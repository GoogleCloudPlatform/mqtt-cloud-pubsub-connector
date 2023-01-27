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

# We need a bastion host to connect to the private GKE cluster

# https://registry.terraform.io/modules/terraform-google-modules/bastion-host/google/latest
module "iap_bastion" {
  source  = "terraform-google-modules/bastion-host/google"
  version = "5.1.1"

  disk_type      = "pd-ssd"
  network        = module.gcp_network.network_name
  project        = data.google_project.default_project.project_id
  startup_script = file("files/init-scripts/bastion-vm-startup-script.sh")
  subnet         = module.gcp_network.subnets_self_links[index(module.gcp_network.subnets_names, local.master_auth_subnetwork)]
  zone           = var.google_default_zone

  # https://cloud.google.com/kubernetes-engine/docs/how-to/iam#predefined
  service_account_roles_supplemental = [
    "roles/container.clusterViewer",
    "roles/container.developer"
  ]

  depends_on = [
    module.project-services
  ]
}
