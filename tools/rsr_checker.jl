#!/usr/bin/env julia
# SPDX-License-Identifier: PMPL-1.0-or-later
#
# Rhodium Standard Repository (RSR) Compliance Checker
# Version: 2.0
#
# Automated compliance verification for RSR Bronze, Silver, Gold, and Platinum levels.
# Migrated from Python to Julia per hyperpolymath language policy.

using JSON3
using Dates

"""
    ComplianceCheck

Represents a single compliance check with its result.
"""
mutable struct ComplianceCheck
    name::String
    description::String
    level::String       # Bronze, Silver, Gold, Platinum
    category::String
    required::Bool
    status::Bool
    details::String
    weight::Float64
end

function ComplianceCheck(;
    name::String,
    description::String,
    level::String,
    category::String,
    required::Bool = true,
    status::Bool = false,
    details::String = "",
    weight::Float64 = 1.0
)
    ComplianceCheck(name, description, level, category, required, status, details, weight)
end

"""
    ComplianceReport

Full compliance report across all RSR levels.
"""
mutable struct ComplianceReport
    bronze_checks::Vector{ComplianceCheck}
    silver_checks::Vector{ComplianceCheck}
    gold_checks::Vector{ComplianceCheck}
    platinum_checks::Vector{ComplianceCheck}
end

ComplianceReport() = ComplianceReport(
    ComplianceCheck[],
    ComplianceCheck[],
    ComplianceCheck[],
    ComplianceCheck[]
)

"""
    get_level_checks(report, level) -> Vector{ComplianceCheck}

Return the checks vector for the given level name.
"""
function get_level_checks(report::ComplianceReport, level::String)::Vector{ComplianceCheck}
    level_lower = lowercase(level)
    if level_lower == "bronze"
        return report.bronze_checks
    elseif level_lower == "silver"
        return report.silver_checks
    elseif level_lower == "gold"
        return report.gold_checks
    elseif level_lower == "platinum"
        return report.platinum_checks
    else
        error("Unknown level: $level")
    end
end

"""
    get_level_score(report, level) -> (passed, total, percentage)

Get the number of passed checks, total checks, and percentage for a given level.
"""
function get_level_score(report::ComplianceReport, level::String)::Tuple{Int, Int, Float64}
    checks = get_level_checks(report, level)
    passed = count(c -> c.status, checks)
    total = length(checks)
    percentage = total > 0 ? (passed / total * 100.0) : 0.0
    return (passed, total, percentage)
end

"""
    get_overall_level(report) -> String

Determine the highest compliance level achieved.
"""
function get_overall_level(report::ComplianceReport)::String
    _, _, bronze_pct = get_level_score(report, "Bronze")
    _, _, silver_pct = get_level_score(report, "Silver")
    _, _, gold_pct = get_level_score(report, "Gold")
    _, _, platinum_pct = get_level_score(report, "Platinum")

    if bronze_pct < 100
        return "Non-compliant"
    elseif silver_pct < 100
        return "Bronze"
    elseif gold_pct < 66
        return "Silver"
    elseif platinum_pct < 66
        return "Gold"
    else
        return "Platinum"
    end
end

"""
    RSRChecker

Main RSR compliance checker. Holds the repository path and the compliance report.
"""
mutable struct RSRChecker
    repo_path::String
    report::ComplianceReport
end

RSRChecker(repo_path::String = ".") = RSRChecker(abspath(repo_path), ComplianceReport())

"""
    check_file_exists(checker, path) -> Bool

Check if a file or directory exists in the repository.
"""
function check_file_exists(checker::RSRChecker, path::String)::Bool
    return ispath(joinpath(checker.repo_path, path))
end

