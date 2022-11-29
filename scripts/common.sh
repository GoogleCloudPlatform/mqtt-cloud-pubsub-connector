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

set -o errexit
set -o nounset

# Ignoring SC2034 because this variable is used in other scripts
# shellcheck disable=SC2034
EXIT_OK=0
# shellcheck disable=SC2034
EXIT_GENERIC_ERR=1
# shellcheck disable=SC2034
ERR_VARIABLE_NOT_DEFINED=2
# shellcheck disable=SC2034
ERR_MISSING_DEPENDENCY=3
# shellcheck disable=SC2034
ERR_ARGUMENT_EVAL_ERROR=4
# shellcheck disable=SC2034
ERR_DIRECTORY_NOT_FOUND=5

# shellcheck disable=SC2034
HELP_DESCRIPTION="show this help message and exit"

check_argument() {
  ARGUMENT_VALUE="${1}"
  ARGUMENT_DESCRIPTION="${2}"

  if [ -z "${ARGUMENT_VALUE}" ]; then
    echo "[ERROR]: ${ARGUMENT_DESCRIPTION} is not defined. Run this command with the -h option to get help. Terminating..."
    # Ignoring because those are defined in common.sh, and don't need quotes
    # shellcheck disable=SC2086
    exit ${ERR_VARIABLE_NOT_DEFINED}
  else
    echo "[OK]: ${ARGUMENT_DESCRIPTION} value is defined: ${ARGUMENT_VALUE}"
  fi

  unset ARGUMENT_NAME
  unset ARGUMENT_VALUE
}

check_exec_dependency() {
  EXECUTABLE_NAME="${1}"

  if ! command -v "${EXECUTABLE_NAME}" >/dev/null 2>&1; then
    echo "[ERROR]: ${EXECUTABLE_NAME} command is not available, but it's needed. Make it available in PATH and try again. Terminating..."
    exit ${ERR_MISSING_DEPENDENCY}
  else
    echo "[OK]: ${EXECUTABLE_NAME} is available in PATH, pointing to: $(command -v "${EXECUTABLE_NAME}")"
  fi

  unset EXECUTABLE_NAME
}

check_optional_argument() {
  ARGUMENT_VALUE="${1}"
  shift
  ARGUMENT_DESCRIPTION="${1}"
  shift
  VALUE_NOT_DEFINED_MESSAGE="$*"

  if [ -z "${ARGUMENT_VALUE}" ]; then
    echo "[OK]: optional ${ARGUMENT_DESCRIPTION} is not defined."
    RET_CODE=1
    if [ -n "${VALUE_NOT_DEFINED_MESSAGE}" ]; then
      echo "${VALUE_NOT_DEFINED_MESSAGE}"
    fi
  else
    echo "[OK]: optional ${ARGUMENT_DESCRIPTION} value is defined: ${ARGUMENT_VALUE}"
    RET_CODE=0
  fi

  unset ARGUMENT_NAME
  unset ARGUMENT_VALUE
  unset VALUE_NOT_DEFINED_MESSAGE
  return ${RET_CODE}
}

is_linux() {
  # Set a default so that we don't have to rely on any environment variable being set
  OS_RELEASE_INFORMATION_FILE_PATH="/etc/os-release"
  if [ -e "${OS_RELEASE_INFORMATION_FILE_PATH}" ]; then
    # shellcheck source=/dev/null
    . "${OS_RELEASE_INFORMATION_FILE_PATH}"
    return 0
  elif is_command_available "uname"; then
    os_name="$(uname -s)"
    if [ "${os_name#*"Linux"}" != "$os_name" ]; then
      unset os_name
      return ${EXIT_OK}
    else
      unset os_name
      return 1
    fi
  else
    echo "Unable to determine if the OS is Linux."
    return 2
  fi
}

is_macos() {
  os_name="$(uname -s)"
  if test "${os_name#*"Darwin"}" != "$os_name"; then
    unset os_name
    return 0
  else
    unset os_name
    return 1
  fi
}

# Gcloud auth container name, reused container volume when gcloud is required in later steps
# shellcheck disable=SC2034
GCLOUD_AUTHENTICATION_CONTAINER_NAME="gcloud-config"

# shellcheck disable=SC2034
GCLOUD_CLI_CONTAINER_IMAGE_ID="gcr.io/google.com/cloudsdktool/cloud-sdk:410.0.0"


run_containerized_gcloud() {
  docker run \
    --env GOOGLE_APPLICATION_CREDENTIALS="/root/.config/gcloud/application_default_credentials.json" \
    --interactive \
    --rm \
    --tty \
    --volume /etc/localtime:/etc/localtime:ro \
    --volumes-from gcloud-config \
    "${GCLOUD_CLI_CONTAINER_IMAGE_ID}" \
    gcloud "$@"
}

check_gcloud_authentication() {
  if docker ps -a -f status=exited -f name="${GCLOUD_AUTHENTICATION_CONTAINER_NAME}" | grep -q "${GCLOUD_AUTHENTICATION_CONTAINER_NAME}" ||
    docker ps -a -f status=created -f name="${GCLOUD_AUTHENTICATION_CONTAINER_NAME}" | grep -q "${GCLOUD_AUTHENTICATION_CONTAINER_NAME}"; then
    return 0
  else
    return 1
  fi
}

cleanup_gcloud_authentication() {
  if check_gcloud_authentication; then
    echo "Cleaning the authentication information..."
    docker rm --force --volumes "${GCLOUD_AUTHENTICATION_CONTAINER_NAME}"
  fi
}

authenticate_gcloud() {
  cleanup_gcloud_authentication

  docker run \
    --interactive \
    --name "${GCLOUD_AUTHENTICATION_CONTAINER_NAME}" \
    --tty \
    "${GCLOUD_CLI_CONTAINER_IMAGE_ID}" \
    gcloud auth login --update-adc
}

CURRENT_WORKING_DIRECTORY="$(pwd)"
TERRAFORM_ENVIRONMENT_DIR="${CURRENT_WORKING_DIRECTORY}/terraform"
TERRAFORM_INIT_ENVIRONMENT_DIR="${CURRENT_WORKING_DIRECTORY}/terraform-init"

TERRAFORM_INIT_VARIABLES_FILE_PATH="${TERRAFORM_INIT_ENVIRONMENT_DIR}/terraform.tfvars"

TERRAFORM_BACKEND_CONFIGURATION_FILE_PATH="${TERRAFORM_ENVIRONMENT_DIR}/gcs-backend.conf"
TERRAFORM_VARIABLES_FILE_PATH="${TERRAFORM_ENVIRONMENT_DIR}/terraform.tfvars"

# shellcheck disable=SC2034
TERRAFORM_CONTAINER_IMAGE_ID="hashicorp/terraform:1.3.6"

run_containerized_terraform() {
  _TERRAFORM_ENVIRONMENT_DIR="${1}"
  shift

  # "${HOME}"/.config/gcloud/application_default_credentials.json is a
  # well-known location for application-default credentials

  # shecllcheck disable=SC2068
  docker run -it --rm \
    --env GOOGLE_APPLICATION_CREDENTIALS="/root/.config/gcloud/application_default_credentials.json" \
    --volume "$(dirname "${_TERRAFORM_ENVIRONMENT_DIR}")":/workspace \
    --volume /etc/localtime:/etc/localtime:ro \
    --volumes-from gcloud-config \
    --workdir "/workspace/$(basename "${_TERRAFORM_ENVIRONMENT_DIR}")" \
    "${TERRAFORM_CONTAINER_IMAGE_ID}" "$@"

  unset _TERRAFORM_ENVIRONMENT_DIR
}
