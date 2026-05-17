variable "aws_region" {
  description = "AWS region for the monitoring server."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name used for AWS resource tags."
  type        = string
  default     = "anvila-observability"
}

variable "instance_type" {
  description = "Monitoring server instance type."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Existing AWS EC2 key pair name."
  type        = string
}

variable "ssh_private_key_path" {
  description = "Local path to the SSH private key matching key_name."
  type        = string
}

variable "monitoring_allowed_cidr" {
  description = "CIDR allowed to access Grafana/Prometheus/Alertmanager directly. Use your public IP /32."
  type        = string
}

variable "app_server_ip" {
  description = "Staging application server IP."
  type        = string
  default     = "13.60.76.205"
}

variable "app_ssh_user" {
  description = "SSH username for the app server."
  type        = string
  default     = "agentforge"
}

variable "staging_url" {
  description = "Staging API URL."
  type        = string
  default     = "https://api.staging.anvila.hng14.com"
}

variable "production_url" {
  description = "Production API URL."
  type        = string
  default     = "https://api.anvila.hng14.com"
}

variable "slack_webhook_url" {
  description = "Incoming Slack webhook for #DevOps-Alerts."
  type        = string
  sensitive   = true
  default     = "https://hooks.slack.com/services/REPLACE/ME/LATER"
}