"""
    check_file_content(checker, path, patterns) -> (Bool, String)

Check if file contains all required regex patterns.
"""
function check_file_content(checker::RSRChecker, path::String, patterns::Vector{String})::Tuple{Bool, String}
    file_path = joinpath(checker.repo_path, path)
    if !isfile(file_path)
        return (false, "File $path not found")
    end

    try
        content = read(file_path, String)
        missing_patterns = String[]
        for pattern in patterns
            rx = Regex(pattern, "im")  # case-insensitive, multiline
            if !occursin(rx, content)
                push!(missing_patterns, pattern)
            end
        end

        if !isempty(missing_patterns)
            shown = join(missing_patterns[1:min(3, length(missing_patterns))], ", ")
            return (false, "Missing patterns: $shown")
        end
        return (true, "All required content present")
    catch e
        return (false, "Error reading file: $(sprint(showerror, e))")
    end
end

"""
    check_bronze_level!(checker)

Check Bronze level compliance (18 requirements).
"""
function check_bronze_level!(checker::RSRChecker)
    checks = ComplianceCheck[]

    # 1. README.md with comprehensive content
    status, details = check_file_content(checker, "README.md", [
        raw"##?\s+Installation",
        raw"##?\s+Usage",
        raw"##?\s+Features",
        raw"##?\s+License"
    ])
    push!(checks, ComplianceCheck(
        name = "README.md",
        description = "Comprehensive README with installation, usage, features, license",
        level = "Bronze",
        category = "Documentation",
        status = status,
        details = details
    ))

    # 2. LICENSE file with SPDX identifier
    status, details = check_file_content(checker, "LICENSE", [
        raw"SPDX-License-Identifier:",
        raw"(MIT|Apache|GPL|AGPL|BSD)"
    ])
    push!(checks, ComplianceCheck(
        name = "LICENSE",
        description = "LICENSE file with SPDX identifier",
        level = "Bronze",
        category = "Legal",
        status = status,
        details = details
    ))

    # 3. SECURITY.md with vulnerability disclosure
    status, details = check_file_content(checker, "SECURITY.md", [
        raw"##?\s+Reporting",
        raw"##?\s+Supported Versions",
        raw"(security@|contact)"
    ])
    push!(checks, ComplianceCheck(
        name = "SECURITY.md",
        description = "Security policy with vulnerability disclosure process",
        level = "Bronze",
        category = "Security",
        status = status,
        details = details
    ))

    # 4. CONTRIBUTING.md
    found = check_file_exists(checker, "CONTRIBUTING.md")
    push!(checks, ComplianceCheck(
        name = "CONTRIBUTING.md",
        description = "Contribution guidelines",
        level = "Bronze",
        category = "Community",
        status = found,
        details = found ? "Found" : "Missing"
    ))

    # 5. CODE_OF_CONDUCT.md
    found = check_file_exists(checker, "CODE_OF_CONDUCT.md")
    push!(checks, ComplianceCheck(
        name = "CODE_OF_CONDUCT.md",
        description = "Code of conduct for community",
        level = "Bronze",
        category = "Community",
        status = found,
        details = found ? "Found" : "Missing"
    ))

    # 6. MAINTAINERS.md
    found = check_file_exists(checker, "MAINTAINERS.md")
    push!(checks, ComplianceCheck(
        name = "MAINTAINERS.md",
        description = "List of project maintainers",
        level = "Bronze",
        category = "Governance",
        status = found,
        details = found ? "Found" : "Missing"
    ))

    # 7. CHANGELOG.md
    found = check_file_exists(checker, "CHANGELOG.md")
    push!(checks, ComplianceCheck(
        name = "CHANGELOG.md",
        description = "Version history and changes",
        level = "Bronze",
        category = "Documentation",
        status = found,
        details = found ? "Found" : "Missing"
    ))

    # 8. .well-known/security.txt (RFC 9116)
    status, details = check_file_content(checker, ".well-known/security.txt", [
        raw"Contact:",
        raw"Expires:",
    ])
    push!(checks, ComplianceCheck(
        name = ".well-known/security.txt",
        description = "RFC 9116 compliant security.txt",
        level = "Bronze",
        category = "Security",
        status = status,
        details = details
    ))

    # 9. .well-known/ai.txt
    found = check_file_exists(checker, ".well-known/ai.txt")
    push!(checks, ComplianceCheck(
        name = ".well-known/ai.txt",
        description = "AI training policy declaration",
        level = "Bronze",
        category = "Legal",
        status = found,
        details = found ? "Found" : "Missing"
    ))

    # 10. .well-known/humans.txt
    found = check_file_exists(checker, ".well-known/humans.txt")
    push!(checks, ComplianceCheck(
        name = ".well-known/humans.txt",
        description = "Team attribution file",
        level = "Bronze",
        category = "Community",
        status = found,
        details = found ? "Found" : "Missing"
    ))

    # 11. Build system (justfile or Makefile)
    found = check_file_exists(checker, "justfile") || check_file_exists(checker, "Makefile")
    push!(checks, ComplianceCheck(
        name = "Build system",
        description = "justfile or Makefile for build automation",
        level = "Bronze",
        category = "Build",
        status = found,
        details = found ? "Found" : "Missing"
    ))

    # 12. Nix builds (flake.nix)
    found = check_file_exists(checker, "flake.nix")
    push!(checks, ComplianceCheck(
        name = "flake.nix",
        description = "Nix flakes for reproducible builds",
        level = "Bronze",
        category = "Build",
        status = found,
        details = found ? "Found" : "Missing"
    ))

    # 13. CI/CD configuration
    ci_files = [".gitlab-ci.yml", ".github/workflows", ".circleci/config.yml"]
    found = any(f -> check_file_exists(checker, f), ci_files)
    push!(checks, ComplianceCheck(
        name = "CI/CD",
        description = "Continuous integration configuration",
        level = "Bronze",
        category = "Build",
        status = found,
        details = found ? "Found" : "Missing"
    ))

    # 14. TPCF governance documentation
    found = check_file_exists(checker, "governance/TPCF.md") ||
            check_file_exists(checker, "governance/PROJECT_GOVERNANCE.md") ||
            check_file_exists(checker, "GOVERNANCE.md")
    push!(checks, ComplianceCheck(
        name = "TPCF Governance",
        description = "Tri-Perimeter Contribution Framework documentation",
        level = "Bronze",
        category = "Governance",
        status = found,
        details = found ? "Found" : "Missing"
    ))

    # 15. .gitignore
    found = check_file_exists(checker, ".gitignore")
    push!(checks, ComplianceCheck(
        name = ".gitignore",
        description = "Git ignore file",
        level = "Bronze",
        category = "Build",
        status = found,
        details = found ? "Found" : "Missing"
    ))

    # 16. Test directory structure
    test_dirs = ["tests", "test", "spec"]
    found = any(d -> check_file_exists(checker, d), test_dirs)
    push!(checks, ComplianceCheck(
        name = "Test structure",
        description = "Test directory or files",
        level = "Bronze",
        category = "Quality",
        status = found,
        details = found ? "Found" : "Missing"
    ))

    # 17. Documentation index
    found = check_file_exists(checker, "DOCUMENTATION_INDEX.md") ||
            check_file_exists(checker, "docs/README.md")
    push!(checks, ComplianceCheck(
        name = "Documentation index",
        description = "Centralized documentation navigation",
        level = "Bronze",
        category = "Documentation",
        status = found,
        details = found ? "Found" : "Missing"
    ))

    # 18. Project metadata (package.json, Cargo.toml, pyproject.toml, etc.)
    metadata_files = ["package.json", "Cargo.toml", "pyproject.toml", "setup.py", "setup.cfg"]
    found = any(f -> check_file_exists(checker, f), metadata_files)
    push!(checks, ComplianceCheck(
        name = "Project metadata",
        description = "Language-specific project metadata file",
        level = "Bronze",
        category = "Build",
        status = found,
        details = found ? "Found" : "Missing"
    ))

    checker.report.bronze_checks = checks
