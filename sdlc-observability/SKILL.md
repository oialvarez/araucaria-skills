---
name: sdlc-observability
description: "💎 Nice-to-Have — Observability Engineer. Reviews logging, monitoring, alerting, and distributed tracing standards. Triggers on: 'logging', 'monitoring', 'alerting', 'observability', 'traces', 'metrics', 'datadog', 'MDC', 'traceability', 'dashboard', 'APM'."
---

# Observability Engineer

Reviews logging standards, distributed tracing, metrics collection, dashboard design, and alerting rules.

## Pipeline Position

```
Cross-cutting opt-in — applies whenever new code paths, error handling, or service interactions are introduced.
Not a gate. Activated on demand for logging reviews, tracing setup, metrics planning, or alerting configuration.
```

## Work Type Variants

| Work Type | Observability Focus |
|-----------|-------------------|
| **Feature** | New log points, business metrics, trace spans, dashboard updates |
| **Bug Fix** | Verify error paths have adequate logging, add missing context |
| **Refactor** | Clean up noisy logs, consolidate MDC usage, remove dead metrics |
| **Investigation** | Log analysis guidance, trace correlation, metric anomaly detection |
| **Spike** | Observability architecture, tool evaluation, cost estimation |

---

## 1. Logging Standards

### Framework

Use **SLF4J** as the logging facade with **MDC (Mapped Diagnostic Context)** for structured context:

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;

private static final Logger log = LoggerFactory.getLogger(CallService.class);

// Set MDC at entry points (filters, interceptors, event handlers)
MDC.put("sessionId", session.getId().toString());
MDC.put("callId", call.getId().toString());
MDC.put("operatorId", operator.getId().toString());

try {
    // ... business logic
    log.info("Call connected — operator joined the session");
} finally {
    MDC.clear(); // Always clean up
}
```

### Log Levels

| Level | When to Use | Example |
|-------|------------|---------|
| `ERROR` | Unrecoverable failure, requires attention | `log.error("Failed to route call — no available operators", ex)` |
| `WARN` | Recoverable issue, degraded behavior | `log.warn("Operator response timed out — retrying with next available")` |
| `INFO` | Business milestone, state transition | `log.info("Call ended — duration: {} seconds", duration)` |
| `DEBUG` | Development diagnostics, detailed flow | `log.debug("Evaluating operator {} — status: {}", id, status)` |
| `TRACE` | Very detailed internal state (rarely used) | `log.trace("Raw WebSocket frame: {}", frame)` |

### Mandatory Context

Every log line in a request/event flow MUST include (via MDC or inline):

- **Correlation ID / Request ID** — links all logs from one external request
- **Session ID** — links logs within a call session
- **User/Entity ID** — identifies the actor (operator ID, caller ID)

### Rules

1. **No PII in logs.** Never log emails, full names, phone numbers, or addresses. Use IDs only.
   ```java
   // ❌ BAD
   log.info("Sending notification to {}", user.getEmail());

   // ✅ GOOD
   log.info("Sending notification to user {}", user.getId());
   ```

2. **No logging in tight loops.** If code runs 1000+ times per request, don't log inside the loop.
   ```java
   // ❌ BAD — logs once per item
   for (Operator i : operators) {
       log.debug("Checking operator {}", i.getId());
   }

   // ✅ GOOD — log summary
   log.debug("Evaluating {} operators for routing", operators.size());
   ```

3. **Business-centric messages.** Describe what happened in business terms, not code terms.
   ```java
   // ❌ BAD
   log.info("Method processEvent completed successfully");

   // ✅ GOOD
   log.info("Operator {} moved to AVAILABLE — ready for next call", operatorId);
   ```

4. **Include exception objects.** Pass the exception as the last argument to preserve the stack trace.
   ```java
   // ❌ BAD — loses stack trace
   log.error("Failed to connect call: " + ex.getMessage());

   // ✅ GOOD — preserves stack trace
   log.error("Failed to connect call — sessionId: {}", sessionId, ex);
   ```

5. **Use parameterized logging.** Never concatenate strings in log statements.
   ```java
   // ❌ BAD — string concatenation happens even if level is disabled
   log.debug("Processing call " + callId + " for operator " + operatorId);

   // ✅ GOOD — parameterized, lazy evaluation
   log.debug("Processing call {} for operator {}", callId, operatorId);
   ```

---

## 2. Distributed Tracing

### Trace Context Propagation

- Propagate trace headers (`traceparent`, `X-Request-ID`) across all service boundaries.
- For HTTP calls: headers are auto-propagated by Spring Cloud Sleuth / Micrometer Tracing.
- For MQ messages: include trace context in message headers explicitly.
- For WebSocket events: attach correlation IDs to each event payload.

### Span Tagging

Tag spans with business-relevant attributes for filtering in the APM tool:

```java
Span currentSpan = tracer.currentSpan();
if (currentSpan != null) {
    currentSpan.tag("callId", callId.toString());
    currentSpan.tag("sessionId", sessionId.toString());
    currentSpan.tag("operatorStatus", status.name());
    currentSpan.tag("callType", callType.name()); // INCOMING, OUTGOING, EMERGENCY
}
```

### Cross-Service Correlation

For request flows that cross multiple services:

1. Generate a `correlationId` at the entry point (API gateway or first service).
2. Pass it in HTTP headers: `X-Correlation-ID`.
3. Add it to MDC in every service.
4. Use it to search across services in the APM tool.

---

## 3. Metrics & Dashboards

### Business Metrics

Track KPIs that matter to the business, not just system health:

| Metric | Type | Description |
|--------|------|-------------|
| `calls.per_minute` | Counter | Inbound call rate |
| `calls.average_wait_time` | Timer | Time from queue entry to operator connection |
| `calls.average_duration` | Timer | Total call duration |
| `operators.available` | Gauge | Currently available operators |
| `operators.busy` | Gauge | Currently in-call operators |
| `calls.abandoned` | Counter | Calls where caller hung up before connection |
| `calls.transfer_rate` | Counter | Calls requiring operator transfer |

### Implementation

```java
// Using Micrometer
private final MeterRegistry meterRegistry;

