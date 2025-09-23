FROM hadolint/hadolint:v2.14.0-alpine AS dockerfile-lint
FROM mvdan/shfmt:v3.12.0 AS shfmt
FROM hashicorp/terraform:1.13.3 AS terraform

FROM mcr.microsoft.com/vscode/devcontainers/java:21-bullseye

ARG INSTALL_MAVEN="false"
ARG MAVEN_VERSION=""
ARG INSTALL_GRADLE="true"
ARG GRADLE_VERSION=""
RUN if [ "${INSTALL_MAVEN}" = "true" ]; then su vscode -c "umask 0002 && . /usr/local/sdkman/bin/sdkman-init.sh && sdk install maven \"${MAVEN_VERSION}\""; fi \
    && if [ "${INSTALL_GRADLE}" = "true" ]; then su vscode -c "umask 0002 && . /usr/local/sdkman/bin/sdkman-init.sh && sdk install gradle \"${GRADLE_VERSION}\""; fi

ARG NODE_VERSION="v24.8.0"
RUN if [ "${NODE_VERSION}" != "none" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

COPY --from=dockerfile-lint /bin/hadolint /usr/local/bin/
COPY --from=shfmt /bin/shfmt /usr/local/bin/
COPY --from=terraform /bin/terraform /usr/local/bin/

SHELL ["/bin/bash", "-o", "pipefail", "-o", "errexit", "-c"]

RUN npm install --global prettier@3.6.2

ENV KUBERNETES_APT_REPOSITORY_KEY_PATH="/etc/apt/keyrings/kubernetes-archive-keyring.gpg"
ENV KUBERNETES_APT_REPOSITORY_URL="https://pkgs.k8s.io/core:/stable:/v1.28/deb/"

RUN mkdir -p "$(dirname "${KUBERNETES_APT_REPOSITORY_KEY_PATH}")" \
    && echo "deb [signed-by=${KUBERNETES_APT_REPOSITORY_KEY_PATH}] ${KUBERNETES_APT_REPOSITORY_URL} /" | tee /etc/apt/sources.list.d/kubernetes.list \
    && curl -fsSL "${KUBERNETES_APT_REPOSITORY_URL}/Release.key" | gpg --dearmor -o "${KUBERNETES_APT_REPOSITORY_KEY_PATH}" \
    && apt-get update \
    && apt-get install --no-install-recommends --yes kubectl \
    && rm -rf /var/lib/apt/lists/* \
    && kubectl version --client

ENV JAVA_HOME=/usr/lib/jvm/msopenjdk-current
ENV PATH="${JAVA_HOME}/bin:${PATH}"
