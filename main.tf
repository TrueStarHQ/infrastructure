# Enable required APIs
resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager_api" {
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry_api" {
  service = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Artifact Registry repository for Docker images
resource "google_artifact_registry_repository" "main" {
  location      = var.region
  repository_id = "main"
  description   = "Docker images for application services"
  format        = "DOCKER"
  
  depends_on = [google_project_service.artifactregistry_api]
}

# Secret Manager for OpenAI API Key
resource "google_secret_manager_secret" "openai_api_key" {
  secret_id = "openai-api-key"
  
  replication {
    auto {}
  }
  
  depends_on = [google_project_service.secretmanager_api]
}

resource "google_secret_manager_secret_version" "openai_api_key" {
  secret      = google_secret_manager_secret.openai_api_key.id
  secret_data = var.openai_api_key
}

# Service Account for Cloud Run
resource "google_service_account" "api_sa" {
  account_id   = "api-sa"
  display_name = "API Service Account"
  description  = "Service account for Cloud Run API"
}

# IAM for Service Account - Secret Manager access
resource "google_project_iam_member" "api_sa_secretmanager" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.api_sa.email}"
}

# Cloud Run Service
resource "google_cloud_run_v2_service" "api" {
  name     = "api"
  location = var.region
  
  template {
    service_account = google_service_account.api_sa.email
    
    containers {
      image = var.api_image
      
      ports {
        container_port = 8080
      }
      
      env {
        name  = "NODE_ENV"
        value = var.environment
      }
      
      env {
        name  = "GCP_PROJECT"
        value = var.project_id
      }
      
      env {
        name = "OPENAI_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.openai_api_key.secret_id
            version = "latest"
          }
        }
      }
      
      resources {
        limits = {
          cpu    = var.api_cpu
          memory = var.api_memory
        }
        startup_cpu_boost = true
      }
      
      # Health check configuration
      liveness_probe {
        http_get {
          path = "/health"
          port = 8080
        }
        initial_delay_seconds = 10
        period_seconds        = 30
        timeout_seconds       = 5
        failure_threshold     = 3
      }
    }
    
    scaling {
      min_instance_count = var.api_min_instances
      max_instance_count = var.api_max_instances
    }
  }
  
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
  
  depends_on = [
    google_project_service.run_api,
    google_secret_manager_secret_version.openai_api_key
  ]
}

# Allow unauthenticated access to Cloud Run service
resource "google_cloud_run_service_iam_member" "public_access" {
  location = google_cloud_run_v2_service.api.location
  service  = google_cloud_run_v2_service.api.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Domain mapping (optional - only if domain is provided)
resource "google_cloud_run_domain_mapping" "api" {
  count    = var.api_domain != "" ? 1 : 0
  location = google_cloud_run_v2_service.api.location
  name     = var.api_domain

  spec {
    route_name = google_cloud_run_v2_service.api.name
  }

  metadata {
    namespace = var.project_id
  }
}

# Outputs
output "api_url" {
  description = "The URL of the deployed API"
  value       = google_cloud_run_v2_service.api.uri
}

output "custom_domain" {
  description = "The custom domain (if configured)"
  value       = var.api_domain != "" ? "https://${var.api_domain}" : "Not configured"
}