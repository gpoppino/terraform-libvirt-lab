variable libvirt_uri {
  type = string
}

variable libvirt_volume_source {
  type = string
}

variable libvirt_volume_pool {
  type = string
  default = "home"
}

variable libvirt_cloudinit_disk_pool {
  type = string
  default = "ISOs"
}

variable libvirt_network_name {
  type = string
  default = "default"
}

variable instance_memory {
  default = "2048"
}

variable instance_vcpu {
  type = number
  default = 2
}

variable instance_name {
  type = string
}

variable ssh_public_key {
  type        = string
  description = "Location of SSH public key."
}

variable number_of_instances {
  type = number
  default = 1
}

variable network_address {
  type = string
}

variable domain {
  type = string
}
