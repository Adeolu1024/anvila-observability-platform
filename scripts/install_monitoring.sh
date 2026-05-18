#!/usr/bin/env bash
set -euo pipefail

PROM_VERSION="2.52.0"
ALERTMANAGER_VERSION="0.27.0"
NODE_EXPORTER_VERSION="1.8.1"
BLACKBOX_VERSION="0.25.0"
LOKI_VERSION="3.1.0"
TEMPO_VERSION="2.5.0"
OTELCOL_VERSION="0.103.1"
GRAFANA_VERSION="11.0.0"

CONFIG_SRC="/tmp/anvila-observability-config"
INSTALL_ROOT="/opt/anvila-observability"
GRAFANA_PUBLIC_URL="${GRAFANA_PUBLIC_URL:-http://localhost:3000}"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y curl unzip tar adduser libfontconfig1 musl gettext-base

mkdir -p "${INSTALL_ROOT}" /etc/prometheus/rules /etc/alertmanager /etc/loki /etc/tempo /etc/otelcol-contrib \
  /etc/grafana/provisioning/datasources /etc/grafana/provisioning/dashboards /var/lib/prometheus \
  /var/lib/alertmanager /var/lib/loki /var/lib/tempo /var/log/anvila-observability

useradd --system --no-create-home --shell /usr/sbin/nologin prometheus || true
useradd --system --no-create-home --shell /usr/sbin/nologin alertmanager || true
useradd --system --no-create-home --shell /usr/sbin/nologin loki || true
useradd --system --no-create-home --shell /usr/sbin/nologin tempo || true
useradd --system --no-create-home --shell /usr/sbin/nologin otelcol || true

download_tar() {
  local url="$1"
  local dest="$2"
  curl -fsSL "$url" -o "/tmp/${dest}.tar.gz"
  mkdir -p "/tmp/${dest}"
  tar -xzf "/tmp/${dest}.tar.gz" -C "/tmp/${dest}" --strip-components=1
}

download_zip() {
  local url="$1"
  local dest="$2"
  curl -fsSL "$url" -o "/tmp/${dest}.zip"
  mkdir -p "/tmp/${dest}"
  unzip -oq "/tmp/${dest}.zip" -d "/tmp/${dest}"
}

download_tar "https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz" "prometheus"
install -m 0755 /tmp/prometheus/prometheus /usr/local/bin/prometheus
install -m 0755 /tmp/prometheus/promtool /usr/local/bin/promtool

download_tar "https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz" "alertmanager"
install -m 0755 /tmp/alertmanager/alertmanager /usr/local/bin/alertmanager
install -m 0755 /tmp/alertmanager/amtool /usr/local/bin/amtool

download_tar "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" "node_exporter"
install -m 0755 /tmp/node_exporter/node_exporter /usr/local/bin/node_exporter

download_tar "https://github.com/prometheus/blackbox_exporter/releases/download/v${BLACKBOX_VERSION}/blackbox_exporter-${BLACKBOX_VERSION}.linux-amd64.tar.gz" "blackbox_exporter"
install -m 0755 /tmp/blackbox_exporter/blackbox_exporter /usr/local/bin/blackbox_exporter

download_zip "https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/loki-linux-amd64.zip" "loki"
install -m 0755 /tmp/loki/loki-linux-amd64 /usr/local/bin/loki

curl -fsSL "https://github.com/grafana/tempo/releases/download/v${TEMPO_VERSION}/tempo_${TEMPO_VERSION}_linux_amd64.tar.gz" -o /tmp/tempo.tar.gz
rm -rf /tmp/tempo
mkdir -p /tmp/tempo
tar -xzf /tmp/tempo.tar.gz -C /tmp/tempo
install -m 0755 "$(find /tmp/tempo -type f -name tempo | head -n 1)" /usr/local/bin/tempo

curl -fsSL "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTELCOL_VERSION}/otelcol-contrib_${OTELCOL_VERSION}_linux_amd64.deb" -o /tmp/otelcol.deb
dpkg -i /tmp/otelcol.deb || apt-get -f install -y
usermod -aG adm,systemd-journal otelcol-contrib || true