end

"""
    check_silver_level!(checker)

Check Silver level compliance (6 requirements).
"""
function check_silver_level!(checker::RSRChecker)
    checks = ComplianceCheck[]

    # 1. RSR compliance checker tool
    found = check_file_exists(checker, "tools/rsr_checker.jl") ||
            check_file_exists(checker, "scripts/rsr_checker.jl") ||
            check_file_exists(checker, "tools/rsr_checker.py") ||
            check_file_exists(checker, "scripts/rsr_checker.py")
    push!(checks, ComplianceCheck(
        name = "RSR checker tool",
        description = "Automated compliance verification tool",
        level = "Silver",
        category = "Quality",
        status = found,
        details = found ? "Found" : "Missing"
    ))

    # 2. RSR compliance documentation
    found = check_file_exists(checker, "RSR_COMPLIANCE.md")
    push!(checks, ComplianceCheck(
        name = "RSR_COMPLIANCE.md",
        description = "Detailed compliance assessment",
        level = "Silver",
        category = "Documentation",
        status = found,
        details = found ? "Found" : "Missing"
    ))

    # 3. Palimpsest dual licensing
    if check_file_exists(checker, "LICENSE")
        status, details = check_file_content(checker, "LICENSE", [
            raw"Palimpsest",
            raw"(MIT OR|Apache-2\.0 OR|GPL-\d\.\d OR)"
        ])
    else
        status, details = false, "LICENSE file not found"
    end
    push!(checks, ComplianceCheck(
        name = "Palimpsest licensing",
        description = "Dual licensing with Palimpsest framework",
        level = "Silver",
        category = "Legal",
        status = status,
        details = details
    ))

    # 4. Comprehensive .well-known directory
    required_wellknown = ["security.txt", "ai.txt", "humans.txt"]
    found = all(f -> check_file_exists(checker, ".well-known/$f"), required_wellknown)
    push!(checks, ComplianceCheck(
        name = "Complete .well-known",
        description = "All required .well-known files present",
        level = "Silver",
        category = "Security",
        status = found,
        details = found ? "Complete" : "Incomplete"
    ))

    # 5. Advanced documentation (multiple guides)
    guides = ["INSTALLATION_GUIDE.md", "USAGE_GUIDE.md", "FEATURES.md"]
    guides_found = count(g -> check_file_exists(checker, g), guides)
    found = guides_found >= 2
    push!(checks, ComplianceCheck(
        name = "Advanced documentation",
        description = "Multiple comprehensive guides (installation, usage, features)",
        level = "Silver",
        category = "Documentation",
        status = found,
        details = "$guides_found/3 guides found"
    ))

    # 6. Reproducible builds with Nix flakes
    if check_file_exists(checker, "flake.nix")
        status, details = check_file_content(checker, "flake.nix", [
            raw"inputs",
            raw"outputs",
            raw"packages"
        ])
    else
        status, details = false, "flake.nix not found"
    end
    push!(checks, ComplianceCheck(
        name = "Nix flakes",
        description = "Complete Nix flakes configuration",
        level = "Silver",
        category = "Build",
        status = status,
        details = details
    ))

    checker.report.silver_checks = checks
