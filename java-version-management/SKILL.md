---
name: java-version-management
description: Commands and setup for jenv. Use when managing JDK versions or fixing Java version mismatches (e.g., migrating to Java 25).
---

# Java Management (jenv)

Standard procedure for managing JDK versions. Check the version the project requires (`pom.xml`, `build.gradle`, `.java-version`) before switching.

## 1. Fast Setup (macOS)
JDKs must be in `/Library/Java/JavaVirtualMachines/`.

```bash
# 1. Symlink (if installed via Homebrew)
sudo ln -sfn $(brew --prefix openjdk@25)/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-25.jdk

# 2. Add to jenv
jenv add /Library/Java/JavaVirtualMachines/openjdk-25.jdk/Contents/Home

# 3. Set Project Local
jenv local 25
```

## 2. Key Commands
- `jenv versions`: List all managed JDKs.
- `jenv global <v>`: Set default version.
- `jenv local <v>`: Set version for current directory (creates `.java-version`).
- `jenv enable-plugin maven`: Forces Maven to respect jenv.

## 3. Troubleshooting
If `java -version` is wrong:
1. Ensure `eval "$(jenv init -)"` is in `~/.zshrc`.
2. Run `jenv rehash` to refresh shims.
3. Check `which java` — it should point to `~/.jenv/shims/java`.
