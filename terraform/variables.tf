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

variable "cloud_pubsub_destination_topic_name" {
  description = "The Cloud Pub/Sub topic where to save messages from MQTT"
  default     = "destination-topic"
  type        = string
}

variable "google_default_project_id" {
  description = "The default Google Cloud project ID"
  type        = string
}

variable "google_default_region" {
  default     = "europe-west6"
  description = "The default Google Cloud region."
  type        = string
}

variable "google_default_zone" {
  default     = "europe-west6-b"
  description = "The default Google Cloud zone."
  type        = string
}

variable "google_artifact_registry_location" {
  default     = "europe"
  description = "The default location where to create Artifact Registry repositories."
  type        = string
}
