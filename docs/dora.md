# DORA Metrics Plan

## Deployment Frequency

Source: GitHub Actions deployment workflow runs.

Workflows:

- `Deploy Staging` on branch `staging`
- `Deploy Production` on branch `main` and manual `workflow_dispatch`

Classification:

| Level | Deployment Frequency |
| --- | --- |
| Elite | On demand, multiple per day |
| High | Between once per day and once per week |
| Medium | Between once per week and once per month |
| Low | Less than once per month |

## Lead Time for Changes

Target measurement:

```text
commit timestamp -> workflow started -> workflow completed -> deployment confirmed
```

The final implementation should export these as Prometheus metrics from GitHub Actions or a small GitHub exporter.

## Change Failure Rate

```promql
anvila_deployment_failures_total / clamp_min(anvila_deployments_total, 1)
```

SLO threshold: keep CFR under 15%.

## Mean Time to Restore

```promql
anvila_incident_mttr_minutes
```

Target: restore service within 60 minutes.

## Toil Identified

1. Manual dashboard creation in Grafana.
   Automation: all dashboards are provisioned from JSON files.

2. Manual alert investigation from vague Slack messages.
   Automation: Alertmanager templates include severity, host, metric value, dashboard link, and runbook link.

3. Manual monitoring server setup.
   Automation: Terraform creates the monitoring server and starts services through systemd.

