/*
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */

package com.google.cloud.solutions.resources;

import static java.util.Map.entry;

import com.github.dockerjava.api.model.Ulimit;
import java.lang.annotation.Annotation;
import java.util.Map;
import org.eclipse.microprofile.config.ConfigProvider;
import org.testcontainers.containers.BindMode;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.wait.strategy.Wait;

public class MqttBrokerResource extends AbstractContainerResource {

  public static final String CAMEL_PAHO_MQTT5_BROKER_URL_PROPERTY_KEY =
      "camel.component.paho-mqtt5.broker-url";
  public static final String MQTT_BROKER_TCP_PORT_PROPERTY_KEY =
      "com.google.cloud.solutions.mqtt-client.mqtt-broker-tcp-port";

  private Integer mqttBrokerTcpPort;

  @Override
  protected Map<String, String> buildAdditionalConfigurationProperties() {
    Integer mqttBrokerTcpMappedPort = this.getContainer().getMappedPort(mqttBrokerTcpPort);

    return Map.ofEntries(
        entry(
            MqttBrokerResource.MQTT_BROKER_TCP_PORT_PROPERTY_KEY,
            mqttBrokerTcpMappedPort.toString()),
        entry(
            MqttBrokerResource.CAMEL_PAHO_MQTT5_BROKER_URL_PROPERTY_KEY,
            "tcp://" + containerHostname + ":" + mqttBrokerTcpMappedPort.toString()));
  }

  @Override
  protected GenericContainer<?> configureContainer(GenericContainer<?> container) {

    mqttBrokerTcpPort =
        ConfigProvider.getConfig()
            .getValue(MqttBrokerResource.MQTT_BROKER_TCP_PORT_PROPERTY_KEY, Integer.class);

    container
        .withClasspathResourceMapping(
            "mosquitto/mosquitto.conf", "/mosquitto/config/mosquitto.conf", BindMode.READ_ONLY)
        .withClasspathResourceMapping(
            "mosquitto/password.conf", "/mosquitto/config/password.conf", BindMode.READ_ONLY)
        .withExposedPorts(mqttBrokerTcpPort)
        .waitingFor(Wait.forLogMessage(".* mosquitto version .* running.*", 1))
        .waitingFor(Wait.forListeningPort())
        .withCreateContainerCmdModifier(
            cmd ->
                cmd.getHostConfig().withUlimits(new Ulimit[] {new Ulimit("nofile", 512L, 512L)}));
    return container;
  }

  @Override
  protected Class<? extends Annotation> getContainerInjectionAnnotationClass() {
    return InjectMqttBrokerContainer.class;
  }
}
