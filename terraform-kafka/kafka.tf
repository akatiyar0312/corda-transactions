provider "google" {
  project     = "ltc-hack-prj-24"  # Your GCP Project ID
  region      = "us-central1"      # Your preferred region
  credentials = file("/home/user93_lloyds/ltc-hack-prj-24-dffbb9e14fee.json")
}

provider "kubernetes" {
  host                   = google_container_cluster.primary.endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

data "google_client_config" "default" {}

# Define the GKE Cluster
resource "google_container_cluster" "primary" {
  name               = "gke-cluster"
  location           = "us-central1-a"
  initial_node_count = 3

  node_config {
    machine_type = "e2-medium"
  }

  network_policy {
    enabled = true
  }
}

# Define the PersistentVolume for Kafka data storage
resource "kubernetes_persistent_volume" "kafka_pv" {
  metadata {
    name = "kafka-pv"
  }

  spec {
    capacity = {
      storage = "10Gi"
    }

    access_modes = ["ReadWriteOnce"]

    persistent_volume_reclaim_policy = "Retain"

    host_path {
      path = "/mnt/data/kafka"
    }
  }
}

# Define PersistentVolumeClaim for Kafka
resource "kubernetes_persistent_volume_claim" "kafka_pvc" {
  metadata {
    name      = "kafka-pvc"
    namespace = "default"
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

# Kafka StatefulSet Deployment
resource "kubernetes_stateful_set" "kafka" {
  metadata {
    name = "kafka"
  }

  spec {
    service_name = "kafka"

    replicas = 3

    selector {
      match_labels = {
        app = "kafka"
      }
    }

    template {
      metadata {
        labels = {
          app = "kafka"
        }
      }

      spec {
        container {
          name  = "kafka"
          image = "confluentinc/cp-kafka:7.6.0"  # Kafka image
          
          ports {
            container_port = 9092
            name           = "kafka"
          }

          volume_mount {
            name      = "kafka-storage"
            mount_path = "/var/lib/kafka/data"
          }

          environment {
            name  = "KAFKA_ADVERTISED_LISTENERS"
            value = "PLAINTEXT://localhost:9092"
          }

          environment {
            name  = "KAFKA_LISTENERS"
            value = "PLAINTEXT://0.0.0.0:9092"
          }

          environment {
            name  = "KAFKA_LISTENER_SECURITY_PROTOCOL"
            value = "PLAINTEXT"
          }

          environment {
            name  = "KAFKA_ZOOKEEPER_CONNECT"
            value = "zookeeper:2181"  # Assuming you have a Zookeeper service
          }
        }

        volume {
          name = "kafka-storage"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.kafka_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

# Define Kafka Service (Exposing the Kafka broker)
resource "kubernetes_service" "kafka" {
  metadata {
    name = "kafka"
  }

  spec {
    selector = {
      app = "kafka"
    }

    ports {
      port        = 9092
      target_port = 9092
      protocol    = "TCP"
    }

    cluster_ip = "None"  # Headless service for StatefulSet
  }
}

# Zookeeper StatefulSet for Kafka
resource "kubernetes_stateful_set" "zookeeper" {
  metadata {
    name = "zookeeper"
  }

  spec {
    service_name = "zookeeper"
    replicas     = 1
    selector {
      match_labels = {
        app = "zookeeper"
      }
    }

    template {
      metadata {
        labels = {
          app = "zookeeper"
        }
      }

      spec {
        container {
          name  = "zookeeper"
          image = "confluentinc/cp-zookeeper:7.6.0"  # Zookeeper image
          ports {
            container_port = 2181
            name           = "zookeeper"
          }
        }
      }
    }
  }
}

# Define Zookeeper Service (Exposing the Zookeeper)
resource "kubernetes_service" "zookeeper" {
  metadata {
    name = "zookeeper"
  }

  spec {
    selector = {
      app = "zookeeper"
    }

    ports {
      port        = 2181
      target_port = 2181
      protocol    = "TCP"
    }

    cluster_ip = "None"  # Headless service for StatefulSet
  }
}

output "kafka_service_endpoint" {
  value = kubernetes_service.kafka.cluster_ip
}
