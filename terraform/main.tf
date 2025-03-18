resource "google_container_cluster" "primary" {
  provider           = google
  name               = "gke-cluster"
  location           = "us-central1-a"
  initial_node_count = 6  # Increase initial node count to 4

  node_config {
    machine_type = "e2-medium"
  }

  network_policy {
    enabled = true
  }
}

resource "google_container_node_pool" "primary_node_pool" {
  name       = "primary-node-pool"
  cluster    = google_container_cluster.primary_cluster.name
  location   = google_container_cluster.primary_cluster.location
  node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 3
    target_cpu_utilization = 0.75  # Target average CPU utilization for scaling
  }

  node_config {
    machine_type = "e2-medium"  # Specify the machine type here
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }


}