// Counter
meterRegistry.counter("calls.connected", "callType", callType.name()).increment();

// Timer
Timer.builder("calls.wait_time")
    .tag("language", language)
    .register(meterRegistry)
    .record(waitDuration);

// Gauge
Gauge.builder("operators.available", availablePool, Collection::size)
    .tag("language", language)
    .register(meterRegistry);
```

### SLA Monitoring

Define and monitor SLAs:

- **Call connection time:** 95th percentile < 30 seconds
- **API response time:** 99th percentile < 500ms
- **System availability:** 99.9% uptime
- **Error rate:** < 0.1% of requests

---

## 4. Alerting Rules

### Alert Design Principles

1. **Every alert must be actionable.** If nobody needs to do anything, it's not an alert — it's a metric.
2. **Link a runbook.** Every alert description includes a link to remediation steps.
3. **Define escalation paths.** Who gets paged first? What happens if they don't respond?

### Standard Alert Thresholds

| Alert | Condition | Severity | Escalation |
|-------|-----------|----------|------------|
| High error rate | Error rate > 1% for 5 minutes | Critical | Page on-call → team lead after 15 min |
| High latency | P95 latency > 2s for 5 minutes | Warning | Slack notification → page after 30 min |
| No available operators | Available count = 0 for 2 minutes | Critical | Page on-call immediately |
| Queue depth growing | Queue size > 50 for 10 minutes | Warning | Slack notification |
| Database connection pool exhausted | Available connections = 0 | Critical | Page on-call immediately |
| Disk space low | < 10% free | Warning | Slack notification |

### Runbook Template

For every new alert, create or update a runbook:

```markdown
## Alert: [Alert Name]

**Trigger:** [Condition]
**Impact:** [What users experience]
**Common Causes:**
1. [Cause A] → [Fix A]
2. [Cause B] → [Fix B]

**Investigation Steps:**
1. Check [dashboard/log/metric]
2. Verify [system component]
3. If [condition], then [action]

**Escalation:**
- First responder: [role]
- Escalate to: [role] after [time]
```

---

## 5. Review Checklist

Before approving any code change, verify:

- [ ] **Error paths have ERROR-level logs?** Every catch block that represents a real failure has `log.error()` with the exception object.
- [ ] **MDC context set at entry points?** Filters, interceptors, or event handlers set session/call/user IDs in MDC.
- [ ] **MDC cleaned up?** `MDC.clear()` called in `finally` blocks or after-completion interceptors.
- [ ] **No PII in log messages?** No emails, names, phone numbers, or addresses — only IDs.
- [ ] **No logging in tight loops?** Loops that iterate >100 times log summaries, not per-item.
- [ ] **Parameterized logging?** No string concatenation in log statements.
- [ ] **Business metrics tracked?** New features have corresponding Micrometer counters/timers/gauges.
- [ ] **Trace context propagated?** Cross-service calls pass correlation IDs in headers.
- [ ] **Alerts defined for new failure modes?** New error scenarios have corresponding alert rules.
- [ ] **Runbook updated?** New alerts have runbook entries with investigation and remediation steps.

---

## Output Artifact

**Deliverable:** Observability Review Report.

Format:

```markdown
## Observability Review — [TICKET-ID]

### Logging
- New log points: [count] added
- MDC context: ✅ Properly set / ❌ Missing at [entry points]
- PII check: ✅ Clean / ❌ Found at [locations]
- Log level appropriateness: [assessment]

### Distributed Tracing
- Trace propagation: ✅ / ❌ Missing for [calls]
- Span tags: ✅ Business attributes tagged / ❌ Missing [attributes]
- Correlation IDs: ✅ / ❌

### Metrics
- New metrics: [list]
- Dashboard updates needed: [yes/no — details]
- SLA coverage: [assessment]

### Alerting
- New alerts needed: [list]
- Runbook entries: ✅ Created / ❌ Missing for [alerts]
- Escalation paths: ✅ Defined / ❌ Missing

### Verdict
[PASS / PASS WITH NOTES / NEEDS CHANGES]
```
