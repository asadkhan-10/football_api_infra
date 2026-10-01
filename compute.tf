data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order                = "DESC"
}

resource "oci_core_instance" "web" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id       = var.compartment_ocid
  display_name         = "football-api"
  shape                = "VM.Standard.E2.1.Micro"

  create_vnic_details {
    subnet_id        = oci_core_subnet.main.id
    assign_public_ip = true
    hostname_label   = "football-api"
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu.images[0].id
    boot_volume_size_in_gbs = 50
  }

  metadata = {
    ssh_authorized_keys = file("~/.ssh/oci_football_api.pub")
  }
}