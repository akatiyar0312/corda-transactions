# PostgreSQL Deployment
resource "kubernetes_deployment" "postgresql" {
  metadata {
    name = "postgresql"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgresql"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgresql"
        }
      }

      spec {
        container {
          name  = "postgresql"
          image = "postgres:14.10"

          env {
            name  = "POSTGRES_USER"
            value = "postgres"
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value = "password"
          }

          env {
            name  = "POSTGRES_DB"
            value = "cordacluster"
          }

          port {
            container_port = 5432
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgresql" {
  metadata {
    name = "postgresql"
  }

  spec {
    selector = {
      app = "postgresql"
    }

    port {
      port        = 5432
      target_port = 5432
    }

    type = "ClusterIP"
  }
}

# Kafka Deployment
resource "kubernetes_deployment" "kafka" {
  metadata {
    name = "kafka"
  }

  spec {
    replicas = 1

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

          env {
            name  = "KAFKA_NODE_ID"
            value = "1"
          }

          env {
            name  = "CLUSTER_ID"
            value = "ZDFiZmU3ODUyMzRiNGI3NG"
          }

          env {
            name  = "KAFKA_LISTENERS"
            value = "PLAINTEXT://0.0.0.0:9092,DOCKER_INTERNAL://0.0.0.0:29092,CONTROLLER://0.0.0.0:9093"
          }

          port {
            container_port = 9092
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "kafka" {
  metadata {
    name = "kafka"
  }

  spec {
    selector = {
      app = "kafka"
    }

    port {
      port        = 9092
      target_port = 9092
    }

    type = "ClusterIP"
  }
}

# Corda Deployment
resource "kubernetes_deployment" "corda" {
  metadata {
    name = "corda"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "corda"
      }
    }

    template {
      metadata {
        labels = {
          app = "corda"
        }
      }

      spec {
        container {
          name  = "corda"
          image = "corda/corda-os-combined-worker-kafka:5.2.0.0"

          env {
            name  = "JAVA_TOOL_OPTIONS"
            value = "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005"
          }

          env {
            name  = "LOG4J_CONFIG_FILE"
            value = "config/log4j2.xml"
          }

          port {
            container_port = 8888
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "corda" {
  metadata {
    name = "corda"
  }

  spec {
    selector = {
      app = "corda"
    }

    port {
      port        = 8888
      target_port = 8888
    }

    type = "LoadBalancer"
  }
}

# Flow Management Tool Deployment
resource "kubernetes_deployment" "flow_management_tool" {
  metadata {
    name = "flow-management-tool"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "flow-management-tool"
      }
    }

    template {
      metadata {
        labels = {
          app = "flow-management-tool"
        }
      }

      spec {
        container {
          name  = "flow-management-tool"
          image = "gcr.io/${var.project_id}/flow-management-tool:latest"

          port {
            container_port = 5000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "flow_management_tool" {
  metadata {
    name = "flow-management-tool"
  }

  spec {
    selector = {
      app = "flow-management-tool"
    }

    port {
      port        = 5000
      target_port = 5000
    }

    type = "LoadBalancer"
  }
}
