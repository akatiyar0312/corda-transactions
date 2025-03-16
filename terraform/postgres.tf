provider "google" {
  project = "trade-finance-453908"
  region  = "us-central1"
}

data "google_client_config" "default" {}

data "google_container_cluster" "gke" {
  name     = google_container_cluster.gke.name
  location = google_container_cluster.gke.location
}

resource "google_container_cluster" "gke" {
  name     = "gke-cluster"
  location = "us-central1"
  initial_node_count = 1
  node_config {
    machine_type = "e2-micro"
    disk_size_gb = 10
  }
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.gke.master_auth[0].cluster_ca_certificate)
}

resource "kubernetes_namespace" "postgres" {
  metadata {
    name = "postgres"
  }
}

resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.postgres.metadata[0].name
    labels = {
      app = "postgres"
    }
  }
  spec {
    replicas = 1
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
          env {
            name  = "POSTGRES_DB"
            value = "corda_db"
          }
          env {
            name  = "POSTGRES_USER"
            value = "corda_user"
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = "corda_password"
          }
          volume_mount {
            mount_path = "/var/lib/postgresql/data"
            name       = "postgres-storage"
          }
        }
        volume {
          name = "postgres-storage"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.postgres.metadata[0].name
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
