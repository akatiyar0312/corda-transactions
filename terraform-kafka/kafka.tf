resource "kubernetes_namespace" "kafka" {
  metadata {
    name = "kafka"
  }
}

# Create PersistentVolumeClaims (PVC) for Kafka brokers
resource "kubernetes_persistent_volume_claim" "kafka_pvc" {
  count        = 3
  metadata {
    name      = "kafka-pvc-${count.index}"
    namespace = kubernetes_namespace.kafka.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }

    volume_mode = "Filesystem"
  }
}

# Create StatefulSet for Kafka
resource "kubernetes_stateful_set" "kafka" {
  metadata {
    name      = "kafka"
    namespace = kubernetes_namespace.kafka.metadata[0].name
  }

  spec {
    service_name = "kafka"
    replicas     = 3
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
          image = "confluentinc/cp-kafka:7.6.0"
          ports {
            container_port = 9093
          }

          env {
            name  = "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP"
            value = "PLAINTEXT:PLAINTEXT,DOCKER_INTERNAL:PLAINTEXT"
          }

          env {
            name  = "KAFKA_LISTENER_NAMES"
            value = "PLAINTEXT,DOCKER_INTERNAL"
          }

          env {
            name  = "KAFKA_LISTENERS"
            value = "PLAINTEXT://0.0.0.0:9092,DOCKER_INTERNAL://0.0.0.0:29092"
          }

          env {
            name  = "KAFKA_ADVERTISED_LISTENERS"
            value = "PLAINTEXT://localhost:9092,DOCKER_INTERNAL://kafka:29092"
          }

          env {
            name  = "KAFKA_ZOOKEEPER_CONNECT"
            value = "zookeeper:2181"
          }

          volume_mount {
            mount_path = "/var/lib/kafka/data"
            name       = "kafka-data"
          }
        }

        volume {
          name = "kafka-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.kafka_pvc[count.index].metadata[0].name
          }
        }
      }
    }
  }
}

# Create Service for Kafka
resource "kubernetes_service" "kafka" {
  metadata {
    name      = "kafka"
    namespace = kubernetes_namespace.kafka.metadata[0].name
  }

  spec {
    selector = {
      app = "kafka"
    }
    port {
      port        = 9092
      target_port = 9092
    }
    cluster_ip = "None"  # Required for StatefulSets
  }
}
