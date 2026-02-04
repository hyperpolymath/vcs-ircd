; SPDX-License-Identifier: MPL-2.0-or-later
; AGENTIC.scm - AI agent instructions for vext
; Media type: application/vnd.agentic+scm

(agentic
  (metadata
    (version "1.0.0")
    (schema-version "1.0")
    (created "2025-12-30")
    (updated "2025-12-30"))

  (agent-identity
    (project "vext")
    (role "development-assistant")
    (capabilities
      "Code review and improvement"
      "Documentation generation"
      "Test creation"
      "Dependency updates"
      "Security scanning"))

  (language-policy
    (allowed
      (language "Rust" (use-case "core daemon, performance-critical"))
      (language "ReScript" (use-case "tools, hooks, JS-target code"))
      (language "Nickel" (use-case "configuration"))
      (language "Guile Scheme" (use-case "SCM files"))
      (language "Bash" (use-case "minimal scripts only")))
    (banned
      (language "TypeScript" (replacement "ReScript"))
      (language "Python" (replacement "Rust or ReScript"))
      (language "Go" (replacement "Rust"))
      (language "Node.js" (replacement "Deno"))
      (language "npm/yarn/pnpm" (replacement "Deno"))))

  (code-standards
    (rust
      (edition "2021")
      (msrv "1.70")
      (lints "clippy::pedantic")
      (format "rustfmt default")
      (async-runtime "tokio"))
    (rescript
      (output "es6")
      (suffix ".mjs")
      (stdlib "@rescript/core"))
    (general
      (line-endings "LF")
      (indent "spaces")
      (max-line-length 100)
      (spdx-headers required)))

  (task-guidelines
    (before-coding
      "Read STATE.scm for current status"
      "Check META.scm for architectural decisions"
      "Review existing code patterns")
    (during-coding
      "Follow language policy strictly"
      "Add SPDX headers to new files"
      "Write tests for new functionality"
      "Document public APIs")
    (after-coding
      "Run just validate"
      "Update STATE.scm if significant progress"
      "Create descriptive commit message"))

  (prohibited-actions
    "Never introduce TypeScript, Python, or Go"
    "Never use npm, yarn, pnpm, or bun"
    "Never hardcode secrets or credentials"
    "Never remove SPDX headers"
    "Never force push to main branch")

  (autonomous-permissions
    (allowed
      "Fix compiler warnings"
      "Update documentation"
      "Add tests"
      "Format code"
      "Update non-breaking dependencies")
    (requires-approval
      "Change public APIs"
      "Add new dependencies"
      "Modify CI/CD workflows"
      "Change license headers"
      "Refactor core architecture")))
