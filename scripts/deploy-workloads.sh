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

usage() {
  echo
  echo "${SCRIPT_BASENAME} - This script deploys workloads in the cloud backend."
  echo
  echo "USAGE"
  echo "  ${SCRIPT_BASENAME} [options]"
  echo
  echo "OPTIONS"
  echo "  -h $(is_linux && echo "| --help"): ${HELP_DESCRIPTION}"
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${ERR_VARIABLE_NOT_DEFINED} when a parameter or a variable is not defined, or empty."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo "  ${ERR_ARGUMENT_EVAL_ERROR} when there was an error while evaluating the program options."
}

LONG_OPTIONS="help"
SHORT_OPTIONS="h"

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

while true; do
  case "${1}" in
  --)
    shift
    break
    ;;
  -h | --help | *)
    usage
    # Ignoring because those are defined in common.sh, and don't need quotes
    # shellcheck disable=SC2086
    exit $EXIT_OK
    ;;
  esac
done

build_gcloud_container_image

if ! check_gcloud_authentication; then
  echo "Authenticating with Google Cloud..."
  authenticate_gcloud
fi

echo "Loading Artifact Registry repository information from Terraform"
_CONTAINER_IMAGE_REPOSITORY_LOCATION="$(run_containerized_terraform "${TERRAFORM_ENVIRONMENT_DIR}" output -raw artifact_registry_container_image_repository_location)"
_CONTAINER_IMAGE_REPOSITORY_PROJECT_ID="$(run_containerized_terraform "${TERRAFORM_ENVIRONMENT_DIR}" output -raw artifact_registry_container_image_repository_project_id)"
_CONTAINER_IMAGE_REPOSITORY_NAME="$(run_containerized_terraform "${TERRAFORM_ENVIRONMENT_DIR}" output -raw artifact_registry_container_image_repository_name)"
_CONTAINER_IMAGE_REPOSITORY_HOSTNAME="${_CONTAINER_IMAGE_REPOSITORY_LOCATION}-docker.pkg.dev"
_CONTAINER_IMAGE_REPOSITORY_ID="${_CONTAINER_IMAGE_REPOSITORY_HOSTNAME}/${_CONTAINER_IMAGE_REPOSITORY_PROJECT_ID}/${_CONTAINER_IMAGE_REPOSITORY_NAME}"
_MQTT_BROKER_CONTAINER_IMAGE_LOCALIZED_ID="${_CONTAINER_IMAGE_REPOSITORY_ID}/${MQTT_BROKER_CONTAINER_IMAGE_ID}"
_MQTT_CLOUD_PUBSUB_CONNECTOR_IMAGE_LOCALIZED_ID="${_CONTAINER_IMAGE_REPOSITORY_ID}/${MQTT_CLOUD_PUBSUB_CONNECTOR_CONTAINER_IMAGE_FULL_ID}"
_MQTT_BROKER_BENCHMARKER_CONTAINER_IMAGE_LOCALIZED_ID="${_CONTAINER_IMAGE_REPOSITORY_ID}/${MQTT_BROKER_BENCHMARKER_CONTAINER_IMAGE_FULL_ID}"

if [ ! -e "${MQTT_BROKER_KUSTOMIZE_FILE_PATH}" ]; then
  echo "Creating ${MQTT_BROKER_KUSTOMIZE_FILE_PATH}"
  run_containerized_kustomize "mosquitto" create \
    --autodetect \
    --namespace="mqtt-cloud-pubsub-connector" \
    --resources "../base"

  echo "Setting the MQTT broker container image ID to: ${_MQTT_BROKER_CONTAINER_IMAGE_LOCALIZED_ID}"
  run_containerized_kustomize "mosquitto" edit set image "eclipse-mosquitto=${_MQTT_BROKER_CONTAINER_IMAGE_LOCALIZED_ID}"

  echo "Creating the MQTT broker configmap"
  run_containerized_kustomize "mosquitto" edit add configmap "mosquitto" \
    --disableNameSuffixHash \
    --from-file="./config/mosquitto.conf"
else
  echo "${MQTT_BROKER_KUSTOMIZE_FILE_PATH} has already been generated"
fi

