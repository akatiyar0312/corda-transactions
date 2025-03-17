provider "google" {
  project     = "ltc-hack-prj-24"  # Replace with your project ID
  region      = "us-central1"      # Replace with your preferred region
  credentials = file("/path/to/your/service-account-key.json")  # Path to your service account key
}

# Create a Cloud SQL PostgreSQL instance
resource "google_sql_database_instance" "postgres_instance" {
  name             = "postgres-instance"
  region           = "us-central1"  # Change to your preferred region
  database_version = "POSTGRES_13"  # PostgreSQL version (can change to another version)

  settings {
    tier = "db-f1-micro"   # Choose your instance tier, db-f1-micro is cost-effective for small workloads

    # Configure IP access
    ip_configuration {
      authorized_networks {
        name  = "MyNetwork"
        value = "0.0.0.0/0"   # This allows any IP to connect, you should restrict this for security
      }

      ipv4_enabled = true
    }

    # Backup settings
    backup_configuration {
      enabled    = true
      start_time = "03:00"   # Define the backup start time
    }

    # Maintenance window configuration
    maintenance_window {
      day          = 0  # Sunday
      hour         = 0  # Midnight UTC
      update_track = "stable"  # Can be "stable" or "canary"
    }
  }

  deletion_protection = false  # Set to true to prevent accidental deletion
}

# Create a PostgreSQL database inside the Cloud SQL instance
resource "google_sql_database" "postgres_db" {
  name     = "corda_db"         # Name of the PostgreSQL database
  instance = google_sql_database_instance.postgres_instance.name  # Reference the created instance
}

# Create a PostgreSQL user for accessing the database
resource "google_sql_user" "postgres_user" {
  name     = "corda_user"       # Database username
  instance = google_sql_database_instance.postgres_instance.name  # Reference the created instance
  password = "corda_password"   # Database password (use a secure password in production)
}

# Optional: Create a schema within the database using local-exec (requires psql command)
resource "null_resource" "postgres_schema" {
  depends_on = [google_sql_database_instance.postgres_instance]

  provisioner "local-exec" {
    command = "psql -h ${google_sql_database_instance.postgres_instance.ip_address[0].ip_address} -U ${google_sql_user.postgres_user.name} -d ${google_sql_database.postgres_db.name} -c 'CREATE SCHEMA my_schema;'"
  }
}
