#!/usr/bin/env bash
set -euo pipefail

NODE_EXPORTER_VERSION="1.8.1"
OTELCOL_VERSION="0.103.1"

MONITORING_SERVER_IP="${MONITORING_SERVER_IP:?Set MONITORING_SERVER_IP before running this script}"
PM2_LOG_DIR="${PM2_LOG_DIR:-/home/agentforge/.pm2/logs}"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y curl tar unzip

useradd --system --no-create-home --shell /usr/sbin/nologin node_exporter || true

curl -fsSL "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" -o /tmp/node_exporter.tar.gz
mkdir -p /tmp/node_exporter
tar -xzf /tmp/node_exporter.tar.gz -C /tmp/node_exporter --strip-components=1
install -m 0755 /tmp/node_exporter/node_exporter /usr/local/bin/node_exporter

curl -fsSL "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTELCOL_VERSION}/otelcol-contrib_${OTELCOL_VERSION}_linux_amd64.deb" -o /tmp/otelcol.deb
dpkg -i /tmp/otelcol.deb || apt-get -f install -y
usermod -aG adm,systemd-journal otelcol-contrib || true

mkdir -p /etc/otelcol-contrib
cat >/etc/otelcol-contrib/config.yaml <<EOF
receivers:
  journald:
    directory: /var/log/journal
    units:
      - nginx.service
  filelog:
    include:
      - ${PM2_LOG_DIR}/backend-staging-out.log
      - ${PM2_LOG_DIR}/backend-staging-error.log
      - ${PM2_LOG_DIR}/backend-production-out.log
      - ${PM2_LOG_DIR}/backend-production-error.log
    start_at: end
    operators:
      - type: regex_parser
        regex: '^(?P<body>.*)$'
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch: {}
  resource:
    attributes:
      - key: service.name
        value: anvila-api
        action: upsert
      - key: deployment.environment
        value: staging
        action: upsert

exporters:
  otlp/monitoring:
    endpoint: ${MONITORING_SERVER_IP}:4317
    tls:
      insecure: true

service:
  pipelines:
    logs:
      receivers: [journald, filelog]
      processors: [resource, batch]
      exporters: [otlp/monitoring]
    traces:
      receivers: [otlp]
      processors: [resource, batch]
      exporters: [otlp/monitoring]
EOF

cat >/etc/systemd/system/node-exporter.service <<'SERVICE'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now node-exporter otelcol-contrib

echo "App observability agent installed. Ensure the app server security group allows TCP 9100 from the monitoring server."
