provider "google" {
  project     = "ltc-hack-prj-24"
  region      = "us-central1"
  credentials = file("/home/user93_lloyds/ltc-hack-prj-24-dffbb9e14fee.json")
}

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

# Kubernetes provider configuration (use the correct GKE cluster)
provider "kubernetes" {
  host                   = google_container_cluster.primary.endpoint
  token                  = google_container_cluster.primary.master_auth[0].access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

# Get the access token dynamically from the cluster
data "google_client_config" "default" {}
