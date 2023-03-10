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

variable "billing_account_id" {
  description = "ID of the billing account to link to the Google Cloud project."
  sensitive   = true
  type        = string
}

variable "folder_id" {
  # The project-factory modules expects an empty string if the project is not going to be in a folder.
  # See https://github.com/terraform-google-modules/terraform-google-project-factory/blob/master/modules/core_project_factory/main.tf
  default     = ""
  description = "ID of the Google Cloud folder where to create the Google Cloud project in. For more information about getting the Google Cloud folder ID, refer to https://cloud.google.com/resource-manager/docs/creating-managing-folders"
  type        = string
}

variable "google_project_id" {
  description = "ID of the Google Cloud project to create. For more information about getting the Google Cloud project ID, refer to https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects"
  type        = string
}

variable "organization_id" {
  description = "ID of the Google Cloud Organization where to create the Google Cloud project in. For more information about getting the Google Cloud Organization ID, refer to https://cloud.google.com/resource-manager/docs/creating-managing-organization#retrieving_your_organization_id"
  type        = string
}

variable "terraform_state_production_bucket_location" {
  default     = "EU"
  description = "Location where to create the Google Cloud Storage bucket to store the production Terraform state."
  type        = string
}

variable "terraform_state_production_bucket_name" {
  description = "Name of the Google Cloud Storage bucket to store the production Terraform state."
  type        = string
}