if [ ! -e "${MQTT_CLOUD_PUBSUB_CONNECTOR_KUSTOMIZE_FILE_PATH}" ]; then
  echo "Generating ${MQTT_CLOUD_PUBSUB_CONNECTOR_KUSTOMIZE_FILE_PATH}"
  run_containerized_kustomize "mqtt-cloud-pubsub-connector" create \
    --autodetect \
    --namespace="mqtt-cloud-pubsub-connector" \
    --resources "../base"

  run_containerized_kustomize "mqtt-cloud-pubsub-connector" edit set image "mqtt-cloud-pubsub-connector=${_MQTT_CLOUD_PUBSUB_CONNECTOR_IMAGE_LOCALIZED_ID}"

  echo "Loading Cloud Pub/Sub information from Terraform"
  _CLOUD_PUBSUB_DESTINATION_PROJECT_ID="$(run_containerized_terraform "${TERRAFORM_ENVIRONMENT_DIR}" output -raw cloud_pubsub_destination_project_id)"
  _CLOUD_PUBSUB_DESTINATION_TOPIC_NAME="$(run_containerized_terraform "${TERRAFORM_ENVIRONMENT_DIR}" output -raw cloud_pubsub_destination_topic_name)"

  echo "Creating the main environment properties file: ${MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_GENERATED_APPLICATION_CONFIGURATION_PATH}"
  cat <<EOF >"${MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_GENERATED_APPLICATION_CONFIGURATION_PATH}"
camel.component.paho-mqtt5.lazy-start-producer=true
EOF

  echo "Creating the cloud environment properties file: ${MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_GENERATED_APPLICATION_CLOUD_ENVIRONMENT_CONFIGURATION_PATH}"
  cat <<EOF >"${MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_GENERATED_APPLICATION_CLOUD_ENVIRONMENT_CONFIGURATION_PATH}"
camel.component.paho-mqtt5.broker-url=tcp://mosquitto:1883
com.google.cloud.solutions.mqtt-client.cloud-pubsub-destination-topic-name=${_CLOUD_PUBSUB_DESTINATION_TOPIC_NAME}
com.google.cloud.solutions.mqtt-client.cloud-pubsub-project-id=${_CLOUD_PUBSUB_DESTINATION_PROJECT_ID}
com.google.cloud.solutions.mqtt-client.mqtt-topic=source-mqtt-topic
EOF

  _MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_GENERATED_APPLICATION_CONFIGURATION_DESTINATION_PATH="./config/$(basename "${MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_GENERATED_APPLICATION_CONFIGURATION_PATH}")"
  _MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_GENERATED_APPLICATION_CLOUD_ENVIRONMENT_DESTINATION_PATH="./config/$(basename "${MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_GENERATED_APPLICATION_CLOUD_ENVIRONMENT_CONFIGURATION_PATH}")"
  echo "Creating the MQTT <-> Cloud Pub/Sub configmap"
  run_containerized_kustomize "mqtt-cloud-pubsub-connector" edit add configmap "mqtt-cloud-pubsub-connector" \
    --disableNameSuffixHash \
    --from-file="${_MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_GENERATED_APPLICATION_CONFIGURATION_DESTINATION_PATH},${_MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_GENERATED_APPLICATION_CLOUD_ENVIRONMENT_DESTINATION_PATH}"

  echo "Loading MQTT <-> Cloud Pub/Sub Connector authentication information"
  _MQTT_CLOUD_PUBSUB_CONNECTOR_SERVICE_ACCOUNT_EMAIL="$(run_containerized_terraform "${TERRAFORM_ENVIRONMENT_DIR}" output -raw mqtt_cloud_pub_sub_connector_service_account_email)"

  echo "Creating ${MQTT_CLOUD_PUBSUB_CONNECTOR_WORKLOAD_IDENTITY_PATCH_FILE_PATH}"
  cat <<EOF >"${MQTT_CLOUD_PUBSUB_CONNECTOR_WORKLOAD_IDENTITY_PATCH_FILE_PATH}"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: mqtt-cloud-pubsub-connector
  annotations:
    iam.gke.io/gcp-service-account: "${_MQTT_CLOUD_PUBSUB_CONNECTOR_SERVICE_ACCOUNT_EMAIL}"
