# Anvila Observability Platform

Production-grade observability stack for the Anvila API using LGTM:

- Loki for logs
- Grafana for dashboards
- Tempo for traces
- Prometheus for metrics
- Alertmanager for Slack alerts
- Node Exporter and Blackbox Exporter for infrastructure and uptime monitoring
- OpenTelemetry Collector for logs and traces

The monitoring stack is designed to run on a dedicated AWS EC2 monitoring server using systemd services. Docker is intentionally not used on the server.


## Known Targets

| Environment | URL | App server | Port |
| --- | --- | --- | --- |
| Staging | `https://api.staging.anvila.hng14.com` | `13.60.76.205` | `8000` |
| Production | `https://api.anvila.hng14.com` | `13.60.76.205` | `8001` |

Staging and production currently run on the same known application server. Prometheus scrapes host-level metrics from this server through Node Exporter, while Blackbox Exporter probes both public API URLs.

## One-Command Deployment

After filling `terraform/terraform.tfvars`, run:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Terraform creates the monitoring EC2 instance, opens the required monitoring ports, uploads all LGTM configuration, and starts systemd services through the bootstrap script.

## Required Values Before Final Deployment

Fill these in `terraform/terraform.tfvars`:

```hcl
aws_region              = "us-east-1"
key_name                = "your-aws-keypair-name"
ssh_private_key_path    = "~/.ssh/your-key.pem"
monitoring_allowed_cidr = "YOUR_PUBLIC_IP/32"
slack_webhook_url       = "https://hooks.slack.com/services/..."
```

Still needed from the team:

- Slack incoming webhook for `#DevOps-Alerts`
- final GitHub token for the DORA exporter, stored only on the monitoring server

For a beginner-friendly explanation of these values, see `docs/beginner-deployment-checklist.md`.

The GitHub token is deliberately not stored in Terraform or Git. After a fresh deploy, configure `/etc/anvila-dora-exporter.env` using `docs/dora-exporter.md`.

Current deployed monitoring server:

```text
Grafana: http://34.204.43.206:3000
Prometheus: http://34.204.43.206:9090
Alertmanager: http://34.204.43.206:9093
```

The app currently runs with Nginx and PM2:

```text
backend-staging: port 8000
backend-production: port 8001
app server public IP: 13.60.76.205
app server private IP: 172.31.19.1
```

Staging instrumentation instructions are in `docs/app-instrumentation.md`.

## Architecture

```mermaid
flowchart LR
  user["Users"] --> nginx["Nginx / Anvila API"]
  github["GitHub Actions"] --> prom["Prometheus"]
  nginx --> blackbox["Blackbox Exporter"]
  appnode["App Server\nNode Exporter + OTel Collector"] --> prom
  appnode --> loki["Loki"]
  appnode --> tempo["Tempo"]
  blackbox --> prom
  prom --> grafana["Grafana"]
  loki --> grafana
  tempo --> grafana
  prom --> alertmanager["Alertmanager"]
  alertmanager --> slack["#DevOps-Alerts"]
```

## Default Ports

| Component | Port |
| --- | --- |
| Grafana | `3000` |
| Prometheus | `9090` |
| Alertmanager | `9093` |
| Loki | `3100` |
| Tempo | `3200`, OTLP gRPC `4317`, OTLP HTTP `4318` |
| Blackbox Exporter | `9115` |
| Node Exporter | `9100` |

## Dashboards

Provisioned dashboard JSON files live in `config/grafana/dashboards`.

- DORA Metrics
- SLO & Error Budget
- Node Exporter
- Blackbox Exporter
- Unified Observability

## Error Budget Policy

For the main availability SLO, Anvila targets 99.5% successful probes over 30 days.

- 0-50% budget consumed: normal delivery continues.
- 50-75% consumed: team reviews recent failures and prioritizes reliability fixes in the next sprint.
- 75-100% consumed: new risky feature deployments require approval from the Anvila DevOps team.
- 100% consumed: feature freeze for the affected service until reliability is restored or the team explicitly accepts the risk.

SLOs should be reviewed weekly during the task period and monthly in normal production operation.

## Team

- Bimbo_og
- DorcasBD
- nyson

Incident ownership: Anvila DevOps team.
