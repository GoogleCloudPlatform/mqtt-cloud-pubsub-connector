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

package com.google.cloud.solutions.routes;

import static org.assertj.core.api.Assertions.assertThat;

import com.google.cloud.solutions.profiles.SingleMqttTopicNameProfile;
import com.google.cloud.solutions.resources.AbstractContainerResource;
import com.google.cloud.solutions.resources.CloudPubSubResource;
import com.google.cloud.solutions.resources.MqttBrokerResource;
import io.quarkus.test.common.QuarkusTestResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;
import jakarta.inject.Inject;
import org.junit.jupiter.api.Test;

@QuarkusTest
@QuarkusTestResource(
    parallel = true,
    value = MqttBrokerResource.class,
    initArgs = {
      @ResourceArg(
          name = AbstractContainerResource.CONTAINER_IMAGE_PROPERTY_KEY,
          value = "com.google.cloud.solutions.mqtt-client.mqtt-broker-container-image-id")
    })
@QuarkusTestResource(
    parallel = true,
    value = CloudPubSubResource.class,
    initArgs = {
      @ResourceArg(
          name = AbstractContainerResource.CONTAINER_IMAGE_PROPERTY_KEY,
          value = "com.google.cloud.solutions.mqtt-client.cloud-pubsub-container-image-id")
    })
@TestProfile(SingleMqttTopicNameProfile.class)
public class MqttToCloudPubSubRouteTest {

  @Inject MqttToCloudPubSubRoute mqttToCloudPubSubRoute;

  @Test
  public void testMqttToCloudPubSubRouteId() {
    String mqttToCloudPubSubRouteId = mqttToCloudPubSubRoute.getMqttToCloudPubSubRouteId();
    assertThat(mqttToCloudPubSubRouteId).isNotBlank();
    assertThat(mqttToCloudPubSubRouteId)
        .startsWith(MqttToCloudPubSubRoute.MQTT_TO_CLOUD_PUB_SUB_ROUTE_ID_PREFIX);
  }

  @Test
  public void testMqttToCloudPubSubFromSourceTopicMqttClientId() {
    String mqttToCloudPubSubRouteMqttClientId =
        mqttToCloudPubSubRoute.getFromSourceTopicMqttClientId();
    assertThat(mqttToCloudPubSubRouteMqttClientId).isNotBlank();
    assertThat(mqttToCloudPubSubRouteMqttClientId)
        .startsWith(
            MqttToCloudPubSubRoute.MQTT_CLIENT_ID_PREFIX
                + MqttToCloudPubSubRoute.MQTT_CLIENT_ID_FROM_SOURCE_TOPIC_PREFIX);
  }
}
