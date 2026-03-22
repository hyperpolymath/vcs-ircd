#!/usr/bin/env python3
"""
Rhodium Standard Repository (RSR) Compliance Checker
Version: 2.0
SPDX-License-Identifier: MIT OR PMPL-1.0-or-later

Automated compliance verification for RSR Bronze, Silver, Gold, and Platinum levels.
"""

import os
import sys
import json
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass, field
from datetime import datetime


@dataclass
class ComplianceCheck:
    """Represents a single compliance check."""
    name: str
    description: str
    level: str  # Bronze, Silver, Gold, Platinum
    category: str
    required: bool = True
    status: bool = False
    details: str = ""
    weight: float = 1.0


@dataclass
class ComplianceReport:
    """Full compliance report across all levels."""
    bronze_checks: List[ComplianceCheck] = field(default_factory=list)
    silver_checks: List[ComplianceCheck] = field(default_factory=list)
    gold_checks: List[ComplianceCheck] = field(default_factory=list)
    platinum_checks: List[ComplianceCheck] = field(default_factory=list)

    def get_level_score(self, level: str) -> Tuple[int, int, float]:
        """Get (passed, total, percentage) for a level."""
        checks = getattr(self, f"{level.lower()}_checks")
        passed = sum(1 for c in checks if c.status)
        total = len(checks)
        percentage = (passed / total * 100) if total > 0 else 0.0
        return passed, total, percentage

    def get_overall_level(self) -> str:
        """Determine the highest compliance level achieved."""
        _, _, bronze_pct = self.get_level_score("Bronze")
        _, _, silver_pct = self.get_level_score("Silver")
        _, _, gold_pct = self.get_level_score("Gold")
        _, _, platinum_pct = self.get_level_score("Platinum")

        if bronze_pct < 100:
            return "Non-compliant"
        elif silver_pct < 100:
            return "Bronze"
        elif gold_pct < 66:
            return "Silver"
        elif platinum_pct < 66:
            return "Gold"
        else:
            return "Platinum"


