FROM hashicorp/terraform:1.7.3 as terraform

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

RUN mkdir -p "$(dirname "${KUBERNETES_APT_REPOSITORY_KEY_PATH}")" \
    && curl -fsSLo "${KUBERNETES_APT_REPOSITORY_KEY_PATH}" https://dl.k8s.io/apt/doc/apt-key.gpg \
    && chmod 0644 "${KUBERNETES_APT_REPOSITORY_KEY_PATH}" \
    && echo "deb [signed-by=${KUBERNETES_APT_REPOSITORY_KEY_PATH}] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update \
    && apt-get install --no-install-recommends --yes kubectl \
    && rm -rf /var/lib/apt/lists/* \
    && kubectl version --client
