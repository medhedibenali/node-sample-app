terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.8.3"
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://medhedi@localhost/system"
}

variable "ssh_key" {
  type = string
  nullable = false
}

resource "libvirt_volume" "tumbleweed" {
  name   = "tumbleweed"
  pool   = "default"
  source = "https://download.opensuse.org/tumbleweed/appliances/openSUSE-Tumbleweed-Minimal-VM.x86_64-Cloud.qcow2"
  format = "qcow2"
}

resource "libvirt_volume" "vm" {
  name           = "vm"
  base_volume_id = libvirt_volume.tumbleweed.id
  pool           = "default"
  size           = 10737418240
}

locals {
  network_config = yamlencode({
    network = {
      version = 1
      config = [{
        type = "physical"
        name = "eth0"
        subnets = [{
          type = "dhcp"
        }]
      }]
    }
  })

  user_data = yamlencode({
    users = [{
      name = "ansible"
      gecos = "Ansible User"
      groups = "users,admin,wheel"
      sudo = "ALL=(ALL) NOPASSWD:ALL"
      shell = "/bin/bash"
      lock_passwd = true
      ssh_authorized_keys = [var.ssh_key]
    }]
    ssh_pwauth = false
    chpasswd = {
      expire = false
    }
    growpart = {
      mode = "auto"
      devices = ["/"]
    }
    runcmd = [
      <<EOT
      if grep 'UsePAM' /etc/ssh/sshd_config; then
        sed -i '/UsePAM/s/.*/UsePAM yes/' /etc/ssh/sshd_config;
      else
        echo 'UsePAM yes' >> /etc/ssh/sshd_config;
      fi
      EOT
      ,
      "systemctl restart sshd",
    ]
  })
}

resource "libvirt_cloudinit_disk" "init" {
  name           = "init.iso"
  user_data      = format("#cloud-config\n%s", local.user_data)
  network_config = local.network_config
}

resource "libvirt_domain" "vm" {
  name   = "vm"
  memory = "4096"
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.init.id

  network_interface {
    network_name = "default"
    hostname = "vm"
    wait_for_lease = true
  }

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
    volume_id = libvirt_volume.vm.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

output "vm_ip" {
  value = libvirt_domain.vm.network_interface.0.addresses.0
}
