; SPDX-License-Identifier: MPL-2.0-or-later
; NEUROSYM.scm - Neurosymbolic context for vext
; Media type: application/vnd.neurosym+scm

(neurosym
  (metadata
    (version "1.0.0")
    (schema-version "1.0")
    (created "2025-12-30")
    (updated "2025-12-30"))

  (conceptual-model
    (domain "developer-infrastructure")
    (subdomain "notification-systems")
    (core-concepts
      (concept "notification"
        (definition "A message about a version control event")
        (properties "to" "privmsg" "project" "branch" "commit" "author" "url"))
      (concept "target"
        (definition "An IRC channel or user to receive notifications")
        (format "irc://server[:port]/channel[?key=secret]"))
      (concept "connection-pool"
        (definition "Managed set of IRC connections to a server")
        (purpose "Reduce join/part spam, improve efficiency"))))

  (semantic-mappings
    (irker-to-vext
      (term "irkerd" maps-to "vextd")
      (term "irkerhook" maps-to "vext-hook")
      (term "irk" maps-to "vext-send"))
    (irc-concepts
      (term "PRIVMSG" relates-to "notification.privmsg")
      (term "JOIN" relates-to "connection-pool.channel-join")
      (term "NICK" relates-to "config.nick-prefix")))

  (reasoning-context
    (problem-space
      "How to efficiently notify IRC channels about VCS events"
      "How to minimize IRC connection churn"
      "How to handle rate limiting gracefully")
    (solution-patterns
      (pattern "connection-pooling"
        (problem "Multiple notifications to same server cause excessive connections")
        (solution "Maintain pool of connections, reuse across notifications"))
      (pattern "rate-limiting"
        (problem "IRC servers throttle rapid messages")
        (solution "Token bucket algorithm per target"))
      (pattern "async-io"
        (problem "Blocking IO limits throughput")
        (solution "Tokio async runtime for non-blocking operations"))))

  (inference-rules
    (rule "target-expansion"
      (if "notification.to contains multiple targets")
      (then "expand to individual IRC PRIVMSG commands"))
    (rule "tls-default"
      (if "port is 6697")
      (then "use TLS connection"))
    (rule "channel-prefix"
      (if "target starts with #")
      (then "target is a channel, may need JOIN")))

  (knowledge-graph-hints
    (entities
      "vextd" "vext-send" "vext-hook" "IRC" "UDP" "JSON"
      "tokio" "Rust" "ReScript" "irker")
    (relationships
      ("vextd" listens-on "UDP:6659")
      ("vextd" connects-to "IRC servers")
      ("vext-hook" sends-to "vextd")
      ("vext" is-fork-of "irker"))))
