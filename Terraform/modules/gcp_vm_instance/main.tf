resource "google_compute_instance" "default" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
      size  = var.boot_disk_size
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = "default"
    subnetwork = "default"
  }

  metadata = {
    foo = "bar"
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}

output "vm_ip" {
  value = google_compute_instance.default.network_interface.0.network_ip
}

output "self_link" {
  value = google_compute_instance.default.self_link
}