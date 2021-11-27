data "google_compute_zones" "available" {
  status = "UP"
}

module "glusterfs" {
  source = "./modules/gcp_vm_instance"
  count = var.vm_count
  name = "${var.vm_name}-n${count.index + 1}"
  machine_type = var.machine_type
  boot_disk_size = var.boot_disk_size
  region = var.region
  zone = data.google_compute_zones.available.names[count.index % length(data.google_compute_zones.available.names)]
}


resource "google_compute_disk" "data" {
  count = var.vm_count
  name  = "${var.vm_name}-data-n${count.index + 1}"
  type  = "pd-ssd"
  zone  = data.google_compute_zones.available.names[count.index % length(data.google_compute_zones.available.names)]
  size  = var.ssd_disk_size
}

resource "google_compute_attached_disk" "attach_ssd" {
  count = var.vm_count
  disk = google_compute_disk.data[count.index].self_link
  instance = module.glusterfs[count.index].self_link
}

resource "null_resource" "inventory" {
  depends_on = [google_compute_attached_disk.attach_ssd]

  provisioner "local-exec" {
    command = "echo [glusterfs] > ../Ansible/inventory/${var.vm_name}.ini"
  }

  count = var.vm_count
  provisioner "local-exec" {
    command = "echo ${module.glusterfs[count.index].vm_ip} >> ../Ansible/inventory/${var.vm_name}.ini"
  }

  provisioner "local-exec" {
    command = "sleep 90"
  }
}

resource "null_resource" "run_ansible-playbook" {
  depends_on = [null_resource.inventory]

  provisioner "local-exec" {
    command = "cd ../Ansible && ansible-playbook -i inventory/${var.vm_name}.ini -e \"ansible_ssh_user=${var.ansible_ssh_user}\" glusterfs_setup.yml"
  }
}

output "ipaddr" {
  value = module.glusterfs[*].vm_ip
}

output "vm_self_link" {
  value = module.glusterfs[*].self_link
}
