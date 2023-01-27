FROM hashicorp/terraform:1.3.7 as terraform

FROM mcr.microsoft.com/vscode/devcontainers/java:17-bullseye

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

RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
    apt-transport-https \
    ca-certificates \
    curl \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update \
    && apt-get install --no-install-recommends --yes kubectl \
    && rm -rf /var/lib/apt/lists/* \
    && kubectl version --client
