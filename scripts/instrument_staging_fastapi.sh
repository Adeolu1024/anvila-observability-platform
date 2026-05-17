#!/usr/bin/env bash
set -euo pipefail

MONITORING_SERVER_IP="${MONITORING_SERVER_IP:?Set MONITORING_SERVER_IP before running this script}"
APP_DIR="${APP_DIR:-/home/agentforge/anvila/backend/staging}"
PM2_APP_NAME="${PM2_APP_NAME:-backend-staging}"

cd "${APP_DIR}"

uv pip install \
  opentelemetry-distro \
  opentelemetry-exporter-otlp \
  opentelemetry-instrumentation-fastapi \
  opentelemetry-instrumentation-asgi \
  opentelemetry-instrumentation-logging \
  opentelemetry-instrumentation-httpx \
  opentelemetry-instrumentation-sqlalchemy \
  opentelemetry-instrumentation-asyncpg

opentelemetry-bootstrap -a install

pm2 delete "${PM2_APP_NAME}" || true
OTEL_SERVICE_NAME=anvila-api-staging \
OTEL_RESOURCE_ATTRIBUTES=deployment.environment=staging,service.namespace=anvila \
OTEL_EXPORTER_OTLP_ENDPOINT="http://${MONITORING_SERVER_IP}:4318" \
OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf \
OTEL_TRACES_EXPORTER=otlp \
OTEL_METRICS_EXPORTER=none \
OTEL_PYTHON_LOG_CORRELATION=true \
pm2 start bash --name "${PM2_APP_NAME}" -- -c "opentelemetry-instrument uv run uvicorn app.main:app --host 0.0.0.0 --port 8000"

pm2 save

echo "Staging FastAPI instrumentation enabled for ${PM2_APP_NAME}."