end

"""
    rglob(dir, pattern) -> Vector{String}

Recursively find files matching a glob-like pattern under dir.
Returns absolute paths.
"""
function rglob(dir::String, pattern::String)::Vector{String}
    results = String[]
    if !isdir(dir)
        return results
    end
    # Convert glob pattern to regex
    regex_str = replace(pattern, "*" => ".*")
    regex_str = replace(regex_str, "." => "\\.")
    # Fix double-escaped dots from the replacement order
    regex_str = replace(regex_str, "\\..*" => ".*")
    rx = Regex("^" * regex_str * "\$", "i")

    for (root, dirs, files) in walkdir(dir)
        for file in files
            if occursin(rx, file)
                push!(results, joinpath(root, file))
            end
        end
    end
    return results
end

"""
    check_gold_level!(checker)

Check Gold level compliance (3 requirements).
"""
function check_gold_level!(checker::RSRChecker)
    checks = ComplianceCheck[]

    # 1. Formal verification or advanced testing
    formal_dirs = ["proofs/", "formal/", "coq/", "isabelle/", "tla+/"]
    has_formal = any(d -> check_file_exists(checker, d), formal_dirs)

    has_property_tests = false
    tests_dir = joinpath(checker.repo_path, "tests")
    if isdir(tests_dir)
        for (root, _, files) in walkdir(tests_dir)
            for file in files
                filepath = joinpath(root, file)
                try
                    content = read(filepath, String)
                    if any(lib -> occursin(lib, content), ["hypothesis", "quickcheck", "proptest"])
                        has_property_tests = true
                        break
                    end
                catch
                    # Skip files that cannot be read
                end
            end
            has_property_tests && break
        end
    end

    status = has_formal || has_property_tests
    detail_parts = String[]
    has_formal && push!(detail_parts, "Formal verification")
    has_property_tests && push!(detail_parts, "Property-based testing")
    push!(checks, ComplianceCheck(
        name = "Formal verification",
        description = "Formal proofs or property-based testing",
        level = "Gold",
        category = "Quality",
        status = status,
        details = isempty(detail_parts) ? "Not found" : join(detail_parts, ", ")
    ))

    # 2. Multi-language support or FFI
    lang_indicators = Dict(
        "Python"     => ["*.py", "setup.py", "pyproject.toml"],
        "Rust"       => ["Cargo.toml", "*.rs"],
        "JavaScript" => ["package.json", "*.js"],
        "TypeScript" => ["tsconfig.json", "*.ts"],
        "Go"         => ["go.mod", "*.go"],
        "Ada"        => ["*.adb", "*.ads"],
        "Elixir"     => ["mix.exs", "*.ex"],
        "Haskell"    => ["*.hs", "stack.yaml"],
    )

    languages_found = String[]
    for (lang, indicators) in lang_indicators
        for indicator in indicators
            if !isempty(rglob(checker.repo_path, indicator))
                push!(languages_found, lang)
                break
            end
        end
    end

    status = length(languages_found) >= 2
    push!(checks, ComplianceCheck(
        name = "Multi-language support",
        description = "Support for 2+ programming languages",
        level = "Gold",
        category = "Architecture",
        status = status,
        details = isempty(languages_found) ? "Single language" : "Languages: $(join(languages_found, ", "))"
    ))

    # 3. Advanced security features
    security_features = String[]

    # Check for security scanning in CI
    for ci_file in [".gitlab-ci.yml", ".github/workflows"]
        ci_path = joinpath(checker.repo_path, ci_file)
        if ispath(ci_path)
            try
                content = ""
                if isfile(ci_path)
                    content = read(ci_path, String)
                elseif isdir(ci_path)
                    for wf in rglob(ci_path, "*.yml")
                        content *= read(wf, String)
                    end
                end
                if any(tool -> occursin(tool, content), ["bandit", "semgrep", "snyk", "trivy"])
                    push!(security_features, "Security scanning")
                    break
                end
            catch
                # Skip unreadable CI files
            end
        end
    end

    # Check for dependency scanning
    if check_file_exists(checker, "requirements.txt") || check_file_exists(checker, "Cargo.lock")
        push!(security_features, "Dependency management")
    end

    # Check for SBOM
    if check_file_exists(checker, "sbom.json") || check_file_exists(checker, "bom.xml")
        push!(security_features, "SBOM")
    end

    status = length(security_features) >= 2
    push!(checks, ComplianceCheck(
        name = "Advanced security",
        description = "Security scanning, SBOM, or other advanced features",
        level = "Gold",
        category = "Security",
        status = status,
        details = isempty(security_features) ? "Not found" : join(security_features, ", ")
    ))

    checker.report.gold_checks = checks
