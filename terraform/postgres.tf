# Define Kubernetes resources for PostgreSQL

resource "kubernetes_config_map" "postgres_config" {
  depends_on = [google_container_cluster.primary, google_container_node_pool.primary_pool]

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
  depends_on = [google_container_cluster.primary, google_container_node_pool.primary_pool]

  metadata {
    name = "postgres-pvc"
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

resource "kubernetes_stateful_set" "postgres" {
  depends_on = [google_container_cluster.primary, google_container_node_pool.primary_pool]

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
              cpu    = "500m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "1000m"
              memory = "1Gi"
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
  depends_on = [google_container_cluster.primary, google_container_node_pool.primary_pool]

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
  depends_on = [google_container_cluster.primary, google_container_node_pool.primary_pool]

  metadata {
    name = "postgres-hpa"
  }
  spec {
    scale_target_ref {
      kind        = "StatefulSet"
      name        = kubernetes_stateful_set.postgres.metadata[0].name
      api_version = "apps/v1"
    }
    min_replicas = 1
    max_replicas = 3
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
