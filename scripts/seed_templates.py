#!/usr/bin/env python3
"""Seed templates/ into PostgreSQL. Skips _test_compile.typ CLI fixtures."""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

import psycopg

from load_env import database_url, load_dotenv

SKIP_FILES = {"_test_compile.typ"}

INSERT_SQL = """
INSERT INTO templates (form, version, typ_source, schema, active)
VALUES (%s, %s, %s, %s::jsonb, true)
ON CONFLICT (form, version)
DO UPDATE SET typ_source = EXCLUDED.typ_source,
              schema = EXCLUDED.schema
"""


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def parse_template(path: Path) -> tuple[str, str]:
    form = path.parent.name
    version = path.stem.removeprefix("v")
    return form, version


def load_schema(typ_path: Path) -> str:
    schema_path = typ_path.with_name(f"{typ_path.stem}.schema.json")
    if not schema_path.is_file():
        return "{}"
    text = schema_path.read_text(encoding="utf-8").strip() or "{}"
    json.loads(text)
    return text


def discover_templates(templates_dir: Path) -> list[Path]:
    paths = sorted(templates_dir.glob("*/*.typ"))
    return [p for p in paths if p.name not in SKIP_FILES and p.is_file()]


def wait_for_postgres(dsn: str, timeout: int) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with psycopg.connect(dsn) as conn:
                conn.execute("SELECT 1")
            return
        except psycopg.OperationalError:
            time.sleep(1)
    raise TimeoutError(f"PostgreSQL not ready after {timeout}s")


def seed(templates_dir: Path, dsn: str, dry_run: bool = False) -> int:
    templates = discover_templates(templates_dir)
    if not templates:
        print(f"No templates found under {templates_dir}", file=sys.stderr)
        return 0

    if dry_run:
        for path in templates:
            form, version = parse_template(path)
            print(f"  -> {form} v{version}")
        return len(templates)

    count = 0
    with psycopg.connect(dsn) as conn:
        for path in templates:
            form, version = parse_template(path)
            source = path.read_text(encoding="utf-8")
            schema = load_schema(path)
            print(f"  -> {form} v{version}")
            conn.execute(INSERT_SQL, (form, version, source, schema))
            count += 1
        conn.commit()
    return count


def main() -> int:
    load_dotenv()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--templates-dir",
        type=Path,
        default=repo_root() / "templates",
    )
    parser.add_argument("--database-url", default=database_url())
    parser.add_argument("--no-wait", action="store_true")
    parser.add_argument("--wait-timeout", type=int, default=60)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    print("=== PDF Gen Seeder ===")
    if not args.no_wait:
        print("Waiting for PostgreSQL...")
        wait_for_postgres(args.database_url, args.wait_timeout)
        print("PostgreSQL ready.")

    print(f"Seeding templates from {args.templates_dir}...")
    count = seed(args.templates_dir, args.database_url, dry_run=args.dry_run)
    print(f"\n=== Seeder complete: {count} templates seeded ===")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
