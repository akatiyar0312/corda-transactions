provider "google" {
  project = "ltc-hack-prj-24"
  region  = "us-central1"  # You can change this to your preferred region
}

resource "google_container_cluster" "primary" {
  name               = "gke-cluster"
  location           = "us-central1-a"  # Change this to your preferred zone
  initial_node_count = 1  # Start with 1 node

  node_config {
    machine_type = "e2-medium"  # You can customize the machine type based on your requirements
  }

  # Autoscaler settings
  autoscaling {
    min_node_count = 1  # Minimum number of nodes
    max_node_count = 5  # Maximum number of nodes
  }

  # Enable network policy if needed
  network_policy {
    enabled = true
  }
}

output "cluster_name" {
  value = google_container_cluster.primary.name
}
