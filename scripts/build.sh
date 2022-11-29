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

# Doesn't follow symlinks, but it's likely expected for most users
SCRIPT_BASENAME="$(basename "${0}")"
SCRIPT_DIRECTORY_PATH="$(dirname "${0}")"

echo "This script (${SCRIPT_BASENAME}) has been invoked with: $0 $*"
echo "This script directory path is: ${SCRIPT_DIRECTORY_PATH}"

# shellcheck source=/dev/null
. "${SCRIPT_DIRECTORY_PATH}/common.sh"

FIX_LINTING_ERRORS_DESCRIPTION="Automatically fix linting errors."
PUSH_CONTAINER_IMAGE_REGISTRY_DESCRIPTION="Push the container image to the provided registry."

usage() {
  echo
  echo "${SCRIPT_BASENAME} - This script builds the container image to run the MQTT <-> Cloud Pub/Sub Connector"
  echo
  echo "USAGE"
  echo "  ${SCRIPT_BASENAME} [options]"
  echo
  echo "OPTIONS"
  echo "  -f $(is_linux && echo "| --fix-linting-errors"): ${FIX_LINTING_ERRORS_DESCRIPTION}"
  echo "  -h $(is_linux && echo "| --help"): ${HELP_DESCRIPTION}"
  echo "  -p $(is_linux && echo "| --push-container-image"): ${PUSH_CONTAINER_IMAGE_REGISTRY_DESCRIPTION}"
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${EXIT_GENERIC_ERR} on a generic error."
  echo "  ${ERR_VARIABLE_NOT_DEFINED} when a parameter or a variable is not defined, or empty."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo "  ${ERR_ARGUMENT_EVAL_ERROR} when there was an error while evaluating the program options."
}

LONG_OPTIONS="fix-linting-errors,help,push-container-image:"
SHORT_OPTIONS="fhp:"

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

CONTAINER_IMAGE_ID="google-cloud-platform/mqtt-to-cloud-pubsub-connector"
CONTAINER_IMAGE_TAG="latest"
DEVCONTAINER_IMAGE_TAG="latest"
DEVCONTAINER_CLI_IMAGE_TAG="latest"
FIX_LINTING_ERRORS="false"
PUSH_CONTAINER_IMAGE_REGISTRY=

while true; do
  case "${1}" in
  -f | --fix-linting-errors)
    FIX_LINTING_ERRORS="true"
    shift
    break
    ;;
  -p | --push-container-image)
    PUSH_CONTAINER_IMAGE_REGISTRY="${2}"
    shift 2
    break
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

# Setting this here because we might have changed it when processing options
CONTAINER_IMAGE_FULL_ID="${CONTAINER_IMAGE_ID}:${CONTAINER_IMAGE_TAG}"
DEVCONTAINER_IMAGE_FULL_ID="${CONTAINER_IMAGE_ID}-devcontainer:${DEVCONTAINER_IMAGE_TAG}"

check_exec_dependency "docker"

echo "Building the devcontainer container image: ${DEVCONTAINER_IMAGE_FULL_ID}"

docker build \
  --file ./.devcontainer/Dockerfile \
  --tag "${DEVCONTAINER_IMAGE_FULL_ID}" \
  .

WORKSPACE_DIRECTORY_SOURCE_PATH="$(pwd)"

DOCKER_FLAGS=
if [ -t 0 ]; then
  DOCKER_FLAGS=-it
fi

if [ "${FIX_LINTING_ERRORS}" = "true" ]; then
  echo "Fixing linting errors..."
  docker run \
    ${DOCKER_FLAGS} \
    --env "JAVA_HOME=/usr/lib/jvm/msopenjdk-current" \
    --rm \
    --volume "${WORKSPACE_DIRECTORY_SOURCE_PATH}":"/workspace" \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --workdir "/workspace" \
    "${DEVCONTAINER_IMAGE_FULL_ID}" \
    ./gradlew :spotlessApply
fi

echo "Running the dev container to build the project: ${DEVCONTAINER_IMAGE_FULL_ID}"

docker run \
  ${DOCKER_FLAGS} \
  --env "JAVA_HOME=/usr/lib/jvm/msopenjdk-current" \
  --rm \
  --volume "${WORKSPACE_DIRECTORY_SOURCE_PATH}":"/workspace" \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --workdir "/workspace" \
  "${DEVCONTAINER_IMAGE_FULL_ID}" \
  ./gradlew clean build

echo "Building the project container image: ${CONTAINER_IMAGE_FULL_ID}"
docker build \
  --tag "${CONTAINER_IMAGE_FULL_ID}" \
  .

if [ -n "${PUSH_CONTAINER_IMAGE_REGISTRY}" ]; then
  CONTAINER_IMAGE_FULL_ID_PLUS_REGISTRY="${PUSH_CONTAINER_IMAGE_REGISTRY}/${CONTAINER_IMAGE_FULL_ID}"

  echo "Tagging ${CONTAINER_IMAGE_FULL_ID_PLUS_REGISTRY}"
  docker image tag "${CONTAINER_IMAGE_FULL_ID}" "${CONTAINER_IMAGE_FULL_ID_PLUS_REGISTRY}"

  echo "Pushing ${CONTAINER_IMAGE_FULL_ID_PLUS_REGISTRY}"
  docker image push \
    --all-tags \
    "${CONTAINER_IMAGE_FULL_ID_PLUS_REGISTRY}"
fi
