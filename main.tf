# We add a project that will serve as a Service Project
resource "google_project" "project-b" {
  name            = "myproject-b"
  project_id      = "project-b-5919"
  org_id          = "591930884219"
  billing_account = var.billing_account
}


# We create the SA to authenticate terraform and perform the provisioning of the next resources
resource "google_service_account" "sa-terra" {
  account_id   = "sa-terra"
  display_name = "sa-terra"
  project      = var.project-cohesive
}


# We add a user (user1@gcp.systemasycloud.com) that will be the VPC Manager and hold the Shared VPC Admin and Project IAM Admin roles 
# at the org level with the scope of project `myterra` and `project-B`

resource "google_organization_iam_member" "organization" {
  org_id = var.organization
  for_each = toset([
    "roles/compute.xpnAdmin",
    "roles/resourcemanager.projectIamAdmin"
  ])
  role   = each.key
  member = "user:user1@gcp.systemasycloud.com"
}

resource "google_organization_iam_member" "yan" {
  org_id = var.organization
  for_each = toset([
    "roles/compute.xpnAdmin",
    "roles/resourcemanager.projectIamAdmin"
  ])
  role   = each.key
  member = "user:yan@gcp.systemasycloud.com"
}


#ENABLE COMPUTE ENGINE SERVICE FOR PROJECT B
#This do it manually

# Create VPC Shared Host Proj
resource "google_compute_shared_vpc_host_project" "host" {
  project = var.project-cohesive
}

#Create VPC Shared Service Proj
resource "google_compute_shared_vpc_service_project" "service" {
  host_project = google_compute_shared_vpc_host_project.host.project
  service_project = var.service_project
}

# Create Subnet/Firewalls that will be used by the VPC Shared
resource "google_compute_network" "vpc-network-for-vpc-shared" {
  name = "vpc-net-shared"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet" {
  name = "subnet-for-vpc-shared"
  region = "us-central1"

  network = google_compute_network.vpc-network-for-vpc-shared.id
  ip_cidr_range = "10.0.0.0/16"
}

resource "google_compute_firewall" "vpc-fw" {
  name = "vpc-shared-fw"
  network = google_compute_network.vpc-network-for-vpc-shared.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = [ 22,3389 ]
  }

  source_tags = ["web"]
  source_ranges = [ "35.235.240.0/20" ]
}



# Create two VMs in `project-B` that will use network resources from project `myterra`
/* resource "google_compute_instance" "vm1" {
  name = "vm1-proj-b"
  machine_type = "n2-standard-2"
  zone = "us-central1-a"

  tags = [ "web" ]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label="image-debian"
      }
    }
  }

  network_interface {
    network = google_compute_network.vpc-network-for-vpc-shared.name
    
    access_config {
      
    }
  }
}

resource "google_compute_instance" "vm2" {
  name = "vm2-proj-b"
  machine_type = "n2-standard-2"
  zone = "us-central1-a"

  tags = [ "web" ]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label="image-debian"
      }
    }
  }

  network_interface {
    network = google_compute_network.vpc-network-for-vpc-shared.name
    
    access_config {
      
    }
  }
} */