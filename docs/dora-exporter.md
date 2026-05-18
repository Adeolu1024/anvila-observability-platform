# DORA Exporter

The DORA exporter exposes GitHub Actions deployment workflow data as Prometheus metrics.

Source repository:

```text
hngprojects/anvila-backend
```

Tracked workflows:

```text
Deploy Staging
Deploy Production
```

Metrics exposed on port `9999`:

```text
anvila_deployments_total
anvila_deployment_failures_total
anvila_deployment_frequency_7d
anvila_lead_time_minutes
anvila_incident_mttr_minutes
anvila_github_actions_exporter_up
```

## Token

Use a GitHub personal access token with read access to Actions workflow runs.

Do not commit the token.

The live server stores it in:

```text
/etc/anvila-dora-exporter.env
```

## Systemd Service

The exporter runs as:

```text
anvila-dora-exporter.service
```

Prometheus scrapes:

```text
localhost:9999
```