end

"""
    check_platinum_level!(checker)

Check Platinum level compliance (4 requirements).
"""
function check_platinum_level!(checker::RSRChecker)
    checks = ComplianceCheck[]

    # 1. CRDT or offline-first capabilities
    crdt_dirs = ["crdt/", "offline/", "sync/"]
    has_crdt_dir = any(d -> check_file_exists(checker, d), crdt_dirs)

    has_crdt_code = false
    for jl_file in rglob(checker.repo_path, "*.jl")
        try
            content = lowercase(read(jl_file, String))
            if any(term -> occursin(term, content), ["crdt", "conflict-free", "operational transform", "automerge"])
                has_crdt_code = true
                break
            end
        catch
            # Skip unreadable files
        end
    end
    # Also check other common source file types
    if !has_crdt_code
        for ext in ["*.rs", "*.py", "*.ex", "*.gleam", "*.res"]
            for src_file in rglob(checker.repo_path, ext)
                try
                    content = lowercase(read(src_file, String))
                    if any(term -> occursin(term, content), ["crdt", "conflict-free", "operational transform", "automerge"])
                        has_crdt_code = true
                        break
                    end
                catch
                end
            end
            has_crdt_code && break
        end
    end

    status = has_crdt_dir || has_crdt_code
    push!(checks, ComplianceCheck(
        name = "CRDT/Offline-first",
        description = "Conflict-free replicated data types or offline-first architecture",
        level = "Platinum",
        category = "Architecture",
        status = status,
        details = status ? "Found" : "Not found"
    ))

    # 2. Academic paper
    paper_files = ["papers/", "docs/papers/", "PAPER.md"]
    found = any(f -> check_file_exists(checker, f), paper_files)
    push!(checks, ComplianceCheck(
        name = "Academic paper",
        description = "Research paper or formal publication",
        level = "Platinum",
        category = "Research",
        status = found,
        details = found ? "Found" : "Not found"
    ))

    # 3. Conference materials
    conf_files = ["docs/conference-materials.md", "talks/", "presentations/"]
    found = any(f -> check_file_exists(checker, f), conf_files)
    push!(checks, ComplianceCheck(
        name = "Conference materials",
        description = "Talk proposals, slides, or presentation materials",
        level = "Platinum",
        category = "Research",
        status = found,
        details = found ? "Found" : "Not found"
    ))

    # 4. iSOS integration
    isos_indicators = ["isos/", "docs/isos.md", ".isos.toml"]
    found = any(f -> check_file_exists(checker, f), isos_indicators)
    push!(checks, ComplianceCheck(
        name = "iSOS integration",
        description = "Integrated Sovereign Operating System framework",
        level = "Platinum",
        category = "Architecture",
        status = found,
        details = found ? "Found" : "Not found"
    ))

    checker.report.platinum_checks = checks
