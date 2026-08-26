FROM python:3.12-slim

WORKDIR /app

COPY scripts/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY scripts/load_env.py .
COPY scripts/seed_templates.py .

ENTRYPOINT ["python", "/app/seed_templates.py", "--templates-dir", "/templates"]
