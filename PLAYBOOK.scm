; SPDX-License-Identifier: MPL-2.0-or-later
; PLAYBOOK.scm - Operational playbook for vext
; Media type: application/vnd.playbook+scm

(playbook
  (metadata
    (version "1.0.0")
    (schema-version "1.0")
    (created "2025-12-30")
    (updated "2025-12-30"))

  (quick-start
    (prerequisites
      "Rust 1.70+"
      "Deno 2.0+"
      "Just task runner")
    (steps
      (step 1 "Clone repository" "git clone https://github.com/hyperpolymath/vext")
      (step 2 "Setup environment" "just setup")
      (step 3 "Build" "just build")
      (step 4 "Run tests" "just test")
      (step 5 "Start daemon" "./target/release/vextd --foreground")))

  (common-tasks
    (development
      (task "Build debug"
        (command "just build-debug")
        (when "Local development"))
      (task "Build release"
        (command "just build")
        (when "Creating release binaries"))
      (task "Run all tests"
        (command "just test")
        (when "Before committing"))
      (task "Format code"
        (command "just format")
        (when "Before committing"))
      (task "Lint code"
        (command "just lint")
        (when "Before committing"))
      (task "Full validation"
        (command "just validate")
        (when "Before creating PR")))

    (operations
      (task "Start daemon"
        (command "vextd --listen 0.0.0.0:6659")
        (when "Production deployment"))
      (task "Start with TLS"
        (command "vextd --tls --default-port 6697")
        (when "Secure IRC connections"))
      (task "Run in container"
        (command "podman run -p 6659:6659 ghcr.io/hyperpolymath/vext")
        (when "Container deployment"))
      (task "Send test notification"
        (command "echo '{\"to\":[\"irc://irc.libera.chat/#test\"],\"privmsg\":\"Hello\"}' | nc -u localhost 6659")
        (when "Testing connectivity"))))

  (troubleshooting
    (issue "Connection refused to IRC server"
      (symptoms "Error: connection refused" "No messages delivered")
      (diagnosis "Check IRC server is reachable" "Verify port and TLS settings")
      (resolution "Use --tls for port 6697" "Check firewall rules"))

    (issue "Rate limiting triggered"
      (symptoms "Messages delayed" "Warning: rate limited")
      (diagnosis "Too many notifications in short time")
      (resolution "Increase rate limit in config" "Batch notifications"))

    (issue "UDP packets not received"
      (symptoms "No notifications processed" "Empty queue")
      (diagnosis "Check bind address" "Verify UDP port open")
      (resolution "Use --listen 0.0.0.0:6659" "Check firewall for UDP")))

  (maintenance
    (daily)
    (weekly
      (task "Review logs for errors"))
    (monthly
      (task "Update dependencies" "cargo update")
      (task "Security audit" "cargo audit"))
    (quarterly
      (task "Review and update documentation")
      (task "Performance benchmarking"))))
