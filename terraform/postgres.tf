provider "google" {
  project = "trade-finance-453908"
  region  = "us-central1"
}

data "google_client_config" "default" {}

resource "google_container_cluster" "gke" {
  name     = "gke-cluster"
  location = "us-central1"
  initial_node_count = 1  # Reduced node count to 1
  node_config {
    machine_type = "e2-micro"  # Reduced to e2-micro for minimal resource usage
    disk_size_gb = 10  # Reduced disk size
  }
}

provider "kubernetes" {
  host                   = google_container_cluster.gke.endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.gke.master_auth.0.cluster_ca_certificate)
}

resource "kubernetes_config_map" "postgres_config" {
  metadata {
    name = "postgres-config"
  }
  data = {
    POSTGRES_DB       = "corda_db"
    POSTGRES_USER     = "corda_user"
    POSTGRES_PASSWORD = "corda_password"
  }
}

resource "kubernetes_persistent_volume_claim" "postgres_pvc" {
  metadata {
    name = "postgres-pvc"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}

resource "kubernetes_stateful_set" "postgres" {
  metadata {
    name = "postgres"
  }
  spec {
    service_name = "postgres"
    replicas     = 1
    selector {
      match_labels = {
        app = "postgres"
      }
    }
    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }
      spec {
        container {
          name  = "postgres"
          image = "postgres:15"
          port {
            container_port = 5432
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.postgres_config.metadata[0].name
            }
          }
          volume_mount {
            mount_path = "/var/lib/postgresql/data"
            name       = "postgres-storage"
            sub_path   = "postgres"
          }
          resources {
            requests = {
              cpu    = "100m"  # Reduced CPU request to 100m
              memory = "128Mi"  # Reduced memory request to 128Mi
            }
            limits = {
              cpu    = "250m"  # Reduced CPU limit to 250m
              memory = "256Mi"  # Reduced memory limit to 256Mi
            }
          }
        }
        volume {
          name = "postgres-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name = "postgres"
  }
  spec {
    selector = {
      app = "postgres"
    }
    port {
      port        = 5432
      target_port = 5432
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "postgres_hpa" {
  metadata {
    name = "postgres-hpa"
  }
  spec {
    scale_target_ref {
      kind       = "StatefulSet"
      name       = kubernetes_stateful_set.postgres.metadata[0].name
      api_version = "apps/v1"
    }
    min_replicas = 1
    max_replicas = 2
    metric {
      type = "Resource"
      resource {
        name  = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }
    metric {
      type = "Resource"
      resource {
        name  = "memory"
        target {
          type                = "Utilization"
          average_utilization = 75
        }
      }
    }
  }
}
