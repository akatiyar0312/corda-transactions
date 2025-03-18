resource "google_container_cluster" "primary" {
  provider           = google
  name               = "gke-cluster"
  location           = "us-central1-a"
  initial_node_count = 6  # Initial node count for the cluster

  node_config {
    machine_type = "e2-medium"
  }

  network_policy {
    enabled = true
  }
}

resource "google_container_node_pool" "primary_node_pool" {
  name       = "primary-node-pool"
  cluster    = google_container_cluster.primary.name
  location   = google_container_cluster.primary.location
  node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 3
    cpu_utilization {
      target = 0.75  # Correct usage of the CPU target utilization
    }
  }

  node_config {
    machine_type = "e2-medium"  # Specify the machine type here
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}
