; SPDX-License-Identifier: MPL-2.0-or-later
; ECOSYSTEM.scm - Project ecosystem relationships for vext
; Media type: application/vnd.ecosystem+scm

(ecosystem
  (version "1.0.0")
  (name "vext")
  (type "application")
  (purpose "IRC notification daemon for version control systems")

  (position-in-ecosystem
    (category "developer-tools")
    (subcategory "notifications")
    (layer "infrastructure"))

  (related-projects
    (sibling-standard
      (project "robot-repo-automaton"
        (relationship "automation-target")
        (description "Automates vext deployment and configuration"))
      (project "rhodium-standard-repositories"
        (relationship "standard-source")
        (description "Defines RSR compliance requirements")))

    (upstream
      (project "irker"
        (relationship "inspiration")
        (url "https://gitlab.com/esr/irker")
        (description "Original Python IRC notification daemon")))

    (potential-consumers
      (project "gitea"
        (relationship "integration-target")
        (description "Self-hosted Git service"))
      (project "gitlab"
        (relationship "integration-target")
        (description "DevOps platform with CI/CD"))
      (project "forgejo"
        (relationship "integration-target")
        (description "Community fork of Gitea"))))

  (what-this-is
    "High-performance IRC notification daemon"
    "Modern Rust rewrite of irker"
    "RSR-compliant reference implementation"
    "Production-ready infrastructure component")

  (what-this-is-not
    "Not an IRC client or bot framework"
    "Not a general-purpose messaging system"
    "Not a replacement for webhooks"
    "Not a monitoring or alerting tool")

  (dependencies
    (runtime
      (crate "tokio" "async runtime")
      (crate "irc" "IRC protocol")
      (crate "native-tls" "TLS support"))
    (build
      (tool "cargo" "Rust build")
      (tool "deno" "ReScript/JS tooling")
      (tool "just" "task runner")))

  (integration-points
    (input
      (protocol "UDP" (port 6659) (format "JSON"))
      (protocol "TCP" (port 6659) (format "JSON")))
    (output
      (protocol "IRC" (ports 6667 6697) (tls optional)))))
