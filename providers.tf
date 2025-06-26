terraform {
  required_version = ">= 1.0"
  
  backend "gcs" {
    # Bucket name must be configured during `terraform init` using the `-backend-config` flag
    # because backend configuration doesn't support variables: https://github.com/hashicorp/terraform/issues/13022
    # 
    # Usage: terraform init -backend-config="bucket=terraform-state-[PROJECT-ID]"
  }
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}