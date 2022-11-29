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
  mqtt_cloud_pub_sub_connector_cluster_name = "gke-mqtt-cloud-pub-sub-1"
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-private-cluster"
  version = "24.0.0"

  datapath_provider               = "ADVANCED_DATAPATH"
  deploy_using_private_endpoint   = true
  description                     = "GKE Cluster to deploy the MQTT <-> Cloud Pub/Sub connector"
  enable_cost_allocation          = true
  enable_network_egress_export    = true
  enable_private_endpoint         = true
  enable_private_nodes            = true
  enable_vertical_pod_autoscaling = true
  grant_registry_access           = true
  ip_range_pods                   = local.pods_range_name
  ip_range_services               = local.svc_range_name
  master_ipv4_cidr_block          = "172.16.0.0/28"
  name                            = local.mqtt_cloud_pub_sub_connector_cluster_name
  network                         = module.gcp_network.network_name
  project_id                      = data.google_project.default_project.project_id
  region                          = var.google_default_region
  subnetwork                      = local.subnet_names[index(module.gcp_network.subnets_names, local.cluster_subnet_name)]

  master_authorized_networks = [
    {
      cidr_block   = local.master_authorized_network_ipv4_cidr
      display_name = "VPC"
    },
  ]

  depends_on = [
    module.project-services
  ]
}
