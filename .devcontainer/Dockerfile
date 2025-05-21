FROM hashicorp/terraform:1.12.1 as terraform

FROM mcr.microsoft.com/vscode/devcontainers/java:21-bullseye

ARG INSTALL_MAVEN="false"
ARG MAVEN_VERSION=""
ARG INSTALL_GRADLE="false"
ARG GRADLE_VERSION=""
RUN if [ "${INSTALL_MAVEN}" = "true" ]; then su vscode -c "umask 0002 && . /usr/local/sdkman/bin/sdkman-init.sh && sdk install maven \"${MAVEN_VERSION}\""; fi \
    && if [ "${INSTALL_GRADLE}" = "true" ]; then su vscode -c "umask 0002 && . /usr/local/sdkman/bin/sdkman-init.sh && sdk install gradle \"${GRADLE_VERSION}\""; fi

ARG NODE_VERSION="none"
RUN if [ "${NODE_VERSION}" != "none" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

COPY --from=terraform /bin/terraform /usr/bin/

SHELL ["/bin/bash", "-o", "pipefail", "-o", "errexit", "-c"]

ENV KUBERNETES_APT_REPOSITORY_KEY_PATH="/etc/apt/keyrings/kubernetes-archive-keyring.gpg"
ENV KUBERNETES_APT_REPOSITORY_URL="https://pkgs.k8s.io/core:/stable:/v1.28/deb/"

RUN mkdir -p "$(dirname "${KUBERNETES_APT_REPOSITORY_KEY_PATH}")" \
    && echo "deb [signed-by=${KUBERNETES_APT_REPOSITORY_KEY_PATH}] ${KUBERNETES_APT_REPOSITORY_URL} /" | tee /etc/apt/sources.list.d/kubernetes.list \
    && curl -fsSL "${KUBERNETES_APT_REPOSITORY_URL}/Release.key" | gpg --dearmor -o "${KUBERNETES_APT_REPOSITORY_KEY_PATH}" \
    && apt-get update \
    && apt-get install --no-install-recommends --yes kubectl \
    && rm -rf /var/lib/apt/lists/* \
    && kubectl version --client