curl -fsSL "https://dl.grafana.com/oss/release/grafana_${GRAFANA_VERSION}_amd64.deb" -o /tmp/grafana.deb
dpkg -i /tmp/grafana.deb || apt-get -f install -y

envsubst < "${CONFIG_SRC}/prometheus/prometheus.yml" > /etc/prometheus/prometheus.yml
envsubst '${GRAFANA_PUBLIC_URL}' < "${CONFIG_SRC}/prometheus/alerts.yml" > /etc/prometheus/rules/alerts.yml
envsubst < "${CONFIG_SRC}/alertmanager/alertmanager.yml" > /etc/alertmanager/alertmanager.yml
cp "${CONFIG_SRC}/alertmanager/slack.tmpl" /etc/alertmanager/slack.tmpl
cp "${CONFIG_SRC}/prometheus/blackbox.yml" /etc/prometheus/blackbox.yml
cp "${CONFIG_SRC}/loki/loki.yml" /etc/loki/loki.yml
cp "${CONFIG_SRC}/tempo/tempo.yml" /etc/tempo/tempo.yml
cp "${CONFIG_SRC}/otelcol/otelcol.yml" /etc/otelcol-contrib/config.yaml
cp "${CONFIG_SRC}/grafana/provisioning/datasources/datasources.yml" /etc/grafana/provisioning/datasources/datasources.yml
cp "${CONFIG_SRC}/grafana/provisioning/dashboards/dashboards.yml" /etc/grafana/provisioning/dashboards/dashboards.yml
mkdir -p /var/lib/grafana/dashboards
cp "${CONFIG_SRC}/grafana/dashboards/"*.json /var/lib/grafana/dashboards/

if [ -f /tmp/anvila-dora-exporter.py ]; then
  install -m 0755 /tmp/anvila-dora-exporter.py /usr/local/bin/anvila-dora-exporter
fi

chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
chown -R alertmanager:alertmanager /etc/alertmanager /var/lib/alertmanager
chown -R loki:loki /etc/loki /var/lib/loki
chown -R tempo:tempo /etc/tempo /var/lib/tempo
chown -R grafana:grafana /var/lib/grafana/dashboards /etc/grafana/provisioning

cat >/etc/systemd/system/prometheus.service <<'SERVICE'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus --storage.tsdb.retention.time=30d --web.enable-lifecycle
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

cat >/etc/systemd/system/alertmanager.service <<'SERVICE'
[Unit]
Description=Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager --config.file=/etc/alertmanager/alertmanager.yml --storage.path=/var/lib/alertmanager
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

cat >/etc/systemd/system/blackbox-exporter.service <<'SERVICE'
[Unit]
Description=Blackbox Exporter
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/blackbox_exporter --config.file=/etc/prometheus/blackbox.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

cat >/etc/systemd/system/node-exporter.service <<'SERVICE'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

cat >/etc/systemd/system/loki.service <<'SERVICE'
[Unit]
Description=Loki
Wants=network-online.target
After=network-online.target

[Service]
User=loki
Group=loki
Type=simple
ExecStart=/usr/local/bin/loki -config.file=/etc/loki/loki.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

cat >/etc/systemd/system/tempo.service <<'SERVICE'
[Unit]
Description=Tempo
Wants=network-online.target
After=network-online.target

[Service]
User=tempo
Group=tempo
Type=simple
ExecStart=/usr/local/bin/tempo -config.file=/etc/tempo/tempo.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

cat >/etc/systemd/system/anvila-dora-exporter.service <<'SERVICE'
[Unit]
Description=Anvila DORA GitHub Actions Exporter
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
EnvironmentFile=/etc/anvila-dora-exporter.env
ExecStart=/usr/bin/python3 /usr/local/bin/anvila-dora-exporter
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
if [ -f /usr/local/bin/anvila-dora-exporter ] && [ -f /etc/anvila-dora-exporter.env ]; then
  systemctl enable --now anvila-dora-exporter
fi
systemctl enable --now node-exporter blackbox-exporter loki tempo otelcol-contrib prometheus alertmanager grafana-server

echo "Monitoring stack installed."
