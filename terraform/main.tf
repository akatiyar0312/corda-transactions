# Google provider (using only ltc-hack-prj-24 project)
provider "google" {
  project     = "ltc-hack-prj-24"
  region      = "us-central1"
  credentials = file("/home/user93_lloyds/ltc-hack-prj-24-dffbb9e14fee.json")
}

# Create the GKE Cluster (primary cluster)
resource "google_container_cluster" "primary" {
  provider           = google
  name               = "gke-cluster"
  location           = "us-central1-a"  # Change this to your preferred zone
  initial_node_count = 1  # Start with 1 node

  node_config {
    machine_type = "e2-medium"
  }

  network_policy {
    enabled = true
  }
}

# Create a node pool for the primary GKE cluster
resource "google_container_node_pool" "primary_pool" {
  provider           = google
  cluster            = google_container_cluster.primary.name
  location           = google_container_cluster.primary.location
  name               = "primary-node-pool"
  initial_node_count = 1

  autoscaling {
    min_node_count = 1  # Minimum number of nodes
    max_node_count = 5  # Maximum number of nodes
  }

  node_config {
    machine_type = "e2-medium"
  }
}

# Kubernetes provider configuration (using the primary cluster)
provider "kubernetes" {
  host                   = google_container_cluster.primary.endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
}

data "google_client_config" "default" {}