EOF

  echo "Configure Kustomize patches in ${MQTT_CLOUD_PUBSUB_CONNECTOR_KUSTOMIZE_FILE_PATH}"
  cat <<EOF >>"${MQTT_CLOUD_PUBSUB_CONNECTOR_KUSTOMIZE_FILE_PATH}"
patchesStrategicMerge:
  - $(basename "${MQTT_CLOUD_PUBSUB_CONNECTOR_WORKLOAD_IDENTITY_PATCH_FILE_PATH}")
EOF

  unset _CLOUD_PUBSUB_DESTINATION_PROJECT_ID
  unset _CLOUD_PUBSUB_DESTINATION_TOPIC_NAME
  unset _MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_GENERATED_APPLICATION_CLOUD_ENVIRONMENT_DESTINATION_PATH
  unset _MQTT_CLOUD_PUBSUB_CONNECTOR_DEPLOYMENT_GENERATED_APPLICATION_CONFIGURATION_DESTINATION_PATH
  unset _MQTT_CLOUD_PUBSUB_CONNECTOR_SERVICE_ACCOUNT_EMAIL
else
  echo "${MQTT_CLOUD_PUBSUB_CONNECTOR_KUSTOMIZE_FILE_PATH} has already been generated"
fi

if [ ! -e "${MQTT_BENCHMARKER_KUSTOMIZE_FILE_PATH}" ]; then
  echo "Creating ${MQTT_BENCHMARKER_KUSTOMIZE_FILE_PATH}"
  run_containerized_kustomize "mqtt-benchmarker" create \
    --autodetect \
    --namespace="mqtt-cloud-pubsub-connector" \
    --resources "../base"

  echo "Setting the MQTT benchmarker container image ID to: ${_MQTT_BROKER_BENCHMARKER_CONTAINER_IMAGE_LOCALIZED_ID}"
  run_containerized_kustomize "mqtt-benchmarker" edit set image "emqtt-bench=${_MQTT_BROKER_BENCHMARKER_CONTAINER_IMAGE_LOCALIZED_ID}"
else
  echo "${MQTT_BROKER_KUSTOMIZE_FILE_PATH} has already been generated"
fi

echo "Configuring authentication for the ${_CONTAINER_IMAGE_REPOSITORY_ID} repository"
run_containerized_gcloud auth print-access-token |
  docker login \
    --username oauth2accesstoken \
    --password-stdin "https://${_CONTAINER_IMAGE_REPOSITORY_HOSTNAME}"

echo "Pushing container images to the ${_CONTAINER_IMAGE_REPOSITORY_ID} registry"
tag_and_push_container_image "${MQTT_BROKER_CONTAINER_IMAGE_ID}" "${_MQTT_BROKER_CONTAINER_IMAGE_LOCALIZED_ID}"
tag_and_push_container_image "${MQTT_CLOUD_PUBSUB_CONNECTOR_CONTAINER_IMAGE_FULL_ID}" "${_MQTT_CLOUD_PUBSUB_CONNECTOR_IMAGE_LOCALIZED_ID}"
tag_and_push_container_image "${MQTT_BROKER_BENCHMARKER_CONTAINER_IMAGE_FULL_ID}" "${_MQTT_BROKER_BENCHMARKER_CONTAINER_IMAGE_LOCALIZED_ID}"

echo "Loading GKE cluster information from Terraform"
_CONNECTOR_GKE_CLUSTER_NAME="$(run_containerized_terraform "${TERRAFORM_ENVIRONMENT_DIR}" output -raw mqtt_cloud_pub_sub_connector_cluster_name)"
_CONNECTOR_GKE_CLUSTER_PROJECT_ID="$(run_containerized_terraform "${TERRAFORM_ENVIRONMENT_DIR}" output -raw mqtt_cloud_pub_sub_connector_cluster_project_id)"
_CONNECTOR_GKE_CLUSTER_REGION="$(run_containerized_terraform "${TERRAFORM_ENVIRONMENT_DIR}" output -raw mqtt_cloud_pub_sub_connector_cluster_region)"

