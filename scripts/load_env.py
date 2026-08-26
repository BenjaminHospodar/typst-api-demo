"""Load the repo-root .env into os.environ (does not override existing vars)."""

from __future__ import annotations

import os
from pathlib import Path


def load_dotenv(path: Path | None = None) -> Path | None:
    env_path = path or Path(__file__).resolve().parent.parent / ".env"
    if not env_path.is_file():
        return None
    for raw in env_path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        os.environ.setdefault(key, value)
    return env_path


def database_url() -> str:
    if url := os.environ.get("DATABASE_URL"):
        return url
    user = os.environ.get("POSTGRES_USER", "pdfgen")
    password = os.environ.get("POSTGRES_PASSWORD", "pdfgen")
    host = os.environ.get("POSTGRES_HOST", "localhost")
    port = os.environ.get("POSTGRES_PORT", "5432")
    db = os.environ.get("POSTGRES_DB", "pdfgen")
    return f"postgresql://{user}:{password}@{host}:{port}/{db}"


def redis_url() -> str:
    if url := os.environ.get("REDIS_URL"):
        return url
    host = os.environ.get("REDIS_HOST", "localhost")
    port = os.environ.get("REDIS_PORT", "6379")
    password = os.environ.get("REDIS_PASSWORD", "")
    if password:
        return f"redis://:{password}@{host}:{port}/0"
    return f"redis://{host}:{port}/0"


def base_url() -> str:
    return os.environ.get("BASE_URL", "http://localhost:8080")
