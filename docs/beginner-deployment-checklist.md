# Beginner Deployment Checklist

This checklist explains what is needed before the monitoring server can be created on AWS.

## 1. AWS EC2 Instance

We do not create the EC2 instance manually in the AWS console if we can avoid it.

Terraform should create it for us.

To do that, Terraform needs:

- AWS account access
- AWS region
- EC2 key pair name
- SSH private key file

## 2. AWS Region

Your AWS Console is currently set to N. Virginia, so the default region is:

```text
us-east-1
```

Confirm this in AWS if possible.

## 3. EC2 Key Pair

An EC2 key pair is what lets us SSH into the monitoring server.

In AWS Console:

```text
EC2 -> Key Pairs -> Create key pair
```

Recommended name:

```text
anvila-monitoring-key
```

Download the `.pem` file and keep it safe.

Terraform will need:

```hcl
key_name             = "anvila-monitoring-key"
ssh_private_key_path = "C:/path/to/anvila-monitoring-key.pem"
```

## 4. Public IP For Grafana Access

This means your own internet IP address.

We use it so only your computer can open Grafana, Prometheus, and Alertmanager.

Example:

```text
102.88.12.34/32
```

The `/32` means only that one IP is allowed.

If your IP changes later, update `monitoring_allowed_cidr` and rerun Terraform.

## 5. Slack Webhook

The Slack webhook is required before real alerts can be sent to `#DevOps-Alerts`.

Until the mentor sends it, keep this placeholder:

```hcl
slack_webhook_url = "REPLACE_WITH_SLACK_WEBHOOK"
```

## 6. Application Server IP

We confirmed that staging and production currently run on the same app server:

```text
Public IP: 13.60.76.205
Private IP: 172.31.19.1
Staging port: 8000
Production port: 8001
```

This server runs:

```text
https://api.staging.anvila.hng14.com
https://api.anvila.hng14.com
```

Prometheus scrapes host-level metrics from this server through Node Exporter on port `9100`. Blackbox Exporter probes both public URLs from the monitoring server.

## 7. App Server Security Group

The app server security group controls which traffic can reach the app server.

For Node Exporter metrics, the app server must allow:

```text
TCP 9100 from the monitoring server IP
```

If this is not configured, Prometheus will not be able to scrape CPU, memory, disk, and network metrics from the app server.

## 8. Terraform

Terraform is the tool that creates the monitoring server and applies the configuration.

Install it on the machine where you will run deployment commands.

After installation, this should work:

```bash
terraform version
```

## 9. Minimum First Deployment Values

Before first deployment, collect:

```text
AWS region:
AWS key pair name:
SSH private key path:
Your public IP address with /32:
Slack webhook URL, or placeholder for now:
```
