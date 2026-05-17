# App Instrumentation

The Anvila backend is a Python FastAPI application running under PM2:

| Environment | PM2 name | Port | Working directory |
| --- | --- | --- | --- |
| Staging | `backend-staging` | `8000` | `/home/agentforge/anvila/backend/staging` |
| Production | `backend-production` | `8001` | `/home/agentforge/anvila/backend/production` |

Instrumentation should be introduced on staging first.

## Staging Command

Upload `scripts/instrument_staging_fastapi.sh` to the app server, then run:

```bash
MONITORING_SERVER_IP="34.204.43.206" bash /tmp/instrument_staging_fastapi.sh
```

This installs OpenTelemetry Python packages into the staging environment and restarts only the `backend-staging` PM2 process with:

```bash
opentelemetry-instrument uv run uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Expected Result

After a few requests to staging:

- traces should arrive in Tempo
- logs should include trace correlation fields where OpenTelemetry logging integration applies
- Grafana should allow drill-down from logs to traces through the Loki derived field

## Rollback

If staging breaks, restart the original command:

```bash
cd /home/agentforge/anvila/backend/staging
pm2 delete backend-staging
pm2 start bash --name backend-staging -- -c "uv run uvicorn app.main:app --host 0.0.0.0 --port 8000"
pm2 save
```

Do not instrument production until staging traces are verified.

