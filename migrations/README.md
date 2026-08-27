# Migrations

This directory is the **only** schema source. Compose mounts it at Postgres `docker-entrypoint-initdb.d` (applied on first data volume only). Kustomize copies `V1__init.sql` into the in-cluster Postgres init ConfigMap.

Do not add a second DDL path (no seeder SQL, no Hibernate `ddl-auto: update`).
