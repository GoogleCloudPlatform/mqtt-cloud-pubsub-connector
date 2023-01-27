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

locals {
  cluster_subnet_name                 = "${local.mqtt_cloud_pub_sub_connector_cluster_name}-private-subnet"
  master_auth_subnetwork              = "${local.mqtt_cloud_pub_sub_connector_cluster_name}-control-plane-subnet"
  master_authorized_network_ipv4_cidr = "10.60.0.0/17"
  network_name                        = "${local.mqtt_cloud_pub_sub_connector_cluster_name}-network"
  pods_range_name                     = "${local.mqtt_cloud_pub_sub_connector_cluster_name}-pods-ip-range"
  subnet_names                        = [for subnet_self_link in module.gcp_network.subnets_self_links : split("/", subnet_self_link)[length(split("/", subnet_self_link)) - 1]]
  svc_range_name                      = "${local.mqtt_cloud_pub_sub_connector_cluster_name}-services-ip-range"
}

# https://registry.terraform.io/modules/terraform-google-modules/network/google/latest
module "gcp_network" {
  source  = "terraform-google-modules/network/google"
  version = "6.0.1"

  project_id   = data.google_project.default_project.project_id
  network_name = local.network_name

  subnets = [
    {
      subnet_name           = local.cluster_subnet_name
      subnet_ip             = "10.0.0.0/17"
      subnet_private_access = "true"
      subnet_region         = var.google_default_region
    },
    {
      subnet_name   = local.master_auth_subnetwork
      subnet_ip     = local.master_authorized_network_ipv4_cidr
      subnet_region = var.google_default_region
    },
  ]

  secondary_ranges = {
    (local.cluster_subnet_name) = [
      {
        range_name    = local.pods_range_name
        ip_cidr_range = "192.168.0.0/18"
      },
      {
        range_name    = local.svc_range_name
        ip_cidr_range = "192.168.64.0/18"
      },
    ]
  }

  depends_on = [
    module.project-services
  ]
}
