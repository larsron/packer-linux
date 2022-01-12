/*
    DESCRIPTION:
    Rocky Linux 8 variables used by Packer.
*/

// Guest Operating System Metadata
vm_guest_os_language = "en_US"
vm_guest_os_keyboard = "us"
vm_guest_os_timezone = "UTC"
vm_guest_os_name     = "rockylinux"
vm_guest_os_version  = "8"

// Virtual Machine Hardware Settings
vm_cpus                  = 1
vm_mem_size              = 2048
vm_disk_size             = 20480

// Parallels Settings
prl_guest_os_type     = "centos"

// Media Settings
iso_url       = "https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-8.5-x86_64-boot.iso"
iso_checksum  = "5a0dc65d1308e47b51a49e23f1030b5ee0f0ece3702483a8a6554382e893333c"

// Boot Settings
vm_boot_wait  = "2s"

// Communicator Settings
communicator_timeout = "30m"

// Provisioner Settings
scripts = ["scripts/init_redhat.sh"]
inline  = []