end

"""
    run_checks!(checker)

Run all compliance checks across all RSR levels.
"""
function run_checks!(checker::RSRChecker)
    println("🔍 Running RSR Compliance Checks...\n")
    println("Repository: $(checker.repo_path)\n")

    check_bronze_level!(checker)
    check_silver_level!(checker)
    check_gold_level!(checker)
    check_platinum_level!(checker)
end

"""
    print_report(checker)

Print a human-readable compliance report to stdout.
"""
function print_report(checker::RSRChecker)
    println("=" ^ 80)
    println("📊 RSR COMPLIANCE REPORT")
    println("=" ^ 80)
    println()

    levels = [
        ("Bronze", "bronze"),
        ("Silver", "silver"),
        ("Gold", "gold"),
        ("Platinum", "platinum"),
    ]

    for (level_name, _) in levels
        passed, total, percentage = get_level_score(checker.report, level_name)
        status_icon = if percentage == 100
            "✅"
        elseif percentage >= 50
            "⚠️"
        else
            "❌"
        end

        println("$status_icon $level_name Level: $passed/$total ($(round(percentage; digits=1))%)")
        println("-" ^ 80)

        level_checks = get_level_checks(checker.report, level_name)
        for check in level_checks
            check_icon = check.status ? "✓" : "✗"
            println("  [$check_icon] $(check.name)")
            if !isempty(check.details)
                println("      $(check.details)")
            end
        end
        println()
    end

    overall_level = get_overall_level(checker.report)
    println("=" ^ 80)
    println("🏆 OVERALL COMPLIANCE LEVEL: $overall_level")
    println("=" ^ 80)
    println()

    # Compliance level definitions
    println("📋 Compliance Level Definitions:")
    println("  • Bronze: 100% of Bronze requirements")
    println("  • Silver: 100% of Bronze + 100% of Silver requirements")
    println("  • Gold: Silver + 66%+ of Gold requirements")
    println("  • Platinum: Gold + 66%+ of Platinum requirements")
    println()
