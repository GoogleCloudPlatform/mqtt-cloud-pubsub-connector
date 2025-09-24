# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# We need a Cloud Router and a Cloud NAT to route external traffic from the bastion host

# https://registry.terraform.io/modules/terraform-google-modules/cloud-router/google
module "cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "7.3.0"

  name    = "master-authorized-network-router"
  network = module.gcp_network.network_name
  project = data.google_project.default_project.project_id
  region  = var.google_default_region

  nats = [{
    name                               = "master-authorized-network-nat"
    source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

    subnetworks = [
      {
        name                    = module.gcp_network.subnets_self_links[index(module.gcp_network.subnets_names, local.master_auth_subnetwork)]
        source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
      }
    ]
  }]

  depends_on = [
    module.project-services
  ]
}
