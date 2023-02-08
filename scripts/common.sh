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
ERR_MISSING_CONFIGURATION_FILE=6

# shellcheck disable=SC2034
HELP_DESCRIPTION="show this help message and exit"

CURRENT_WORKING_DIRECTORY="$(pwd)"

TERRAFORM_ENVIRONMENT_DIR="${CURRENT_WORKING_DIRECTORY}/terraform"
TERRAFORM_INIT_ENVIRONMENT_DIR="${CURRENT_WORKING_DIRECTORY}/terraform-init"

# shellcheck disable=SC2034
TERRAFORM_INIT_VARIABLES_FILE_PATH="${TERRAFORM_INIT_ENVIRONMENT_DIR}/terraform.tfvars"

# shellcheck disable=SC2034
TERRAFORM_BACKEND_CONFIGURATION_FILE_PATH="${TERRAFORM_ENVIRONMENT_DIR}/gcs-backend.conf"
# shellcheck disable=SC2034
TERRAFORM_VARIABLES_FILE_PATH="${TERRAFORM_ENVIRONMENT_DIR}/terraform.tfvars"

WORKLOADS_DEPLOYMENT_DESCRIPTORS_DIRECTORY_PATH="${CURRENT_WORKING_DIRECTORY}/kubernetes"

MQTT_BROKER_DEPLOYMENT_DESCRIPTORS_DIRECTORY_PATH="${WORKLOADS_DEPLOYMENT_DESCRIPTORS_DIRECTORY_PATH}/mosquitto"
# shellcheck disable=SC2034
MQTT_BROKER_KUSTOMIZE_FILE_PATH="${MQTT_BROKER_DEPLOYMENT_DESCRIPTORS_DIRECTORY_PATH}/kustomization.yaml"

MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_DESCRIPTORS_DIRECTORY_PATH="${WORKLOADS_DEPLOYMENT_DESCRIPTORS_DIRECTORY_PATH}/mqtt-cloud-pubsub-connector"
MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_CONFIGURATION_DIRECTORY_PATH="${MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_DESCRIPTORS_DIRECTORY_PATH}/config"
# shellcheck disable=SC2034
MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_GENERATED_APPLICATION_CONFIGURATION_PATH="${MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_CONFIGURATION_DIRECTORY_PATH}/application.properties"
# shellcheck disable=SC2034
MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_GENERATED_APPLICATION_CLOUD_ENVIRONMENT_CONFIGURATION_PATH="${MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_CONFIGURATION_DIRECTORY_PATH}/application-prod.properties"
# shellcheck disable=SC2034
MQTT_CLOUD_PUBSUB_CONNECTOR_KUSTOMIZE_FILE_PATH="${MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_DESCRIPTORS_DIRECTORY_PATH}/kustomization.yaml"
# shellcheck disable=SC2034
MQTT_CLOUD_PUBSUB_CONNECTOR_WORKLOAD_IDENTITY_PATCH_FILE_PATH="${MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_DESCRIPTORS_DIRECTORY_PATH}/mqtt-cloud-pubsub-connector-workload-identity-annotation-patch.yaml"

# shellcheck disable=SC2034
MQTT_BROKER_BENCHMARK_DIRECTORY_PATH="${CURRENT_WORKING_DIRECTORY}/emqtt-bench"
MQTT_BROKER_DEPLOYMENT_DESCRIPTORS_DIRECTORY_PATH="${WORKLOADS_DEPLOYMENT_DESCRIPTORS_DIRECTORY_PATH}/mqtt-benchmarker"
# shellcheck disable=SC2034
MQTT_BENCHMARKER_KUSTOMIZE_FILE_PATH="${MQTT_BROKER_DEPLOYMENT_DESCRIPTORS_DIRECTORY_PATH}/kustomization.yaml"

CONTAINER_ENGINE_USER_CONFIGURATION_DIRECTORY_PATH="${HOME}/.docker"
# shellcheck disable=SC2034
CONTAINER_ENGINE_USER_CONFIGURATION_FILE_PATH="${CONTAINER_ENGINE_USER_CONFIGURATION_DIRECTORY_PATH}/config.json"

WORKSPACE_DESTINATION_PATH="/workspace"

COMPUTE_ENGINE_SSH_PRIVATE_KEY_DESTINATION_PATH="/root/.ssh/google_compute_engine"

