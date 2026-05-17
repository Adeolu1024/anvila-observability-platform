# App Server Setup

The monitoring server can probe Anvila API over HTTP immediately, but host metrics and logs require lightweight agents on the app server.

Run this on the app server after the monitoring server exists:

```bash
sudo MONITORING_SERVER_IP="<monitoring-public-ip>" bash scripts/install_app_observability_agent.sh
```

The current Anvila API runs with PM2, so the collector reads PM2 backend logs from `/home/agentforge/.pm2/logs`.

The app server security group must allow:

| Port | Direction | Source |
| --- | --- | --- |
| `9100` | inbound | monitoring server IP |

The monitoring server security group already allows OTLP ports `4317` and `4318` from the app server IP.

## Python OpenTelemetry

For Python, install instrumentation dependencies in the application environment:

```bash
pip install opentelemetry-distro opentelemetry-exporter-otlp
opentelemetry-bootstrap -a install
```

Then run the app with:

```bash
OTEL_SERVICE_NAME=anvila-api \
OTEL_EXPORTER_OTLP_ENDPOINT=http://<monitoring-public-ip>:4318 \
OTEL_TRACES_EXPORTER=otlp \
OTEL_METRICS_EXPORTER=none \
opentelemetry-instrument <existing-start-command>
```

The exact command depends on whether the app is started by Gunicorn, Uvicorn, PM2, or systemd.
