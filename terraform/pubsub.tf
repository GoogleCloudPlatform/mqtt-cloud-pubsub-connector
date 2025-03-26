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

module "pubsub" {
  source  = "terraform-google-modules/pubsub/google"
  version = "6.0.0"

  topic      = var.cloud_pubsub_destination_topic_name
  project_id = data.google_project.default_project.project_id
  pull_subscriptions = [
    {
      enable_exactly_once_delivery = true
      enable_message_ordering      = true
      maximum_backoff              = "600s"
      minimum_backoff              = "300s"
      name                         = "mqtt-pull"
    }
  ]

  depends_on = [
    module.project-services
  ]
}
