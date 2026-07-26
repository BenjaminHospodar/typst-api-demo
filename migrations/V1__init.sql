-- Template registry
CREATE TABLE templates (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    form        TEXT NOT NULL,
    version     TEXT NOT NULL,
    typ_source  TEXT NOT NULL,
    schema      JSONB NOT NULL DEFAULT '{}',
    active      BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT now(),
    UNIQUE (form, version)
);

CREATE INDEX idx_templates_form_version ON templates (form, version) WHERE active;

-- Job audit log
CREATE TABLE jobs (
    id           TEXT PRIMARY KEY,
    form         TEXT NOT NULL,
    version      TEXT NOT NULL,
    status       TEXT NOT NULL,
    queued_at    TIMESTAMPTZ DEFAULT now(),
    started_at   TIMESTAMPTZ,
    finished_at  TIMESTAMPTZ,
    error_msg    TEXT,
    page_count   INT,
    compile_ms   INT
);
