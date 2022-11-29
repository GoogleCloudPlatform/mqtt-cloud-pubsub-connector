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
