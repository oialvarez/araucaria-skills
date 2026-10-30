---
name: sdlc-dba
description: "💎 Nice-to-Have — Database Administrator. Reviews database schema design, migration scripts, query performance, and index optimization. Triggers on: 'database', 'migration', 'liquibase', 'SQL', 'query optimization', 'index', 'schema', 'N+1', 'slow query', 'table design', 'DBA review'."
---

# Database Administrator

Reviews database schema design, migration scripts, query performance, index optimization, and data integrity patterns.

## Pipeline Position

```
Cross-cutting opt-in — applies whenever database changes are introduced at any pipeline stage.
Not a gate. Activated on demand for schema changes, migrations, query tuning, or JPA entity modifications.
```

## Work Type Variants

| Work Type | DBA Focus |
|-----------|----------|
| **Feature** | Schema design for new tables, index planning, migration scripts |
| **Bug Fix** | Query analysis, data integrity checks, constraint validation |
| **Refactor** | Table normalization, index consolidation, query optimization |
| **Investigation** | EXPLAIN ANALYZE, slow query log review, lock contention analysis |
| **Spike** | Schema prototyping, capacity estimation, migration strategy |

---

## 1. Schema Design Standards

### Naming Conventions

- **Tables:** `snake_case`, singular form — `operator_session`, not `OperatorSessions`
- **Columns:** `snake_case` — `created_date`, not `createdDate` (JPA handles mapping)
- **Foreign keys:** `<referenced_table>_id` — `operator_id`, not `fk_operator`
- **Indexes:** `idx_<table>_<columns>` — `idx_operator_session_status_created`
- **Constraints:** `uq_<table>_<columns>` for unique, `chk_<table>_<column>` for check

### Mandatory Audit Columns

Every table MUST include:

```sql
created_date      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
last_modified_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
created_by        VARCHAR(255),
last_modified_by  VARCHAR(255)
```

In JPA, use `@EntityListeners(AuditingEntityListener.class)` with `@CreatedDate`, `@LastModifiedDate`, `@CreatedBy`, `@LastModifiedBy`.

### Foreign Key Rules

- Always define FK constraints at the database level — don't rely solely on JPA `@ManyToOne`.
- Default cascade: `ON DELETE RESTRICT` — prevent accidental orphan creation.
- Use `ON DELETE CASCADE` only for true ownership relationships (e.g., `call_log` → `call_log_entry`).
- Never use `ON DELETE SET NULL` unless the business logic explicitly requires it.

### Data Type Selection

| ❌ Avoid | ✅ Use Instead | Why |
|---------|---------------|-----|
| `VARCHAR(255)` for everything | Appropriate type and length | Storage efficiency, constraint enforcement |
| `INT` for status flags | `VARCHAR` with CHECK constraint or enum table | Readability, self-documenting |
| `FLOAT`/`DOUBLE` for money | `DECIMAL(19,4)` | Precision |
| `TEXT` for short values | `VARCHAR(n)` with appropriate length | Query performance |
| `TIMESTAMP` without timezone | `TIMESTAMP WITH TIME ZONE` | Avoid timezone bugs |

---

## 2. Migration Standards (Liquibase)

### Changeset Rules

1. **Atomic:** One logical change per changeset. Don't mix table creation with data migration.
2. **Idempotent:** Use `<preConditions>` to prevent re-execution failures:

```xml
<changeSet id="add-column-status-to-call" author="developer">
    <preConditions onFail="MARK_RAN">
        <not>
            <columnExists tableName="call" columnName="status"/>
        </not>
    </preConditions>
    <addColumn tableName="call">
        <column name="status" type="VARCHAR(50)" defaultValue="PENDING">
            <constraints nullable="false"/>
        </column>
    </addColumn>
    <rollback>
        <dropColumn tableName="call" columnName="status"/>
    </rollback>
</changeSet>
```

3. **Never modify existing changesets.** Liquibase checksums will break. Always create a new changeset.
4. **Always include a `<rollback>` section.** Even if it's a comment explaining why rollback isn't possible.
5. **Link in master.xml:** Every new changelog file must be included in the master changelog.
6. **Changeset ID format:** `<description>-<ticket>` — e.g., `add-column-status-to-call-PROJ-1234`.

### Data Migrations

- Separate schema changes from data migrations into different changesets.
- Use `<sql>` or `<customChange>` for data transformations.
- Always test data migrations against a production-sized dataset before deploying.

---

## 3. Query Performance

### N+1 Detection

The most common JPA performance killer. Signs:

- A loop that accesses a lazy-loaded collection → N+1 queries.
- Hibernate log showing repeated SELECT statements for the same entity type.

**Fixes:**

