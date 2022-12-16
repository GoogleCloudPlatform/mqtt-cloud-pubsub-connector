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

output "artifact_registry_container_image_repository_location" {
  description = "Location of the Artifact Registry repository to store container images."
  value       = google_artifact_registry_repository.mqtt_cloud_pubsub_container_image_repository.location
}

output "artifact_registry_container_image_repository_name" {
  description = "Last part of the name of the Artifact Registry container image repository."
  value       = google_artifact_registry_repository.mqtt_cloud_pubsub_container_image_repository.repository_id
}

output "artifact_registry_container_image_repository_project_id" {
  description = "ID of the Artifact Registry container image repository Google Cloud project."
  value       = google_artifact_registry_repository.mqtt_cloud_pubsub_container_image_repository.project
}

output "bastion_host_hostname" {
  description = "Hostname of the bastion host."
  value       = module.iap_bastion.hostname
}

output "bastion_host_project_id" {
  description = "ID of the bastion host Google Cloud project"
  value       = data.google_project.default_project.project_id
}

output "bastion_host_zone" {
  description = "Zone of the bastion host."
  value       = var.google_default_zone
}

output "cloud_pubsub_destination_project_id" {
  description = "ID of the Cloud Pub/Sub Google Cloud project."
  value       = data.google_project.default_project.project_id
}

output "cloud_pubsub_destination_topic_name" {
  description = "Name of the Cloud Pub/Sub topic where to store messages from the MQTT broker."
  value       = module.pubsub.topic
}

output "mqtt_cloud_pub_sub_connector_cluster_name" {
  description = "Name of the GKE cluster to deploy the MQTT <-> Cloud Pub/Sub connector."
  value       = module.gke.name
}

output "mqtt_cloud_pub_sub_connector_cluster_project_id" {
  description = "ID of the project of the GKE cluster to deploy the MQTT <-> Cloud Pub/Sub connector."
  value       = data.google_project.default_project.project_id
}

output "mqtt_cloud_pub_sub_connector_cluster_region" {
  description = "Region of the GKE cluster to deploy the MQTT <-> Cloud Pub/Sub connector."
  value       = module.gke.region
}

output "mqtt_cloud_pub_sub_connector_service_account_email" {
  description = "Email address of MQTT <-> Cloud Pub/Sub Connector service account."
  value       = module.mqtt_cloud_pubsub_connector_workload_identity.gcp_service_account_email
}
