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

# https://registry.terraform.io/modules/terraform-google-modules/cloud-storage/google
module "terraform_backend_gcs_buckets" {
  source  = "terraform-google-modules/cloud-storage/google"
  version = "5.0.0"

  location                 = var.terraform_state_production_bucket_location
  names                    = [var.terraform_state_production_bucket_name]
  prefix                   = module.project-factory.project_id
  project_id               = module.project-factory.project_id
  public_access_prevention = true
  randomize_suffix         = true

  force_destroy = {
    (var.terraform_state_production_bucket_name) = true
  }

  versioning = {
    (var.terraform_state_production_bucket_name) = true
  }
}
