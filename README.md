## Overview

This Terraform configuration (`main.tf`) sets up a Google Cloud environment by creating and configuring various resources necessary for a Shared VPC setup. The configuration is designed to establish a service project, enable required services, assign roles, and deploy virtual machines (VMs) that utilize a shared VPC network hosted in another project. This setup is useful for managing and isolating resources across different projects while leveraging shared networking resources.

## Resources Created

### 1. **Service Project Creation**
   - **`google_project.project-b`**: Creates a Google Cloud project (`zzsa-project-b`) that will serve as the service project.

### 2. **Service Enabling**
   - **`google_project_service.compute_engine_service`**: Enables the Compute Engine API for the service project, allowing the creation and management of VMs.

### 3. **IAM Roles Assignment**
   - **`google_organization_iam_member.organization` & `google_organization_iam_member.yan`**: Assigns the roles of Shared VPC Admin (`roles/compute.xpnAdmin`) and Project IAM Admin (`roles/resourcemanager.projectIamAdmin`) to two users at the organization level.
   - **`google_project_iam_member.yan-project-b-iam` & `google_project_iam_member.user1-project-b-iam`**: Grants the Compute Admin role (`roles/compute.admin`) to the users for the service project, enabling them to manage VMs and other compute resources.

### 4. **Shared VPC Setup**
   - **`google_compute_shared_vpc_host_project.host`**: Configures an existing project as the Shared VPC host project.
   - **`google_compute_shared_vpc_service_project.service`**: Links the service project to the Shared VPC host project, allowing it to use the shared network resources.

### 5. **Networking Configuration**
   - **`google_compute_network.vpc-network-for-vpc-shared`**: Creates a custom VPC network to be used as the shared VPC.
   - **`google_compute_subnetwork.subnet`**: Defines a subnet within the shared VPC, specifying the IP range and region.
   - **`google_compute_subnetwork_iam_member.subnet_iam_service_project`**: Grants network access to the service project users, allowing them to use the defined subnet.
   - **`google_compute_firewall.vpc-fw`**: Creates firewall rules to control traffic to and from the resources within the VPC network.

### 6. **Virtual Machines Deployment**
   - **`google_compute_instance.vm1` & `google_compute_instance.vm2`**: Deploys two VMs in the service project (`project-b`) that use the shared VPC network from the host project. The VMs are configured with a Debian 11 image and are tagged for firewall rule association.

## Prerequisites

Before applying this configuration, ensure that:
- You have a valid billing account and organization ID.
- The host project is already created and configured.
- The necessary APIs are enabled in the Google Cloud Console.

## Variables

The configuration relies on several variables, which should be defined in a separate `terraform.tfvars` file or passed directly during Terraform execution:

- `service_project`: The ID of the service project to be created.
- `billing_account`: The billing account ID to associate with the service project.
- `organization`: The organization ID where the roles will be assigned.
- `host_project`: The ID of the project designated as the Shared VPC host.
- `region`: The region where the subnet and VMs will be deployed.

## Usage


1. Initialize Terraform:

   ```bash
   terraform init

2. Review the execution plan:

   ```bash
   terraform plan

3. Apply the configuration:

   ```bash
   terraform apply

## Cleanup

To remove the resources created by this configuration, run: 

   ```bash
   terraform destroy
```
Ensure that you have the appropriate permissions and have considered the impact of destroying these resources, especially in a production environment.
Notes

   - The prevent_destroy lifecycle rule for the google_compute_shared_vpc_service_project resource is set to false, allowing Terraform to manage and potentially destroy this resource if needed.
   -  Ensure that the organization-level roles are assigned carefully, as they grant significant permissions across the organization.

This setup is ideal for organizations looking to manage multiple projects under a common network infrastructure, ensuring centralized control while allowing project-level autonomy.


