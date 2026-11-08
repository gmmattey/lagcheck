#!/usr/bin/env python3
"""Small, local-only contracts for Nico metadata and repository discovery."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

IOS_LIMITS = {
    "name": (30, "characters"),
    "subtitle": (30, "characters"),
    "keywords": (100, "utf8_bytes"),
    "promotional_text": (170, "characters"),
    "description": (4000, "characters"),
    "whats_new": (4000, "characters"),
}
ANDROID_LIMITS = {
    "title": (30, "characters"),
    "short_description": (80, "characters"),
    "full_description": (4000, "characters"),
}
EXTERNAL_OPERATIONS = {
    "publish", "submit_for_review", "upload_build", "change_price",
    "change_subscription", "activate_paid_campaign", "change_privacy",
    "delete_published_asset", "reply_to_review", "change_credentials",
    "change_permissions", "create_recurring_cost_resource",
}


def measure(value: str, unit: str) -> int:
    return len(value.encode("utf-8")) if unit == "utf8_bytes" else len(value)


def count_tokens(value: str) -> list[str]:
    return re.findall(r"[\wÀ-ÿ]+", value.casefold())


def validate(payload: dict[str, Any]) -> dict[str, Any]:
    platform = payload.get("platform")
    metadata = payload.get("metadata", {})
    if platform not in {"ios", "android"}:
        return {"valid": False, "errors": ["platform must be ios or android"], "warnings": []}
    if not isinstance(metadata, dict):
        return {"valid": False, "errors": ["metadata must be an object"], "warnings": []}

    limits = IOS_LIMITS if platform == "ios" else ANDROID_LIMITS
    errors: list[dict[str, Any]] = []
    warnings: list[dict[str, Any]] = []
    checks: list[dict[str, Any]] = []
    for field, (limit, unit) in limits.items():
        value = metadata.get(field)
        if value is None:
            continue
        if not isinstance(value, str):
            errors.append({"field": field, "message": "must be a string"})
            continue
        observed = measure(value, unit)
        checks.append({"field": field, "observed": observed, "limit": limit, "unit": unit, "ok": observed <= limit})
        if observed > limit:
            errors.append({"field": field, "message": f"{observed} exceeds {limit} {unit}"})

    title_fields = ("name", "subtitle") if platform == "ios" else ("title", "short_description")
    title_text = " ".join(str(metadata.get(field, "")) for field in title_fields).casefold()
    risky = [term for term in ("#1", "nº 1", "best", "melhor", "grátis", "gratis", "free") if term in title_text]
    if risky:
        warnings.append({"field": ",".join(title_fields), "message": "review title claim or promotion manually", "terms": risky})

    if platform == "ios" and isinstance(metadata.get("keywords"), str):
        keywords = metadata["keywords"]
        if ", " in keywords:
            warnings.append({"field": "keywords", "message": "remove spaces after commas to preserve Apple keyword bytes"})
        name_tokens = set(count_tokens(str(metadata.get("name", "")) + " " + str(metadata.get("subtitle", ""))))
        duplicates = sorted({item.casefold() for item in keywords.split(",") if item.casefold() in name_tokens})
        if duplicates:
            warnings.append({"field": "keywords", "message": "terms duplicate app name or subtitle", "terms": duplicates})

    warnings.append({"field": "policy", "message": "local validation cannot certify store policy, privacy declaration, rights, asset fidelity, console state, or review approval"})
    return {
        "valid": not errors,
        "platform": platform,
        "locale": payload.get("locale", "unspecified"),
        "checks": checks,
        "errors": errors,
        "warnings": warnings,
    }


def discover(root: Path) -> dict[str, Any]:
    found: list[str] = []
    if list(root.glob("*.xcodeproj")) or (root / "Package.swift").exists():
        found.append("ios")
    if (root / "android" / "app" / "build.gradle.kts").exists() or (root / "android" / "app" / "build.gradle").exists():
        found.append("android")
    docs = {
        "ios_listing": "docs/lojas/listing-app-store.md",
        "android_listing": "docs/lojas/listing-google-play.md",
        "release_flow": "docs/06-fluxo-de-release.md",
        "aso_metadata": "docs/lojas/ASO_METADATA.md",
    }
    present = {name: path for name, path in docs.items() if (root / path).exists()}
    product = "LagCheck" if (root / "docs" / "ASO_METADATA.md").exists() else "unknown"
    return {
        "product": product,
        "platforms": found,
        "local_evidence": present,
        "distribution_stage": "documented_or_prepared" if present else "unknown",
        "distribution_state": "not_verified",
        "limitations": [
            "Local files do not prove a public listing, TestFlight/Play track state, approval, publication, rankings, installs, revenue, or retention.",
            "Query an authorized console/API or a public listing before reporting external state.",
        ],
    }


def operation_guard(operation: str, authorized: bool) -> dict[str, Any]:
    if operation in EXTERNAL_OPERATIONS and not authorized:
        return {"operation": operation, "allowed": False, "reason": "explicit owner authorization is required before this external action"}
    return {"operation": operation, "allowed": True, "reason": "this command only evaluates authorization; it performs no external action"}


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Nico inputs locally; never calls a store API.")
    sub = parser.add_subparsers(dest="command", required=True)
    discover_parser = sub.add_parser("discover")
    discover_parser.add_argument("--root", default=".")
    validate_parser = sub.add_parser("validate")
    validate_parser.add_argument("--input", required=True, help="metadata JSON input")
    guard_parser = sub.add_parser("guard-operation")
    guard_parser.add_argument("--operation", required=True)
    guard_parser.add_argument("--authorized", action="store_true")
    args = parser.parse_args()

    if args.command == "discover":
        result = discover(Path(args.root).resolve())
    elif args.command == "validate":
        try:
            result = validate(json.loads(Path(args.input).read_text(encoding="utf-8")))
        except (OSError, json.JSONDecodeError) as exc:
            result = {"valid": False, "errors": [f"invalid input: {exc}"], "warnings": []}
    else:
        result = operation_guard(args.operation, args.authorized)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result.get("valid", result.get("allowed", True)) else 1


if __name__ == "__main__":
    sys.exit(main())
