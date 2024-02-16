# Cloud storage bucket for terraform backend
resource "google_storage_bucket" "terra-bucket" {
  project       = var.project_id
  name          = var.bucket_name
  location      = "US-WEST1"
  force_destroy = true

  uniform_bucket_level_access = true
}

# Firewall to allow access to the flask application
resource "google_compute_firewall" "flask" {
  project = var.project_id
  name    = "flask-app-firewall"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Firewall to allow SSH to compute engine instance
resource "google_compute_firewall" "ssh" {
  project = var.project_id
  name    = "allow-ssh"
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.vpc_network.id
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}


# VPC Network for compute engine instance
resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = "custom-mode-network"
  auto_create_subnetworks = false
  mtu                     = 1460
}

# Subnet
resource "google_compute_subnetwork" "subnet1" {
  project       = var.project_id
  name          = "my-custom-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-west1"
  network       = google_compute_network.vpc_network.id
}

# Compute Engine Intance
resource "google_compute_instance" "default" {
  project      = var.project_id
  name         = "flask-vm"
  machine_type = "f1-micro"
  zone         = "us-west1-a"
  tags         = ["ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  # Clone Repo and Install packages
  metadata_startup_script = "sudo apt-get update; sudo apt-get install -yq build-essential python3-pip git rsync; git clone https://github.com/kwamito/flask_compute_engine.git; cd flask_compute_engine; pip install -r requirements.txt; python3 app.py"

  network_interface {
    subnetwork = google_compute_subnetwork.subnet1.id

    access_config {
      # Include this section to give the VM an external IP address
    }
  }
}

terraform {
  backend "gcs" {
    bucket = "terra-bucket101"
    prefix = "terraform/state"
  }
}


// A variable for extracting the external IP address of the VM
output "Web-server-URL" {
  value = join("", ["http://", google_compute_instance.default.network_interface.0.access_config.0.nat_ip, ":5000"])
}
