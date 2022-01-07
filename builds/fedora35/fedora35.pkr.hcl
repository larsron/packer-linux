/*
    DESCRIPTION:
    Fedora 35 template using the Packer Builder.
*/

//  BLOCK: packer
//  The Packer configuration.

packer {
  required_version = ">= 1.7.4"
  required_plugins {
    parallels = {
      version = ">= v1.0.0"
      source  = "github.com/hashicorp/parallels"
    }
    qemu = {
      version = ">= v1.0.1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "VAGRANT_BOX_PATH" {
  type = string
}

//  BLOCK: locals
//  Defines the local variables.

locals {
  buildtime     = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  manifest_date = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
  manifest_path = "${path.cwd}/manifests/"
  data_source_content = {
    "/ks.cfg" = templatefile("${abspath(path.root)}/data/ks.pkrtpl.hcl", {
      build_username           = var.build_username
      build_password_encrypted = var.build_password_encrypted
      vm_guest_os_language     = var.vm_guest_os_language
      vm_guest_os_keyboard     = var.vm_guest_os_keyboard
      vm_guest_os_timezone     = var.vm_guest_os_timezone
    })
  }
  data_source_command = var.common_data_source == "http" ? "inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg" : "inst.ks=cdrom:/ks.cfg"
}

//  BLOCK: source
//  Defines the builder configuration blocks.

source "parallels-iso" "fedora35" {
  // Virtual Machine Settings
  guest_os_type        = var.vm_guest_os_type
  vm_name              = "${var.vm_guest_os_name}-${var.vm_guest_os_version}"
  cpus                 = var.vm_cpus
  memory               = var.vm_mem_size
  disk_size            = var.vm_disk_size
  skip_compaction      = var.prl_skip_compaction
  parallels_tools_mode = var.prl_parallels_tools_mode

  // Media Settings
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum
  http_content = var.common_data_source == "http" ? local.data_source_content : null

  // Boot and Provisioning Settings
  http_port_min = var.common_data_source == "http" ? var.common_http_port_min : null
  http_port_max = var.common_data_source == "http" ? var.common_http_port_max : null
  boot_wait     = var.vm_boot_wait
  boot_command = [
    "<up><wait><tab> inst.text ",
    "${local.data_source_command}",
    "<enter>"
  ]
  shutdown_command = "echo '${var.build_password}' | sudo -S -E shutdown -P now"
  shutdown_timeout = var.common_shutdown_timeout

  // Communicator Settings and Credentials
  ssh_username       = var.build_username
  ssh_password       = var.build_password
  ssh_timeout        = var.communicator_timeout
}

source "qemu" "fedora35" {
  // Virtual Machine Settings
  vm_name              = "${var.vm_guest_os_name}-${var.vm_guest_os_version}"
  cpus                 = var.vm_cpus
  memory               = var.vm_mem_size
  disk_size            = var.vm_disk_size
  format               = var.qemu_format
  accelerator          = var.qemu_accelerator
  net_device           = var.qemu_net_device
  disk_interface       = var.qemu_disk_interface

  // Media Settings
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum
  http_content = var.common_data_source == "http" ? local.data_source_content : null

  // Boot and Provisioning Settings
  http_port_min = var.common_data_source == "http" ? var.common_http_port_min : null
  http_port_max = var.common_data_source == "http" ? var.common_http_port_max : null
  boot_wait     = var.vm_boot_wait
  boot_command = [
    "<up><wait><tab> inst.text ",
    "${local.data_source_command}",
    "<enter>"
  ]
  shutdown_command = "echo '${var.build_password}' | sudo -S -E shutdown -P now"
  shutdown_timeout = var.common_shutdown_timeout

  // Communicator Settings and Credentials
  ssh_username         = var.build_username
  ssh_password         = var.build_password
  ssh_timeout          = var.communicator_timeout
}

//  BLOCK: build
//  Defines the builders to run, provisioners, and post-processors.

build {
  sources = [
    "source.parallels-iso.fedora35",
    "source.qemu.fedora35",
  ]

  provisioner "shell" {
    execute_command = "echo '${var.build_password}' | {{.Vars}} sudo -E -S sh -eux '{{.Path}}'"
    environment_vars = [
      "BUILD_USERNAME=${var.build_username}",
      "BUILD_KEY=${var.build_key}"
    ]
    scripts = formatlist("${path.cwd}/%s", var.scripts)
  }

  provisioner "ansible" {
    playbook_file           = "${path.cwd}/ansible/main.yml"
    roles_path              = "${path.cwd}/ansible/roles"
    ansible_env_vars = [
      "ANSIBLE_CONFIG=${path.cwd}/ansible/ansible.cfg"
    ]
  }

  post-processor "vagrant" {
    output = "${var.VAGRANT_BOX_PATH}/${source.name}.box"
  }

  post-processor "shell-local" {
    inline = [
      "vagrant box add --force --name ${source.name} ${var.VAGRANT_BOX_PATH}/${source.name}.box",
      "rm -rf output-${source.name}"
    ]
  }
}