terraform {
    required_providers {
        libvirt = {
            source  = "dmacvicar/libvirt"
            version = "0.7.6"
        }
    }
}

provider "libvirt" {
    uri = var.libvirt_uri
}

data "template_file" "user_data" {
  count = var.number_of_instances
  template = file("${path.module}/templates/cloud_init.cfg")
  vars = {
    ssh_public_key = file(var.ssh_public_key)
    hostname = "${var.instance_name}-${terraform.workspace}-${count.index}"
  }
}

data "template_file" "network_config" {
  count = var.number_of_instances
  template = file("${path.module}/templates/network_config.cfg")
  vars = {
    ip_address = cidrhost(var.network_address, count.index + 2)
    netmask = cidrnetmask(var.network_address)
    gateway = cidrhost(var.network_address, 1)
  }
}

# for more info about paramater check this out
# https://github.com/dmacvicar/terraform-provider-libvirt/blob/master/website/docs/r/cloudinit.html.markdown
# Use CloudInit to add our ssh-key to the instance
# you can add also meta_data field
resource "libvirt_cloudinit_disk" "commoninit" {
  count          = var.number_of_instances
  name           = "${var.instance_name}-${terraform.workspace}-${count.index}.iso"
  pool           = var.libvirt_cloudinit_disk_pool
  user_data      = data.template_file.user_data[count.index].rendered
  network_config = data.template_file.network_config[count.index].rendered
}

resource "libvirt_volume" "instance_volume" {
  count  = var.number_of_instances
  name   = "${var.instance_name}-${terraform.workspace}-${count.index}.qcow2"
  pool   = var.libvirt_volume_pool
  source = var.libvirt_volume_source
  format = "qcow2"
}

# Create the machine
resource "libvirt_domain" "instance_domain" {
  count  = var.number_of_instances
  name   = "${var.instance_name}-${terraform.workspace}-${count.index}"
  memory = var.instance_memory
  vcpu   = var.instance_vcpu

  cloudinit = libvirt_cloudinit_disk.commoninit.*.id[count.index]

  network_interface {
    network_id = libvirt_network.network.id
    wait_for_lease = true
  }

  # IMPORTANT: this is a known bug on cloud images, since they expect a console
  # we need to pass it
  # https://bugs.launchpad.net/cloud-images/+bug/1573095
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.instance_volume.*.id[count.index]
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

data "libvirt_network_dns_host_template" "hosts" {
  count = var.number_of_instances
  hostname = data.template_file.user_data[count.index].vars.hostname
  ip = libvirt_domain.instance_domain[count.index].network_interface.0.addresses[0]
}

resource "libvirt_network" "network" {
  name = "${var.instance_name}-${terraform.workspace}-network"
  mode = var.network_mode
  domain = var.domain
  dhcp {  enabled = true }
  addresses = [ var.network_address ]
  autostart = true
  dns {
    enabled = true
    local_only = false
  }
}

output "disk_id" {
  value = libvirt_volume.instance_volume.*.id
}

output "network_id" {
  value = libvirt_network.network.id
}

output "hosts" {
  value = data.libvirt_network_dns_host_template.hosts.*.rendered
}

output "ipv4" {
  value = libvirt_domain.instance_domain.*.network_interface.0.addresses
}