end

"""
    export_json(checker; output_file="rsr_compliance.json")

Export compliance report as a JSON file.
"""
function export_json(checker::RSRChecker; output_file::String = "rsr_compliance.json")
    levels_data = Dict{String, Any}()

    for level in ["bronze", "silver", "gold", "platinum"]
        passed, total, percentage = get_level_score(checker.report, titlecase(level))
        level_checks = get_level_checks(checker.report, level)

        checks_data = [
            Dict(
                "name" => c.name,
                "description" => c.description,
                "category" => c.category,
                "status" => c.status,
                "details" => c.details
            )
            for c in level_checks
        ]

        levels_data[level] = Dict(
            "score" => Dict(
                "passed" => passed,
                "total" => total,
                "percentage" => percentage
            ),
            "checks" => checks_data
        )
    end

    data = Dict(
        "timestamp" => Dates.format(now(), dateformat"yyyy-mm-ddTHH:MM:SS"),
        "repository" => checker.repo_path,
        "overall_level" => get_overall_level(checker.report),
        "levels" => levels_data
    )

    output_path = joinpath(checker.repo_path, output_file)
    open(output_path, "w") do io
        JSON3.pretty(io, data)
    end

    println("📄 JSON report exported to: $output_path")
end

"""
    generate_badge(checker) -> String

Generate a compliance badge URL using shields.io.
"""
function generate_badge(checker::RSRChecker)::String
    level = get_overall_level(checker.report)
    colors = Dict(
        "Platinum" => "purple",
        "Gold" => "yellow",
        "Silver" => "silver",
        "Bronze" => "orange",
        "Non-compliant" => "red"
    )
    color = get(colors, level, "lightgrey")

    badge_url = "https://img.shields.io/badge/RSR-$(replace(level, " " => "%20"))-$color"

    println("🏅 Badge URL: $badge_url")
    println("   Markdown: ![RSR Compliance]($badge_url)")
    println("   HTML: <img src=\"$badge_url\" alt=\"RSR Compliance\">")

    return badge_url
end

"""
    main()

Entry point: parse CLI arguments and run the compliance checker.
"""
function main()
    # Simple argument parsing
    repo_path = "."
    do_json = false
    json_output = "rsr_compliance.json"
    do_badge = false
    quiet = false

    args = copy(ARGS)
    positional_args = String[]
    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--json"
            do_json = true
        elseif arg == "--json-output" && i < length(args)
            i += 1
            json_output = args[i]
        elseif arg == "--badge"
            do_badge = true
        elseif arg == "--quiet"
            quiet = true
        elseif arg == "--help" || arg == "-h"
            println("Usage: julia rsr_checker.jl [PATH] [OPTIONS]")
            println()
            println("RSR Compliance Checker - Verify Rhodium Standard Repository compliance")
            println()
            println("Arguments:")
            println("  PATH                  Path to repository (default: current directory)")
            println()
            println("Options:")
            println("  --json                Export JSON report")
            println("  --json-output FILE    JSON output filename (default: rsr_compliance.json)")
            println("  --badge               Generate compliance badge URL")
            println("  --quiet               Suppress detailed output")
            println("  -h, --help            Show this help message")
            return
        elseif !startswith(arg, "-")
            push!(positional_args, arg)
        else
            println(stderr, "Unknown option: $arg")
            exit(1)
        end
        i += 1
    end

    if !isempty(positional_args)
        repo_path = positional_args[1]
    end

    checker = RSRChecker(repo_path)
    run_checks!(checker)

    if !quiet
        print_report(checker)
    end

    if do_json
        export_json(checker; output_file = json_output)
    end

    if do_badge
        generate_badge(checker)
    end

    # Exit with non-zero if not at least Bronze compliant
    overall_level = get_overall_level(checker.report)
    if overall_level == "Non-compliant"
        exit(1)
    end

    exit(0)
end

# Run main when executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