echo "Loading bastion host information from Terraform"
_BASTION_HOST_HOSTNAME="$(run_containerized_terraform "${TERRAFORM_ENVIRONMENT_DIR}" output -raw bastion_host_hostname)"
_BASTION_HOST_PROJECT_ID="$(run_containerized_terraform "${TERRAFORM_ENVIRONMENT_DIR}" output -raw bastion_host_project_id)"
_BASTION_HOST_ZONE="$(run_containerized_terraform "${TERRAFORM_ENVIRONMENT_DIR}" output -raw bastion_host_zone)"

echo "Configuring GKE cluster authentication"
run_containerized_gcloud compute ssh "${_BASTION_HOST_HOSTNAME}" \
  --command "USE_GKE_GCLOUD_AUTH_PLUGIN=True gcloud container clusters get-credentials ${_CONNECTOR_GKE_CLUSTER_NAME} --region ${_CONNECTOR_GKE_CLUSTER_REGION}" \
  --project "${_BASTION_HOST_PROJECT_ID}" \
  --zone "${_BASTION_HOST_ZONE}"

echo "Getting cluster information"
run_containerized_gcloud compute ssh "${_BASTION_HOST_HOSTNAME}" \
  --command "kubectl version && kubectl get nodes" \
  --project "${_BASTION_HOST_PROJECT_ID}" \
  --zone "${_BASTION_HOST_ZONE}"

echo "Copying deployment descriptors to the bastion host"
run_containerized_gcloud compute scp \
  --project "${_BASTION_HOST_PROJECT_ID}" \
  --recurse \
  --zone "${_BASTION_HOST_ZONE}" \
  "${WORKSPACE_DESTINATION_PATH}/kubernetes/" "${_BASTION_HOST_HOSTNAME}":~/

echo "Creating the target namespace"
run_containerized_gcloud compute ssh "${_BASTION_HOST_HOSTNAME}" \
  --command "kubectl apply --kustomize=kubernetes/base" \
  --project "${_BASTION_HOST_PROJECT_ID}" \
  --zone "${_BASTION_HOST_ZONE}"

echo "Deploying the MQTT broker"
run_containerized_gcloud compute ssh "${_BASTION_HOST_HOSTNAME}" \
  --command "kubectl apply --kustomize=kubernetes/mosquitto" \
  --project "${_BASTION_HOST_PROJECT_ID}" \
  --zone "${_BASTION_HOST_ZONE}"

echo "Deploying the MQTT <-> Cloud Pub/Sub connector"
run_containerized_gcloud compute ssh "${_BASTION_HOST_HOSTNAME}" \
  --command "kubectl apply --kustomize=kubernetes/mqtt-cloud-pubsub-connector" \
  --project "${_BASTION_HOST_PROJECT_ID}" \
  --zone "${_BASTION_HOST_ZONE}"

echo "Deploying the MQTT benchmarker"
run_containerized_gcloud compute ssh "${_BASTION_HOST_HOSTNAME}" \
  --command "kubectl apply --kustomize=kubernetes/mqtt-benchmarker" \
  --project "${_BASTION_HOST_PROJECT_ID}" \
  --zone "${_BASTION_HOST_ZONE}"

unset _BASTION_HOST_HOSTNAME
unset _BASTION_HOST_PROJECT_ID
unset _BASTION_HOST_ZONE
unset _CONNECTOR_GKE_CLUSTER_NAME
unset _CONNECTOR_GKE_CLUSTER_PROJECT_ID
unset _CONNECTOR_GKE_CLUSTER_REGION
unset _CONTAINER_IMAGE_REPOSITORY_HOSTNAME
unset _CONTAINER_IMAGE_REPOSITORY_ID
unset _CONTAINER_IMAGE_REPOSITORY_LOCATION
unset _CONTAINER_IMAGE_REPOSITORY_NAME
unset _CONTAINER_IMAGE_REPOSITORY_PROJECT_ID
unset _MQTT_BROKER_BENCHMARKER_CONTAINER_IMAGE_LOCALIZED_ID
unset _MQTT_BROKER_CONTAINER_IMAGE_LOCALIZED_ID
unset _MQTT_CLOUD_PUBSUB_CONNECTOR_IMAGE_LOCALIZED_ID
