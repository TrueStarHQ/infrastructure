# TrueStar infrastructure

This directory contains infrastructure as code for configuring TrueStar's production resources on Google Cloud. Currently using [Terraform](https://www.terraform.io/).

**Note**: This infrastructure is for TrueStar's official deployment and is not intended for personal use.

## What this creates

- **Google Cloud Run Service**: Hosts the TrueStar API with health checks
- **Artifact Registry Repository**: Stores Docker images for deployment
- **Secret Manager**: Securely stores secret keys
- **Service Account**: With appropriate permissions for the API
- **Domain Mapping**: Optional custom domain configuration

## Prerequisites

1. **Install Terraform** - See [official installation guide](https://developer.hashicorp.com/terraform/install)

2. **Install Google Cloud SDK** - See [official installation guide](https://cloud.google.com/sdk/docs/install)

3. **Configure Google Cloud access**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   gcloud config set project [PROJECT-ID]
   ```

## Setup

Run all commands from the `infrastructure/` directory:

### 1. Create the state bucket
Terraform is configured to store its state in a Google Cloud Storage bucket. This is a one-time setup per project.

```bash
# Replace [PROJECT-ID] with the actual project ID
gsutil mb -p [PROJECT-ID] gs://terraform-state-[PROJECT-ID]
gsutil versioning set on gs://terraform-state-[PROJECT-ID]
```

### 2. Configure and deploy
```bash
# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with the project ID and other variables

# Initialize Terraform with the state bucket
# Replace [PROJECT-ID] with the actual project ID
terraform init -backend-config="bucket=terraform-state-[PROJECT-ID]"

# Preview what will be created
terraform plan

# Create the infrastructure
terraform apply
```

## Security notes

- Never commit `terraform.tfvars` 
- The secret keys are stored in Secret Manager, not environment variables
- Cloud Run service is publicly accessible (required for browser extension)