class RSRChecker:
    """Main RSR compliance checker."""

    def __init__(self, repo_path: str = "."):
        self.repo_path = Path(repo_path).resolve()
        self.report = ComplianceReport()

    def check_file_exists(self, path: str) -> bool:
        """Check if a file exists in the repository."""
        return (self.repo_path / path).exists()

    def check_file_content(self, path: str, patterns: List[str]) -> Tuple[bool, str]:
        """Check if file contains required patterns."""
        file_path = self.repo_path / path
        if not file_path.exists():
            return False, f"File {path} not found"

        try:
            content = file_path.read_text(encoding='utf-8')
            missing = []
            for pattern in patterns:
                if not re.search(pattern, content, re.IGNORECASE | re.MULTILINE):
                    missing.append(pattern)

            if missing:
                return False, f"Missing patterns: {', '.join(missing[:3])}"
            return True, "All required content present"
        except Exception as e:
            return False, f"Error reading file: {str(e)}"

    def check_bronze_level(self):
        """Check Bronze level compliance (18 requirements)."""
        checks = []

        # 1. README.md with comprehensive content
        status, details = self.check_file_content("README.md", [
            r"##?\s+Installation",
            r"##?\s+Usage",
            r"##?\s+Features",
            r"##?\s+License"
        ])
        checks.append(ComplianceCheck(
            name="README.md",
            description="Comprehensive README with installation, usage, features, license",
            level="Bronze",
            category="Documentation",
            status=status,
            details=details
        ))

        # 2. LICENSE file with SPDX identifier
        status, details = self.check_file_content("LICENSE", [
            r"SPDX-License-Identifier:",
            r"(MIT|Apache|GPL|AGPL|BSD)"
        ])
        checks.append(ComplianceCheck(
            name="LICENSE",
            description="LICENSE file with SPDX identifier",
            level="Bronze",
            category="Legal",
            status=status,
            details=details
        ))

        # 3. SECURITY.md with vulnerability disclosure
        status, details = self.check_file_content("SECURITY.md", [
            r"##?\s+Reporting",
            r"##?\s+Supported Versions",
            r"(security@|contact)"
        ])
        checks.append(ComplianceCheck(
            name="SECURITY.md",
            description="Security policy with vulnerability disclosure process",
            level="Bronze",
            category="Security",
            status=status,
            details=details
        ))

        # 4. CONTRIBUTING.md
        status = self.check_file_exists("CONTRIBUTING.md")
        checks.append(ComplianceCheck(
            name="CONTRIBUTING.md",
            description="Contribution guidelines",
            level="Bronze",
            category="Community",
            status=status,
            details="Found" if status else "Missing"
        ))

        # 5. CODE_OF_CONDUCT.md
        status = self.check_file_exists("CODE_OF_CONDUCT.md")
        checks.append(ComplianceCheck(
            name="CODE_OF_CONDUCT.md",
            description="Code of conduct for community",
            level="Bronze",
            category="Community",
            status=status,
            details="Found" if status else "Missing"
        ))

        # 6. MAINTAINERS.md
        status = self.check_file_exists("MAINTAINERS.md")
        checks.append(ComplianceCheck(
            name="MAINTAINERS.md",
            description="List of project maintainers",
            level="Bronze",
            category="Governance",
            status=status,
            details="Found" if status else "Missing"
        ))

        # 7. CHANGELOG.md
        status = self.check_file_exists("CHANGELOG.md")
        checks.append(ComplianceCheck(
            name="CHANGELOG.md",
            description="Version history and changes",
            level="Bronze",
            category="Documentation",
            status=status,
            details="Found" if status else "Missing"
        ))

        # 8. .well-known/security.txt (RFC 9116)
        status, details = self.check_file_content(".well-known/security.txt", [
            r"Contact:",
            r"Expires:",
        ])
        checks.append(ComplianceCheck(
            name=".well-known/security.txt",
            description="RFC 9116 compliant security.txt",
            level="Bronze",
            category="Security",
            status=status,
            details=details
        ))

        # 9. .well-known/ai.txt
        status = self.check_file_exists(".well-known/ai.txt")
        checks.append(ComplianceCheck(
            name=".well-known/ai.txt",
            description="AI training policy declaration",
            level="Bronze",
            category="Legal",
            status=status,
            details="Found" if status else "Missing"
        ))

        # 10. .well-known/humans.txt
        status = self.check_file_exists(".well-known/humans.txt")
        checks.append(ComplianceCheck(
            name=".well-known/humans.txt",
            description="Team attribution file",
            level="Bronze",
            category="Community",
            status=status,
            details="Found" if status else "Missing"
        ))

        # 11. Build system (justfile or Makefile)
        status = self.check_file_exists("justfile") or self.check_file_exists("Makefile")
        checks.append(ComplianceCheck(
            name="Build system",
            description="justfile or Makefile for build automation",
            level="Bronze",
            category="Build",
            status=status,
            details="Found" if status else "Missing"
        ))

        # 12. Nix builds (flake.nix)
        status = self.check_file_exists("flake.nix")
        checks.append(ComplianceCheck(
            name="flake.nix",
            description="Nix flakes for reproducible builds",
            level="Bronze",
            category="Build",
            status=status,
            details="Found" if status else "Missing"
        ))

        # 13. CI/CD configuration
        ci_files = [".gitlab-ci.yml", ".github/workflows", ".circleci/config.yml"]
        status = any(self.check_file_exists(f) for f in ci_files)
        checks.append(ComplianceCheck(
            name="CI/CD",
            description="Continuous integration configuration",
            level="Bronze",
            category="Build",
            status=status,
            details="Found" if status else "Missing"
        ))

        # 14. TPCF governance documentation
        status = self.check_file_exists("governance/TPCF.md") or \
                 self.check_file_exists("governance/PROJECT_GOVERNANCE.md") or \
                 self.check_file_exists("GOVERNANCE.md")
        checks.append(ComplianceCheck(
            name="TPCF Governance",
            description="Tri-Perimeter Contribution Framework documentation",
            level="Bronze",
            category="Governance",
            status=status,
            details="Found" if status else "Missing"
        ))

        # 15. .gitignore
        status = self.check_file_exists(".gitignore")
        checks.append(ComplianceCheck(
            name=".gitignore",
            description="Git ignore file",
            level="Bronze",
            category="Build",
            status=status,
            details="Found" if status else "Missing"
        ))

        # 16. Test directory structure
        test_dirs = ["tests", "test", "spec"]
        status = any(self.check_file_exists(d) for d in test_dirs)
        checks.append(ComplianceCheck(
            name="Test structure",
            description="Test directory or files",
            level="Bronze",
            category="Quality",
            status=status,
            details="Found" if status else "Missing"
        ))

        # 17. Documentation index
        status = self.check_file_exists("DOCUMENTATION_INDEX.md") or \
                 self.check_file_exists("docs/README.md")
        checks.append(ComplianceCheck(
            name="Documentation index",
            description="Centralized documentation navigation",
            level="Bronze",
            category="Documentation",
            status=status,
            details="Found" if status else "Missing"
        ))

        # 18. Project metadata (package.json, Cargo.toml, pyproject.toml, etc.)
        metadata_files = ["package.json", "Cargo.toml", "pyproject.toml", "setup.py", "setup.cfg"]
        status = any(self.check_file_exists(f) for f in metadata_files)
        checks.append(ComplianceCheck(
            name="Project metadata",
            description="Language-specific project metadata file",
            level="Bronze",
            category="Build",
            status=status,
            details="Found" if status else "Missing"
        ))

        self.report.bronze_checks = checks

    def check_silver_level(self):
        """Check Silver level compliance (6 requirements)."""
        checks = []

        # 1. RSR compliance checker tool
        status = self.check_file_exists("tools/rsr_checker.py") or \
                 self.check_file_exists("scripts/rsr_checker.py")
        checks.append(ComplianceCheck(
            name="RSR checker tool",
            description="Automated compliance verification tool",
            level="Silver",
            category="Quality",
            status=status,
            details="Found" if status else "Missing"
        ))

        # 2. RSR compliance documentation
        status = self.check_file_exists("RSR_COMPLIANCE.md")
        checks.append(ComplianceCheck(
            name="RSR_COMPLIANCE.md",
            description="Detailed compliance assessment",
            level="Silver",
            category="Documentation",
            status=status,
            details="Found" if status else "Missing"
        ))

        # 3. Palimpsest dual licensing
        if self.check_file_exists("LICENSE"):
            status, details = self.check_file_content("LICENSE", [
                r"Palimpsest",
                r"(MIT OR|Apache-2\.0 OR|GPL-\d\.\d OR)"
            ])
        else:
            status, details = False, "LICENSE file not found"
        checks.append(ComplianceCheck(
            name="Palimpsest licensing",
            description="Dual licensing with Palimpsest framework",
            level="Silver",
            category="Legal",
            status=status,
            details=details
        ))

        # 4. Comprehensive .well-known directory
        required_files = ["security.txt", "ai.txt", "humans.txt"]
        status = all(self.check_file_exists(f".well-known/{f}") for f in required_files)
        checks.append(ComplianceCheck(
            name="Complete .well-known",
            description="All required .well-known files present",
            level="Silver",
            category="Security",
            status=status,
            details="Complete" if status else "Incomplete"
        ))

        # 5. Advanced documentation (multiple guides)
        guides = ["INSTALLATION_GUIDE.md", "USAGE_GUIDE.md", "FEATURES.md"]
        found = sum(1 for g in guides if self.check_file_exists(g))
        status = found >= 2
        checks.append(ComplianceCheck(
            name="Advanced documentation",
            description="Multiple comprehensive guides (installation, usage, features)",
            level="Silver",
            category="Documentation",
            status=status,
            details=f"{found}/3 guides found"
        ))

        # 6. Reproducible builds with Nix flakes
        if self.check_file_exists("flake.nix"):
            status, details = self.check_file_content("flake.nix", [
                r"inputs",
                r"outputs",
                r"packages"
            ])
        else:
            status, details = False, "flake.nix not found"
        checks.append(ComplianceCheck(
            name="Nix flakes",
            description="Complete Nix flakes configuration",
            level="Silver",
            category="Build",
            status=status,
            details=details
        ))

        self.report.silver_checks = checks

    def check_gold_level(self):
        """Check Gold level compliance (3 requirements)."""
        checks = []

        # 1. Formal verification or advanced testing
        formal_files = ["proofs/", "formal/", "coq/", "isabelle/", "tla+/"]
        has_formal = any(self.check_file_exists(f) for f in formal_files)

        # Check for property-based testing
        has_property_tests = False
        if self.check_file_exists("tests"):
            for test_file in (self.repo_path / "tests").rglob("*"):
                if test_file.is_file():
                    try:
                        content = test_file.read_text(encoding='utf-8', errors='ignore')
                        if any(lib in content for lib in ["hypothesis", "quickcheck", "proptest"]):
                            has_property_tests = True
                            break
                    except:
                        pass

        status = has_formal or has_property_tests
        details = []
        if has_formal:
            details.append("Formal verification")
        if has_property_tests:
            details.append("Property-based testing")

        checks.append(ComplianceCheck(
            name="Formal verification",
            description="Formal proofs or property-based testing",
            level="Gold",
            category="Quality",
            status=status,
            details=", ".join(details) if details else "Not found"
        ))

        # 2. Multi-language support or FFI
        lang_indicators = {
            "Python": ["*.py", "setup.py", "pyproject.toml"],
            "Rust": ["Cargo.toml", "src/*.rs"],
            "JavaScript": ["package.json", "*.js"],
            "TypeScript": ["tsconfig.json", "*.ts"],
            "Go": ["go.mod", "*.go"],
            "Ada": ["*.adb", "*.ads"],
            "Elixir": ["mix.exs", "*.ex"],
            "Haskell": ["*.hs", "stack.yaml"],
        }

        languages_found = []
        for lang, indicators in lang_indicators.items():
            for indicator in indicators:
                if list(self.repo_path.rglob(indicator)):
                    languages_found.append(lang)
                    break

        status = len(languages_found) >= 2
        checks.append(ComplianceCheck(
            name="Multi-language support",
            description="Support for 2+ programming languages",
            level="Gold",
            category="Architecture",
            status=status,
            details=f"Languages: {', '.join(languages_found)}" if languages_found else "Single language"
        ))

        # 3. Advanced security features
        security_features = []

        # Check for security scanning in CI
        for ci_file in [".gitlab-ci.yml", ".github/workflows"]:
            if self.check_file_exists(ci_file):
                try:
                    path = self.repo_path / ci_file
                    if path.is_file():
                        content = path.read_text(encoding='utf-8')
                    else:
                        # Check workflow files
                        content = ""
                        for wf in path.rglob("*.yml"):
                            content += wf.read_text(encoding='utf-8')

                    if any(tool in content for tool in ["bandit", "semgrep", "snyk", "trivy"]):
                        security_features.append("Security scanning")
                        break
                except:
                    pass

        # Check for dependency scanning
        if self.check_file_exists("requirements.txt") or self.check_file_exists("Cargo.lock"):
            security_features.append("Dependency management")

        # Check for SBOM
        if self.check_file_exists("sbom.json") or self.check_file_exists("bom.xml"):
            security_features.append("SBOM")

        status = len(security_features) >= 2
        checks.append(ComplianceCheck(
            name="Advanced security",
            description="Security scanning, SBOM, or other advanced features",
            level="Gold",
            category="Security",
            status=status,
            details=", ".join(security_features) if security_features else "Not found"
        ))

        self.report.gold_checks = checks

    def check_platinum_level(self):
        """Check Platinum level compliance (4 requirements)."""
        checks = []

        # 1. CRDT or offline-first capabilities
        crdt_files = ["crdt/", "offline/", "sync/"]
        has_crdt_dir = any(self.check_file_exists(f) for f in crdt_files)

        has_crdt_code = False
        for py_file in self.repo_path.rglob("*.py"):
            try:
                content = py_file.read_text(encoding='utf-8', errors='ignore')
                if any(term in content.lower() for term in ["crdt", "conflict-free", "operational transform", "automerge"]):
                    has_crdt_code = True
                    break
            except:
                pass

        status = has_crdt_dir or has_crdt_code
        checks.append(ComplianceCheck(
            name="CRDT/Offline-first",
            description="Conflict-free replicated data types or offline-first architecture",
            level="Platinum",
            category="Architecture",
            status=status,
            details="Found" if status else "Not found"
        ))

        # 2. Academic paper
        paper_files = ["papers/", "docs/papers/", "PAPER.md"]
        status = any(self.check_file_exists(f) for f in paper_files)
        checks.append(ComplianceCheck(
            name="Academic paper",
            description="Research paper or formal publication",
            level="Platinum",
            category="Research",
            status=status,
            details="Found" if status else "Not found"
        ))

        # 3. Conference materials
        conf_files = ["docs/conference-materials.md", "talks/", "presentations/"]
        status = any(self.check_file_exists(f) for f in conf_files)
        checks.append(ComplianceCheck(
            name="Conference materials",
            description="Talk proposals, slides, or presentation materials",
            level="Platinum",
            category="Research",
            status=status,
            details="Found" if status else "Not found"
        ))

        # 4. iSOS integration
        isos_indicators = [
            "isos/",
            "docs/isos.md",
            ".isos.toml",
        ]
        status = any(self.check_file_exists(f) for f in isos_indicators)
        checks.append(ComplianceCheck(
            name="iSOS integration",
            description="Integrated Sovereign Operating System framework",
            level="Platinum",
            category="Architecture",
            status=status,
            details="Found" if status else "Not found"
        ))

        self.report.platinum_checks = checks

    def run_checks(self):
        """Run all compliance checks."""
        print("🔍 Running RSR Compliance Checks...\n")
        print(f"Repository: {self.repo_path}\n")

        self.check_bronze_level()
        self.check_silver_level()
        self.check_gold_level()
        self.check_platinum_level()

    def print_report(self):
        """Print human-readable compliance report."""
        print("=" * 80)
        print("📊 RSR COMPLIANCE REPORT")
        print("=" * 80)
        print()

        levels = [
            ("Bronze", "bronze"),
            ("Silver", "silver"),
            ("Gold", "gold"),
            ("Platinum", "platinum")
        ]

        for level_name, level_key in levels:
            passed, total, percentage = self.report.get_level_score(level_name)
            status_icon = "✅" if percentage == 100 else "⚠️" if percentage >= 50 else "❌"

            print(f"{status_icon} {level_name} Level: {passed}/{total} ({percentage:.1f}%)")
            print("-" * 80)

            checks = getattr(self.report, f"{level_key}_checks")
            for check in checks:
                check_icon = "✓" if check.status else "✗"
                print(f"  [{check_icon}] {check.name}")
                if check.details:
                    print(f"      {check.details}")
            print()

        overall_level = self.report.get_overall_level()
        print("=" * 80)
        print(f"🏆 OVERALL COMPLIANCE LEVEL: {overall_level}")
        print("=" * 80)
        print()

        # Compliance level definitions
        print("📋 Compliance Level Definitions:")
        print("  • Bronze: 100% of Bronze requirements")
        print("  • Silver: 100% of Bronze + 100% of Silver requirements")
        print("  • Gold: Silver + 66%+ of Gold requirements")
        print("  • Platinum: Gold + 66%+ of Platinum requirements")
        print()

    def export_json(self, output_file: str = "rsr_compliance.json"):
        """Export compliance report as JSON."""
        data = {
            "timestamp": datetime.now().isoformat(),
            "repository": str(self.repo_path),
            "overall_level": self.report.get_overall_level(),
            "levels": {}
        }

        for level in ["bronze", "silver", "gold", "platinum"]:
            passed, total, percentage = self.report.get_level_score(level.capitalize())
            checks = getattr(self.report, f"{level}_checks")

            data["levels"][level] = {
                "score": {
                    "passed": passed,
                    "total": total,
                    "percentage": percentage
                },
                "checks": [
                    {
                        "name": c.name,
                        "description": c.description,
                        "category": c.category,
                        "status": c.status,
                        "details": c.details
                    }
                    for c in checks
                ]
            }

        output_path = self.repo_path / output_file
        with open(output_path, 'w') as f:
            json.dump(data, f, indent=2)

        print(f"📄 JSON report exported to: {output_path}")

    def generate_badge(self) -> str:
        """Generate a compliance badge URL."""
        level = self.report.get_overall_level()
        colors = {
            "Platinum": "purple",
            "Gold": "yellow",
            "Silver": "silver",
            "Bronze": "orange",
            "Non-compliant": "red"
        }
        color = colors.get(level, "lightgrey")

        # shields.io badge URL
        badge_url = f"https://img.shields.io/badge/RSR-{level.replace(' ', '%20')}-{color}"

        print(f"🏅 Badge URL: {badge_url}")
        print(f"   Markdown: ![RSR Compliance]({badge_url})")
        print(f"   HTML: <img src=\"{badge_url}\" alt=\"RSR Compliance\">")

        return badge_url


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description="RSR Compliance Checker - Verify Rhodium Standard Repository compliance"
    )
    parser.add_argument(
        "path",
        nargs="?",
        default=".",
        help="Path to repository (default: current directory)"
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Export JSON report"
    )
    parser.add_argument(
        "--json-output",
        default="rsr_compliance.json",
        help="JSON output filename (default: rsr_compliance.json)"
    )
    parser.add_argument(
        "--badge",
        action="store_true",
        help="Generate compliance badge URL"
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="Suppress detailed output"
    )

    args = parser.parse_args()

    checker = RSRChecker(args.path)
    checker.run_checks()

    if not args.quiet:
        checker.print_report()

    if args.json:
        checker.export_json(args.json_output)

    if args.badge:
        checker.generate_badge()

    # Exit with non-zero if not at least Bronze compliant
    overall_level = checker.report.get_overall_level()
    if overall_level == "Non-compliant":
        sys.exit(1)

    sys.exit(0)


if __name__ == "__main__":
    main()
