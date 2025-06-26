variable "project_id" {
  description = "The Google Cloud project ID"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters, start with a letter, and contain only lowercase letters, numbers, and hyphens"
  }
}

variable "region" {
  description = "The Google Cloud region for resources"
  type        = string
  default     = "us-central1"
  
  validation {
    condition = contains([
      "us-central1", "us-east1", "us-east4", "us-west1", "us-west2", "us-west3", "us-west4",
      "europe-west1", "europe-west2", "europe-west3", "europe-west4", "europe-west6",
      "asia-east1", "asia-east2", "asia-northeast1", "asia-northeast2", "asia-northeast3",
      "asia-southeast1", "asia-southeast2", "asia-south1"
    ], var.region)
    error_message = "Region must be a valid Google Cloud region for Cloud Run"
  }
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stage, prod"
  }
}

variable "api_domain" {
  description = "Custom domain for the API (e.g., api.truestar.pro)"
  type        = string
  default     = ""
}

variable "openai_api_key" {
  description = "OpenAI API key for review analysis"
  type        = string
  sensitive   = true
  
  validation {
    condition     = can(regex("^sk-[a-zA-Z0-9_-]{48,}$", var.openai_api_key))
    error_message = "OpenAI API key must start with 'sk-' followed by at least 48 alphanumeric characters"
  }
}

variable "api_image" {
  description = "Docker image for the API service (e.g., us-central1-docker.pkg.dev/your-project/main/api:latest)"
  type        = string
}

variable "api_memory" {
  description = "Memory allocation for Cloud Run service"
  type        = string
  default     = "512Mi"
  
  validation {
    condition     = can(regex("^[0-9]+(Mi|Gi)$", var.api_memory))
    error_message = "Memory must be specified in Mi or Gi (e.g., 512Mi, 1Gi)"
  }
}

variable "api_cpu" {
  description = "CPU allocation for Cloud Run service" 
  type        = string
  default     = "1"
  
  validation {
    condition = contains(["1", "2", "4", "8"], var.api_cpu)
    error_message = "CPU must be one of: 1, 2, 4, 8"
  }
}

variable "api_min_instances" {
  description = "Minimum number of Cloud Run instances"
  type        = number
  default     = 0
  
  validation {
    condition     = var.api_min_instances >= 0 && var.api_min_instances <= 100
    error_message = "Minimum instances must be between 0 and 100"
  }
}

variable "api_max_instances" {
  description = "Maximum number of Cloud Run instances"
  type        = number
  default     = 100
  
  validation {
    condition     = var.api_max_instances >= 1 && var.api_max_instances <= 1000
    error_message = "Maximum instances must be between 1 and 1000"
  }
}