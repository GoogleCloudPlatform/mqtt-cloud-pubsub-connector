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

module "project-factory" {
  source  = "terraform-google-modules/project-factory/google"
  version = "15.0.1"

  auto_create_network = false
  billing_account     = var.billing_account_id
  folder_id           = var.folder_id
  name                = var.google_project_id
  org_id              = var.organization_id
  random_project_id   = true

  # Workaround for https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/issues/1488
  # (to remove when the above issue is fixed)
  # We need to keep the default service account because the terraform-google-kubernetes-engine module
  # doesn't yet support setting a non-default service account for GKE Autopilot clusters
  default_service_account = "keep"

  activate_apis = []
}
