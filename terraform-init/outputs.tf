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

output "billing_account_id" {
  description = "ID of the Google Cloud billing account."
  sensitive   = true
  value       = var.billing_account_id
}

output "folder_id" {
  description = "ID of the Google Cloud folder."
  value       = var.folder_id
}

output "google_project_id" {
  description = "ID of the Google Cloud project."
  value       = module.project-factory.project_id
}

output "organization_id" {
  description = "ID of the Google Cloud organization."
  value       = var.organization_id
}

output "terraform_backend_gcs_bucket_name" {
  description = "The Terraform remote backend Google Cloud Storage bucket name."
  value       = module.terraform_backend_gcs_buckets.name
}
