; SPDX-License-Identifier: MPL-2.0-or-later
; META.scm - Meta-level information for vext
; Media type: application/meta+scm

(meta
  (metadata
    (version "1.0.0")
    (schema-version "1.0")
    (created "2025-01-01")
    (updated "2025-12-30"))

  (architecture-decisions
    (adr-001
      (status accepted)
      (date "2025-01-01")
      (title "Use Rust for core daemon")
      (context "Need high-performance async networking with memory safety")
      (decision "Implement vext-core in Rust with tokio async runtime")
      (consequences
        "Excellent performance and memory safety"
        "Steep learning curve for contributors"
        "Binary distribution instead of interpreted"))

    (adr-002
      (status accepted)
      (date "2025-01-01")
      (title "Dual licensing with MIT OR AGPL-3.0-or-later")
      (context "Balance between permissive use and copyleft protection")
      (decision "Use SPDX expression 'MIT OR AGPL-3.0-or-later' with Palimpsest philosophical framework")
      (consequences
        "Users can choose license that fits their needs"
        "Encourages both commercial and community adoption"))

    (adr-003
      (status accepted)
      (date "2025-01-01")
      (title "ReScript for tools instead of TypeScript")
      (context "RSR language policy bans TypeScript")
      (decision "Use ReScript compiled via Deno for all JS-target code")
      (consequences
        "Type safety with OCaml-like syntax"
        "Smaller bundle sizes"
        "Requires ReScript toolchain"))

    (adr-004
      (status accepted)
      (date "2025-01-01")
      (title "Nickel for configuration")
      (context "Need typed, validated configuration language")
      (decision "Use Nickel as source of truth, generate TOML where needed")
      (consequences
        "Contracts and types for config validation"
        "Can export to JSON/TOML/YAML"
        "Requires Nickel runtime for development")))

  (development-practices
    (code-style
      (rust "rustfmt default, clippy pedantic")
      (rescript "rescript format")
      (nickel "nickel format"))
    (security
      "No hardcoded secrets"
      "SHA-pinned dependencies"
      "SPDX headers on all files"
      "Regular dependency audits")
    (testing
      "Unit tests required for all public APIs"
      "Integration tests for network code"
      "Fuzz testing for parsers")
    (versioning "Semantic Versioning 2.0.0")
    (documentation
      "AsciiDoc for README"
      "Markdown for guides"
      "Man pages for CLI")
    (branching
      "main is always releasable"
      "Feature branches for development"
      "No force push to main"))

  (design-rationale
    (why-rust
      "Memory safety without garbage collection"
      "Excellent async ecosystem (tokio)"
      "Cross-platform compilation"
      "Active security-focused community")
    (why-rescript
      "Type safety for JavaScript target"
      "No runtime overhead"
      "OCaml heritage aligns with project values")
    (why-irker-fork
      "Original irker is Python 2/3 with no async"
      "Need modern TLS and connection pooling"
      "Opportunity for RSR-compliant rewrite")))