is_ci() {
  if [ "${GITHUB_ACTIONS:-}" = "true" ] || [ "${CI:-}" = "true" ]; then
    return 0
  else
    return 1
  fi
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

echo "Checking if the necessary dependencies are available..."
check_exec_dependency "cut"
check_exec_dependency "docker"
check_exec_dependency "getopt"
check_exec_dependency "grep"
check_exec_dependency "tee"

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

get_simple_java_property() {
  grep "^${2}=" "${1}" | cut -d'=' -f2
}

# Load container image IDs from Java property files when possible to use the same container images in scripts and Java test suites
GCLOUD_CLI_CONTAINER_IMAGE_ID="google-cloud-platform-mqtt-cloud-pub-sub-connector/cloud-sdk:latest"
# shellcheck disable=SC2034
KUSTOMIZE_CONTAINER_IMAGE_ID="k8s.gcr.io/kustomize/kustomize:v4.5.7"
# shellcheck disable=SC2034
MQTT_BROKER_CONTAINER_IMAGE_ID="$(get_simple_java_property "src/test/resources/application.properties" "com.google.cloud.solutions.mqtt-client.mqtt-broker-container-image-id")"
# shellcheck disable=SC2034
MQTT_CLOUD_PUBSUB_CONNECTOR_CONTAINER_IMAGE_ID="google-cloud-platform/mqtt-to-cloud-pubsub-connector"
# shellcheck disable=SC2034
MQTT_CLOUD_PUBSUB_CONNECTOR_CONTAINER_IMAGE_TAG="latest"
# shellcheck disable=SC2034
MQTT_CLOUD_PUBSUB_CONNECTOR_CONTAINER_IMAGE_FULL_ID="${MQTT_CLOUD_PUBSUB_CONNECTOR_CONTAINER_IMAGE_ID}:${MQTT_CLOUD_PUBSUB_CONNECTOR_CONTAINER_IMAGE_TAG}"
# shellcheck disable=SC2034
MQTT_BROKER_BENCHMARKER_CONTAINER_IMAGE_FULL_ID="emqx/emqtt-bench:latest"
TERRAFORM_CONTAINER_IMAGE_ID="$(cat .devcontainer/Dockerfile | grep "hashicorp/terraform" | awk -F ' ' '{print $2}')"

# shellcheck disable=SC2034
DEVCONTAINER_IMAGE_TAG="latest"
DEVCONTAINER_IMAGE_FULL_ID="${MQTT_CLOUD_PUBSUB_CONNECTOR_CONTAINER_IMAGE_ID}-devcontainer:${DEVCONTAINER_IMAGE_TAG}"

DOCKER_FLAGS=
if [ -t 0 ]; then
  DOCKER_FLAGS="--interactive --tty"
fi

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

build_gcloud_container_image() {
  echo "Building the Google Cloud SDK container image"
  docker build \
    --file ./container-images/gcloud-sdk/Dockerfile \
    --tag "${GCLOUD_CLI_CONTAINER_IMAGE_ID}" \
    .
}

run_gcloud_container_image() {
  _EXECUTABLE_NAME="${1}"
  shift

  # shellcheck disable=SC2086
  docker run \
    ${DOCKER_FLAGS} \
    --env GOOGLE_APPLICATION_CREDENTIALS="/root/.config/gcloud/application_default_credentials.json" \
    --env USE_GKE_GCLOUD_AUTH_PLUGIN="True" \
    --rm \
    --volume "${CURRENT_WORKING_DIRECTORY}":"${WORKSPACE_DESTINATION_PATH}" \
    --volume /etc/localtime:/etc/localtime:ro \
    --volumes-from "${GCLOUD_AUTHENTICATION_CONTAINER_NAME}" \
    "${GCLOUD_CLI_CONTAINER_IMAGE_ID}" \
    "${_EXECUTABLE_NAME}" "$@"
  unset _EXECUTABLE_NAME
}

run_devcontainer() {
  GRADLE_CACHE_PATH="${CURRENT_WORKING_DIRECTORY}/.gradle-cache"
  mkdir \
    --parent \
    "${GRADLE_CACHE_PATH}"

  # shellcheck disable=SC2086
  docker run \
    ${DOCKER_FLAGS} \
    --env "JAVA_HOME=/usr/lib/jvm/msopenjdk-current" \
    --rm \
    --volume "${CURRENT_WORKING_DIRECTORY}":"${WORKSPACE_DESTINATION_PATH}" \
    --volume "${GRADLE_CACHE_PATH}":"/root/.gradle" \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --workdir "${WORKSPACE_DESTINATION_PATH}" \
    "${DEVCONTAINER_IMAGE_FULL_ID}" \
    "$@"
}

run_containerized_gcloud() {
  run_gcloud_container_image "gcloud" "$@"
}

run_containerized_kubectl() {
  run_gcloud_container_image "kubectl" "$@"
}

run_containerized_kustomize() {
  _KUSTOMIZE_ENVIRONMENT_DIR_NAME="${1}"
  shift

  # shellcheck disable=SC2086
  docker run \
    ${DOCKER_FLAGS} \
    --rm \
    --user "$(id --user)":"$(id --group)" \
    --volume "${CURRENT_WORKING_DIRECTORY}":"${WORKSPACE_DESTINATION_PATH}" \
    --volume /etc/localtime:/etc/localtime:ro \
    --volumes-from "${GCLOUD_AUTHENTICATION_CONTAINER_NAME}" \
    --workdir "${WORKSPACE_DESTINATION_PATH}/kubernetes/${_KUSTOMIZE_ENVIRONMENT_DIR_NAME}" \
    "${KUSTOMIZE_CONTAINER_IMAGE_ID}" \
    "$@"
  unset _KUSTOMIZE_ENVIRONMENT_DIR_NAME
}

check_artifact_registry_container_image_repository_authentication() {
  if grep -q "${2}" "${1}"; then
    return 0
  else
    return 1
  fi
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

  # shellcheck disable=SC2086
  docker run \
    ${DOCKER_FLAGS} \
    --name "${GCLOUD_AUTHENTICATION_CONTAINER_NAME}" \
    "${GCLOUD_CLI_CONTAINER_IMAGE_ID}" \
    gcloud auth login --update-adc

  create_ssh_keypair
}

authenticate_kubectl() {
  _AUTHENTICATE_KUBECTL_GKE_CLUSTER_NAME="${1}"
  _AUTHENTICATE_KUBECTL_GKE_CLUSTER_PROJECT_ID="${2}"
  _AUTHENTICATE_KUBECTL_GKE_CLUSTER_REGION="${3}"

  echo "Configuring authentication for the ${_AUTHENTICATE_KUBECTL_GKE_CLUSTER_NAME} cluster. Cluster project ID: ${_AUTHENTICATE_KUBECTL_GKE_CLUSTER_PROJECT_ID}. Cluster region: ${_AUTHENTICATE_KUBECTL_GKE_CLUSTER_REGION}"
  run_containerized_gcloud container clusters get-credentials "${_AUTHENTICATE_KUBECTL_GKE_CLUSTER_NAME}" \
    --project "${_AUTHENTICATE_KUBECTL_GKE_CLUSTER_PROJECT_ID}" \
    --region "${_AUTHENTICATE_KUBECTL_GKE_CLUSTER_REGION}"

  unset _AUTHENTICATE_KUBECTL_GKE_CLUSTER_NAME
  unset _AUTHENTICATE_KUBECTL_GKE_CLUSTER_PROJECT_ID
  unset _AUTHENTICATE_KUBECTL_GKE_CLUSTER_REGION
}

create_ssh_keypair() {
  echo "Generating a keypair with an empty passphrase to connect to the bastion host via SSH"
  run_gcloud_container_image "ssh-keygen" \
    -b 4096 \
    -f "${COMPUTE_ENGINE_SSH_PRIVATE_KEY_DESTINATION_PATH}" \
    -N "" \
    -t rsa
}

run_containerized_terraform() {
  _TERRAFORM_ENVIRONMENT_DIR="${1}"
  shift

  # "${HOME}"/.config/gcloud/application_default_credentials.json is a
  # well-known location for application-default credentials

  # shellcheck disable=SC2086
  docker run \
    ${DOCKER_FLAGS} \
    --env GOOGLE_APPLICATION_CREDENTIALS="/root/.config/gcloud/application_default_credentials.json" \
    --rm \
    --volume "$(dirname "${_TERRAFORM_ENVIRONMENT_DIR}")":"${WORKSPACE_DESTINATION_PATH}" \
    --volume /etc/localtime:/etc/localtime:ro \
    --volumes-from "${GCLOUD_AUTHENTICATION_CONTAINER_NAME}" \
    --workdir "${WORKSPACE_DESTINATION_PATH}/$(basename "${_TERRAFORM_ENVIRONMENT_DIR}")" \
    "${TERRAFORM_CONTAINER_IMAGE_ID}" "$@"

  unset _TERRAFORM_ENVIRONMENT_DIR
}

tag_and_push_container_image() {
  _CONTAINER_IMAGE_ID_SOURCE="${1}"
  _CONTAINER_IMAGE_ID_DESTINATION="${2}"

  echo "Tagging the ${_CONTAINER_IMAGE_ID_SOURCE} container image as ${_CONTAINER_IMAGE_ID_DESTINATION}"
  docker image tag "${_CONTAINER_IMAGE_ID_SOURCE}" "${_CONTAINER_IMAGE_ID_DESTINATION}"

  echo "Pushing the ${_CONTAINER_IMAGE_ID_DESTINATION} container image"
  docker image push "${_CONTAINER_IMAGE_ID_DESTINATION}"

  unset _CONTAINER_IMAGE_ID_SOURCE
  unset _CONTAINER_IMAGE_ID_DESTINATION
}
