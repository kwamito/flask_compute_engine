resource "google_compute_network" "vpc_network" {
  project = var.project_id
  name                    = "custom-mode-network"
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "subnet1" {
  project = var.project_id
  name          = "my-custom-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-west1"
  network       = google_compute_network.vpc_network.id
}

# Create a single Compute Engine instance
resource "google_compute_instance" "default" {
  project = var.project_id
  name         = "flask-vm"
  machine_type = "f1-micro"
  zone         = "us-west1-a"
  tags         = ["ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  # Install Flask
  metadata_startup_script = "sudo apt-get update; sudo apt install git; sudo apt-get install -yq build-essential python3-pip rsync; git clone https://github.com/kwamito/flask_compute_engine.git; cd flask_compute_engine; pip install -r requirements.txt; python3 app.py"

  network_interface {
    subnetwork = google_compute_subnetwork.subnet1.id

    access_config {
      # Include this section to give the VM an external IP address
    }
  }
}