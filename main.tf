#Create a project that will serve as a Service Project
resource "google_project" "project-b" {
  name            = "zzsa-project-b"
  project_id      = var.service_project
  org_id          = "591930884219"
  billing_account = var.billing_account
}

data "google_project" "proj_b_numbr" {
  project_id = google_project.project-b.project_id
}

#Enable Compute Engine Service in Project B
resource "google_project_service" "compute_engine_service" {
  project = google_project.project-b.project_id
  service = "compute.googleapis.com"
}

# Add user (user1@gcp.systemasycloud.com) that will be the VPC Manager and hold the Shared VPC Admin and Project IAM Admin roles 
# at the org level
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

#Adding proper roles to deploy VMs in Project B
resource "google_project_iam_member" "yan-project-b-iam" {
  project = var.service_project
  role    = "roles/compute.admin"
  member  = "user:yan@gcp.systemasycloud.com"
}

resource "google_project_iam_member" "user1-project-b-iam" {
  project = var.service_project
  role    = "roles/compute.admin"
  member  = "user:user1@gcp.systemasycloud.com"
}

# Create Shared VPC Host Project
resource "google_compute_shared_vpc_host_project" "host" {
  project = var.host_project

  depends_on = [ google_organization_iam_member.yan ]
}

#Create Shared VPC Service Project
resource "google_compute_shared_vpc_service_project" "service" {
  host_project    = google_compute_shared_vpc_host_project.host.project
  service_project = google_project.project-b.project_id

  lifecycle {
    prevent_destroy = false # Allow Terraform to destroy this resource
  }
}

# Create Subnet/Firewalls that will be used by the Shared VPC
resource "google_compute_network" "vpc-network-for-vpc-shared" {
  name                    = "vpc-net-shared"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  project       = var.host_project
  name          = "subnet-for-vpc-shared"
  region        = var.region
  network       = google_compute_network.vpc-network-for-vpc-shared.id
  ip_cidr_range = "10.0.0.0/16"
}

#Configure the Service Project access to selected subnets from the VPC Host project
resource "google_compute_subnetwork_iam_member" "subnet_iam_service_project" {
  project    = google_compute_subnetwork.subnet.project
  region     = google_compute_subnetwork.subnet.region
  subnetwork = google_compute_subnetwork.subnet.name
  role       = "roles/compute.networkUser"
  //member     = "serviceAccount:service-${data.google_project.proj_b_numbr.project_id}@compute-system.iam.gserviceaccount.com"
  member     = "user:yan@gcp.systemasycloud.com"
  depends_on = [google_compute_shared_vpc_service_project.service]
}

resource "google_compute_firewall" "vpc-fw" {
  name    = "vpc-shared-fw"
  network = google_compute_network.vpc-network-for-vpc-shared.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = [22, 3389]
  }

  source_tags   = ["web"]
  source_ranges = ["35.235.240.0/20"]
}

# Create two VMs in `project-B` that will use network resources from project `myterra`
resource "google_compute_instance" "vm1" {
  project      = google_project.project-b.project_id
  name         = "vm1-proj-b"
  machine_type = "n2-standard-2"
  zone         = "us-central1-a"

  tags = ["web"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "image-debian"
      }
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.self_link
    access_config {
      //external ip
    }
  }
  depends_on = [google_compute_shared_vpc_service_project.service]
}

resource "google_compute_instance" "vm2" {
  project      = google_project.project-b.project_id
  name         = "vm2-proj-b"
  machine_type = "n2-standard-2"
  zone         = "us-central1-a"

  tags = ["web"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "image-debian"
      }
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.self_link

    access_config {
      //external ip
    }
  }
  depends_on = [google_compute_shared_vpc_service_project.service]
}
