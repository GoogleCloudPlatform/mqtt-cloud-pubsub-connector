#!/usr/bin/env sh

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

set -o nounset
set -o errexit

echo "This script has been invoked with: $0 $*"

# shellcheck disable=SC1094
. scripts/common.sh

# Doesn't follow symlinks, but it's likely expected for most users
SCRIPT_BASENAME="$(basename "${0}")"

TERRAFORM_SUBCOMMAND_DESCRIPTION="Terraform subcommand to run, along with arguments. Defaults to 'apply'."

usage() {
  echo
  echo "${SCRIPT_BASENAME} - This script initializes the environment for Terraform, and runs it. The script will always run terraform init and terraform validate before any subcommand you specify."
  echo
  echo "USAGE"
  echo "  ${SCRIPT_BASENAME} [options]"
  echo
  echo "OPTIONS"
  echo "  -h $(is_linux && echo "| --help"): ${HELP_DESCRIPTION}"
  echo "  -s $(is_linux && echo "| --terraform-subcommand"): ${TERRAFORM_SUBCOMMAND_DESCRIPTION}"
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${ERR_VARIABLE_NOT_DEFINED} when a parameter or a variable is not defined, or empty."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo "  ${ERR_ARGUMENT_EVAL_ERROR} when there was an error while evaluating the program options."
}

LONG_OPTIONS="help,terraform-subcommand:"
SHORT_OPTIONS="ht:"

# BSD getopt (bundled in MacOS) doesn't support long options, and has different parameters than GNU getopt
if is_linux; then
  TEMP="$(getopt -o "${SHORT_OPTIONS}" --long "${LONG_OPTIONS}" -n "${SCRIPT_BASENAME}" -- "$@")"
elif is_macos; then
  TEMP="$(getopt "${SHORT_OPTIONS} --" "$@")"
  echo "WARNING: Long command line options are not supported on this system."
fi
RET_CODE=$?
if [ ! ${RET_CODE} ]; then
  echo "Error while evaluating command options. Terminating..."
  # Ignoring because those are defined in common.sh, and don't need quotes
  # shellcheck disable=SC2086
  exit ${ERR_ARGUMENT_EVAL_ERROR}
fi
eval set -- "${TEMP}"

TERRAFORM_SUBCOMMAND="apply"

while true; do
  case "${1}" in
  -t | --terraform-subcommand)
    TERRAFORM_SUBCOMMAND="${2}"
    shift 2
    ;;
  --)
    shift
    break
    ;;
  -h | --help | *)
    usage
    # Ignoring because those are defined in common.sh, and don't need quotes
    # shellcheck disable=SC2086
    exit $EXIT_OK
    break
    ;;
  esac
done

check_optional_argument "${TERRAFORM_SUBCOMMAND}" "${TERRAFORM_SUBCOMMAND_DESCRIPTION}"

build_gcloud_container_image

if ! check_gcloud_authentication; then
  echo "Authenticating with Google Cloud..."
  authenticate_gcloud
fi

if [ ! -f "${TERRAFORM_INIT_VARIABLES_FILE_PATH}" ]; then
  echo "[ERROR] Could not find ${TERRAFORM_INIT_VARIABLES_FILE_PATH}. Provide one to continue."
fi

echo "Provisioning the Google Cloud project..."

run_containerized_terraform "${TERRAFORM_INIT_ENVIRONMENT_DIR}" version
run_containerized_terraform "${TERRAFORM_INIT_ENVIRONMENT_DIR}" init
run_containerized_terraform "${TERRAFORM_INIT_ENVIRONMENT_DIR}" validate
run_containerized_terraform "${TERRAFORM_INIT_ENVIRONMENT_DIR}" "${TERRAFORM_SUBCOMMAND}"

if [ ! -f "${TERRAFORM_BACKEND_CONFIGURATION_FILE_PATH}" ]; then
  _TERRAFORM_BACKEND_CLOUD_STORAGE_BUCKET_NAME="$(run_containerized_terraform "${TERRAFORM_INIT_ENVIRONMENT_DIR}" output -raw terraform_backend_gcs_bucket_name)"

  echo "Generating the Terraform backend configuration file: ${TERRAFORM_BACKEND_CONFIGURATION_FILE_PATH}"
  tee "${TERRAFORM_BACKEND_CONFIGURATION_FILE_PATH}" <<EOF
bucket = "${_TERRAFORM_BACKEND_CLOUD_STORAGE_BUCKET_NAME}"
EOF
  unset _TERRAFORM_BACKEND_CLOUD_STORAGE_BUCKET_NAME

  echo "${TERRAFORM_BACKEND_CONFIGURATION_FILE_PATH} contents:"
  cat "${TERRAFORM_BACKEND_CONFIGURATION_FILE_PATH}"
fi

if [ ! -f "${TERRAFORM_VARIABLES_FILE_PATH}" ]; then
  _GOOGLE_CLOUD_PROJECT_ID="$(run_containerized_terraform "${TERRAFORM_INIT_ENVIRONMENT_DIR}" output -raw google_project_id)"

  echo "Setting the Google Cloud project ID (${_GOOGLE_CLOUD_PROJECT_ID}) in the Terraform variables file: ${TERRAFORM_VARIABLES_FILE_PATH}"
  tee "${TERRAFORM_VARIABLES_FILE_PATH}" <<EOF
google_default_project_id = "${_GOOGLE_CLOUD_PROJECT_ID}"
EOF
  unset _GOOGLE_CLOUD_PROJECT_ID

  echo "${TERRAFORM_BACKEND_CONFIGURATION_FILE_PATH} contents:"
  cat "${TERRAFORM_BACKEND_CONFIGURATION_FILE_PATH}"
fi

echo "Provisioning resources in the Google Cloud project..."

run_containerized_terraform "${TERRAFORM_ENVIRONMENT_DIR}" version
run_containerized_terraform "${TERRAFORM_ENVIRONMENT_DIR}" init -backend-config="$(basename "${TERRAFORM_BACKEND_CONFIGURATION_FILE_PATH}")"
run_containerized_terraform "${TERRAFORM_ENVIRONMENT_DIR}" validate
run_containerized_terraform "${TERRAFORM_ENVIRONMENT_DIR}" "${TERRAFORM_SUBCOMMAND}"
