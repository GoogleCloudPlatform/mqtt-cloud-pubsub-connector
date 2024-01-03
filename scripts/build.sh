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
  echo
  echo "EXIT STATUS"
  echo
  echo "  ${EXIT_OK} on correct execution."
  echo "  ${EXIT_GENERIC_ERR} on a generic error."
  echo "  ${ERR_VARIABLE_NOT_DEFINED} when a parameter or a variable is not defined, or empty."
  echo "  ${ERR_MISSING_DEPENDENCY} when a required dependency is missing."
  echo "  ${ERR_ARGUMENT_EVAL_ERROR} when there was an error while evaluating the program options."
}

LONG_OPTIONS="fix-linting-errors,help"
SHORT_OPTIONS="fh"

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

FIX_LINTING_ERRORS="false"

while true; do
  case "${1}" in
  -f | --fix-linting-errors)
    FIX_LINTING_ERRORS="true"
    shift
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
    ;;
  esac
done

if ! is_ci; then
  echo "Running lint checks"

  _DOCKER_INTERACTIVE_TTY_OPTION=
  if [ -t 0 ]; then
    _DOCKER_INTERACTIVE_TTY_OPTION="-it"
  fi

  LINTER_CONTAINER_IMAGE="ghcr.io/super-linter/super-linter:${LINTER_CONTAINER_IMAGE_VERSION:-"latest"}"

  if [ "${UPDATE_CONTAINER_IMAGE:-}" = "true" ]; then
    docker pull "${LINTER_CONTAINER_IMAGE}"
  fi

  # shellcheck disable=SC2086
  docker run \
    ${_DOCKER_INTERACTIVE_TTY_OPTION} \
    --env ACTIONS_RUNNER_DEBUG="${ACTIONS_RUNNER_DEBUG:-"false"}" \
    --env MULTI_STATUS="false" \
    --env RUN_LOCAL="true" \
    --env-file "config/lint/super-linter.env" \
    --name "super-linter" \
    --rm \
    --volume "$(pwd)":/tmp/lint \
    --volume /etc/localtime:/etc/localtime:ro \
    --workdir /tmp/lint \
    "${LINTER_CONTAINER_IMAGE}" \
    "$@"

  unset _DOCKER_INTERACTIVE_TTY_OPTION
else
  echo "Skipping lint checks because we assume it runs in a dedicated CI workflow."
fi

echo "Building the devcontainer container image: ${DEVCONTAINER_IMAGE_FULL_ID}"

docker build \
  --file ./.devcontainer/Dockerfile \
  --tag "${DEVCONTAINER_IMAGE_FULL_ID}" \
  .

if [ "${FIX_LINTING_ERRORS}" = "true" ]; then
  echo "Fixing linting errors..."
  run_devcontainer ./gradlew --no-daemon :spotlessApply
fi

echo "Running the dev container to build the project: ${DEVCONTAINER_IMAGE_FULL_ID}"
run_devcontainer ./gradlew --info --no-daemon --warning-mode all clean build

echo "Building the project container image: ${MQTT_CLOUD_PUBSUB_CONNECTOR_CONTAINER_IMAGE_FULL_ID}"
docker build \
  --tag "${MQTT_CLOUD_PUBSUB_CONNECTOR_CONTAINER_IMAGE_FULL_ID}" \
  .

if [ ! -e "${MQTT_BROKER_BENCHMARK_DIRECTORY_PATH}" ]; then
  git clone https://github.com/emqx/emqtt-bench.git
  git -C "${MQTT_BROKER_BENCHMARK_DIRECTORY_PATH}" checkout "0.4.7"
fi

docker build \
  --file "${MQTT_BROKER_BENCHMARK_DIRECTORY_PATH}/Dockerfile" \
  --tag "${MQTT_BROKER_BENCHMARKER_CONTAINER_IMAGE_FULL_ID}" \
  "${MQTT_BROKER_BENCHMARK_DIRECTORY_PATH}"
