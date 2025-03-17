# main.tf
# Google provider (using only ltc-hack-prj-24 project)
provider "google" {
  project = "ltc-hack-prj-24"
  region  = "us-central1"
}

resource "google_container_cluster" "primary" {
  provider           = google
  name               = "gke-cluster"
  location           = "us-central1-a"  # Change this to your preferred zone
  initial_node_count = 1  # Start with 1 node

  node_config {
    machine_type = "e2-medium"
  }

  autoscaling {
    min_node_count = 1  # Minimum number of nodes
    max_node_count = 5  # Maximum number of nodes
  }

  network_policy {
    enabled = true
  }
}

resource "google_container_cluster" "gke" {
  provider           = google
  name               = "gke-cluster"
  location           = "us-central1"
  initial_node_count = 2
  node_config {
    machine_type = "e2-medium"
  }
}

provider "kubernetes" {
  host                   = google_container_cluster.gke.endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.gke.master_auth.0.cluster_ca_certificate)
}

data "google_client_config" "default" {}