```java
// ❌ N+1: loads each operator separately
List<Session> sessions = sessionRepository.findAll();
sessions.forEach(s -> s.getOperator().getName()); // N extra queries

// ✅ JOIN FETCH: single query
@Query("SELECT s FROM Session s JOIN FETCH s.operator WHERE s.status = :status")
List<Session> findByStatusWithOperator(@Param("status") String status);

// ✅ @EntityGraph: declarative approach
@EntityGraph(attributePaths = {"operator", "callLog"})
List<Session> findByStatus(String status);
```

### Index Strategy

- **Composite indexes** for common `WHERE` + `ORDER BY` patterns:
  ```sql
  CREATE INDEX idx_session_status_created ON operator_session(status, created_date);
  ```
- **Column order matters:** Put equality conditions first, range conditions last.
- **Don't over-index:** Each index slows down writes. Only index columns used in WHERE, JOIN, or ORDER BY.
- **Partial indexes** for filtered queries (PostgreSQL):
  ```sql
  CREATE INDEX idx_session_active ON operator_session(operator_id)
  WHERE status IN ('BUSY', 'CONNECTING');
  ```

### Query Analysis

Run `EXPLAIN ANALYZE` for any query that:
- Hits a table with >1,000 rows
- Is called more than once per request
- Appears in a loop or batch operation

Look for:
- **Seq Scan** on large tables → missing index
- **Nested Loop** with high row estimates → consider JOIN optimization
- **Sort** operations → consider adding an index on ORDER BY columns

### General Rules

- **No `SELECT *`** — specify only needed columns, especially for large tables.
- **Pagination:** Always use `LIMIT`/`OFFSET` or keyset pagination for list endpoints.
- **Batch operations:** Use `saveAll()` instead of individual `save()` calls. Set `spring.jpa.properties.hibernate.jdbc.batch_size=25`.

---

## 4. Data Integrity

### Database-Level Constraints

Don't rely solely on application validation. Enforce at the database level:

```sql
-- NOT NULL for required fields
ALTER TABLE operator ADD CONSTRAINT chk_operator_name CHECK (name IS NOT NULL AND name <> '');

-- UNIQUE for business keys
ALTER TABLE operator ADD CONSTRAINT uq_operator_email UNIQUE (email);

-- CHECK for valid ranges
ALTER TABLE call_log ADD CONSTRAINT chk_call_duration CHECK (duration_seconds >= 0);
```

### Enum Mapping

```java
// ✅ Use STRING — readable, survives reordering
@Enumerated(EnumType.STRING)
@Column(nullable = false)
private OperatorStatus status;

// ❌ NEVER use ORDINAL — breaks if enum order changes
@Enumerated(EnumType.ORDINAL) // DON'T
private OperatorStatus status;
```

### Optimistic Locking

For any entity that can be updated concurrently:

```java
@Version
@Column(nullable = false)
private Long version;
```

This prevents lost updates. If two transactions read the same row, the second one to commit gets an `OptimisticLockException` and can retry.

### Soft Deletes

Prefer soft deletes for audit-critical entities:

```java
@Column(nullable = false)
private boolean deleted = false;

private LocalDateTime deletedDate;
```

Add a default `WHERE deleted = false` filter via `@Where(clause = "deleted = false")` or a custom repository base.

---

## 5. Review Checklist

Before approving any database change:

- [ ] **Audit columns?** New tables include `created_date`, `last_modified_date`, `created_by`, `last_modified_by`.
- [ ] **Indexes added?** Frequently queried columns have appropriate indexes.
- [ ] **Migration is idempotent?** `<preConditions>` prevent double-execution failures.
- [ ] **No N+1 patterns?** New JPA queries use JOIN FETCH or @EntityGraph where needed.
- [ ] **Rollback section included?** Every changeset has a rollback or an explanation why not.
- [ ] **Constraints at DB level?** NOT NULL, UNIQUE, CHECK constraints are in the migration, not just in Java.
- [ ] **Enum mapping uses STRING?** No `@Enumerated(EnumType.ORDINAL)` anywhere.
- [ ] **Version column for concurrent entities?** Entities updated by multiple users/processes have `@Version`.
- [ ] **Data types appropriate?** No `VARCHAR(255)` catch-all; proper types and lengths chosen.
- [ ] **EXPLAIN ANALYZE run?** Complex queries verified against realistic data volumes.

---

## Output Artifact

**Deliverable:** Database Review Report.

Format:

```markdown
## Database Review — [TICKET-ID]

### Schema Changes
- Table `X` added/modified: [assessment]
- Audit columns: ✅ Present / ❌ Missing
- Constraints: [list]

### Migration Quality
- Idempotent: ✅ / ❌
- Rollback: ✅ / ❌
- Changeset granularity: [assessment]

### Query Performance
- N+1 risks: [list or "none detected"]
- Index recommendations: [list]
- EXPLAIN ANALYZE results: [summary]

### Data Integrity
- Enum mapping: ✅ STRING / ❌ ORDINAL
- Optimistic locking: ✅ / ❌ (needed for: [entities])
- DB-level constraints: [assessment]

### Verdict
[PASS / PASS WITH NOTES / NEEDS CHANGES]
```
