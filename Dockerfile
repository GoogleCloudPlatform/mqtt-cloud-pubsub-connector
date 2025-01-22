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

FROM ghcr.io/graalvm/jdk-community:23.0.2

ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en'

ENV APP_DIRECTORY="/usr/src/app"
ENV USER_UID=185
ENV USER_GID=${USER_UID}

RUN mkdir --parent "${APP_DIRECTORY}" \
    && chown "${USER_UID}":"${USER_GID}" "${APP_DIRECTORY}"
WORKDIR /usr/src/app

USER "${USER_UID}"

# # We make four distinct layers so if there are application changes the library layers can be re-used
COPY --chown="${USER_UID}" build/quarkus-app/lib/ "${APP_DIRECTORY}/lib/"
COPY --chown="${USER_UID}" build/quarkus-app/*.jar "${APP_DIRECTORY}/"
COPY --chown="${USER_UID}" build/quarkus-app/app/ "${APP_DIRECTORY}/app/"
COPY --chown="${USER_UID}" build/quarkus-app/quarkus/ "${APP_DIRECTORY}/quarkus/"

EXPOSE 8080
USER 185
ENV JAVA_OPTS="-Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager"

ENTRYPOINT [ "java" ]
CMD [ "-jar", "./quarkus-run.jar" ]
