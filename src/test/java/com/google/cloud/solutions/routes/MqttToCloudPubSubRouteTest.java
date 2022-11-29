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

import com.google.cloud.solutions.resources.AbstractContainerResource;
import com.google.cloud.solutions.resources.CloudPubSubResource;
import com.google.cloud.solutions.resources.InjectCloudPubSubContainer;
import com.google.cloud.solutions.resources.InjectMqttBrokerContainer;
import com.google.cloud.solutions.resources.MqttBrokerResource;
import io.quarkus.test.common.QuarkusTestResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.junit.QuarkusTest;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import javax.inject.Inject;
import org.apache.camel.CamelContext;
import org.apache.camel.ConsumerTemplate;
import org.apache.camel.Exchange;
import org.apache.camel.Message;
import org.apache.camel.ProducerTemplate;
import org.apache.camel.builder.NotifyBuilder;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;
import org.junit.jupiter.api.Test;
import org.testcontainers.containers.GenericContainer;

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
public class MqttToCloudPubSubRouteTest {

  private static final Logger LOG = Logger.getLogger(MqttToCloudPubSubRouteTest.class);

  @Inject CamelContext camelContext;

  @Inject ConsumerTemplate consumerTemplate;

  @InjectCloudPubSubContainer GenericContainer<?> cloudPubsubContainer;

  @ConfigProperty(name = MqttToCloudPubSubRoute.CLOUD_PUB_SUB_PROJECT_ID_PROPERTY_KEY)
  @Inject
  String cloudPubSubProjectId;

  @ConfigProperty(
      name = CloudPubSubResource.CLOUD_PUB_SUB_DESTINATION_TOPIC_SUBSCRIPTION_NAME_PROPERTY_KEY)
  @Inject
  String cloudPubSubDestinationTopicSubscriptionName;

  @Inject MqttToCloudPubSubRoute mqttToCloudPubSubRoute;

  @InjectMqttBrokerContainer GenericContainer<?> mqttBrokerContainer;

  @Inject ProducerTemplate producerTemplate;

  @ConfigProperty(name = MqttToCloudPubSubRoute.MQTT_TOPIC_PROPERTY_KEY)
  @Inject
  String mqttTopic;

  private void assertCloudPubSubClientConnected(String cloudPubSubLogContents) {
    assertThat(cloudPubSubLogContents).isNotBlank();
    assertThat(cloudPubSubLogContents).contains("Detected HTTP/2 connection");
  }

  /**
   * Assert that an MQTT client connected to the MQTT broker by inspecting the MQTT broker logs.
   *
   * @param mqttBrokerLogContents The contents of the MQTT broker logs
   * @param mqttClientId The ID of the MQTT client that connected to the MQTT broker
   */
  private void assertMqttClientConnected(String mqttBrokerLogContents, String mqttClientId) {
    assertThat(mqttBrokerLogContents).isNotBlank();
    assertThat(mqttClientId).isNotBlank();

    assertThat(mqttBrokerLogContents).contains("Sending CONNACK to " + mqttClientId);
  }

  /**
   * Assert that an MQTT client disconnected from the MQTT broker by inspecting the MQTT broker
   * logs.
   *
   * @param mqttBrokerLogContents The contents of the MQTT broker logs
   * @param mqttClientId The ID of the MQTT client that disconnected from the MQTT broker
   */
  private void assertMqttClientDisconnected(String mqttBrokerLogContents, String mqttClientId) {
    assertThat(mqttBrokerLogContents).isNotBlank();
    assertThat(mqttClientId).isNotBlank();

    assertThat(mqttBrokerLogContents).contains("Client " + mqttClientId + " disconnected.");
  }

  /**
   * Assert that an MQTT client published a message in a MQTT topic by inspecting the MQTT broker
   * logs.
   *
   * @param mqttBrokerLogContents The contents of the MQTT broker logs
   * @param mqttClientId The ID of the MQTT client that published the message
   * @param mqttTopicName The name of the MQTT topic
   */
  private void assertMqttClientPublishedMessage(
      String mqttBrokerLogContents, String mqttClientId, String mqttTopicName) {
    assertThat(mqttBrokerLogContents).isNotBlank();
    assertThat(mqttClientId).isNotBlank();
    assertThat(mqttTopicName).isNotBlank();

    assertThat(mqttBrokerLogContents)
        .containsPattern(
            "Received PUBLISH from " + mqttClientId + " \\(([a-z][0-9], ){4}'" + mqttTopicName);
  }

  private void assertMqttClientSubscribedToTopic(
      String mqttBrokerLogContents, String mqttClientId, String mqttTopicName) {
    assertThat(mqttBrokerLogContents).isNotBlank();
    assertThat(mqttClientId).isNotBlank();
    assertThat(mqttTopicName).isNotBlank();

    assertThat(mqttBrokerLogContents)
        .containsPattern(
            "Received SUBSCRIBE from " + mqttClientId + "\n[0-9]*: \\t" + mqttTopicName);
  }

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

  @Test
  public void testRouteUnsecuredMqttMessageToCloudPubSub() {
    // Set a MQTT client ID that we use in this test to check a few things, such as
    // if the client actually connected to the MQTT broker
    String testMqttClientId =
        MqttToCloudPubSubRoute.MQTT_CLIENT_ID_PREFIX + "test-client-" + UUID.randomUUID();

    // Build the Apache Camel component endpoint URL to connect to the containerized
    // MQTT broker. We call this the "test MQTT client".
    String mqttEndpointUrl = "paho-mqtt5:" + mqttTopic + "?" + "clientId=" + testMqttClientId;
    LOG.infof("The MQTT broker endpoint URL is %s", mqttEndpointUrl);

    assertThat(mqttBrokerContainer).isNotNull();

    // To proceed only when messages are successfully processed
    NotifyBuilder notifyBuilder = new NotifyBuilder(camelContext).whenCompleted(1).create();

    // Publish a message in a MQTT topic using the test MQTT client
    String messageBody = "test";
    LOG.infof("Sending message (payload: %s) to %s endpoint", messageBody, mqttEndpointUrl);
    producerTemplate.sendBody(mqttEndpointUrl, messageBody);
    producerTemplate.stop();

    String cloudPubSubEndpointUrl =
        "google-pubsub:" + cloudPubSubProjectId + ":" + cloudPubSubDestinationTopicSubscriptionName;
    LOG.infof("Receiving message from %s endpoint", cloudPubSubEndpointUrl);
    Exchange exchange =
        consumerTemplate.receive(cloudPubSubEndpointUrl + "?" + "synchronousPull=true", 5000L);
    Message receivedMessage = exchange.getMessage();
    String receivedMessageBody = receivedMessage.getBody(String.class);
    consumerTemplate.doneUoW(exchange);
    consumerTemplate.stop();

    // Wait for the message to be successfully processed
    assertThat(notifyBuilder.matches(5, TimeUnit.SECONDS)).isTrue();

    // Check that the test MQTT client connected to the MQTT broker, published a
    // message, and then disconnected from the MQTT broker
    assertMqttClientConnected(mqttBrokerContainer.getLogs(), testMqttClientId);
    assertMqttClientPublishedMessage(mqttBrokerContainer.getLogs(), testMqttClientId, mqttTopic);
    assertMqttClientDisconnected(mqttBrokerContainer.getLogs(), testMqttClientId);

    // Check that the Apache Camel route connected to the MQTT broker, and
    // subscribed to an MQTT topic.
    // We don't test the disconnection because Quarkus shuts down the route after
    // the test is completed.
    String mqttToCloudPubSubRouteClientId = mqttToCloudPubSubRoute.getFromSourceTopicMqttClientId();
    assertMqttClientConnected(mqttBrokerContainer.getLogs(), mqttToCloudPubSubRouteClientId);
    assertMqttClientSubscribedToTopic(
        mqttBrokerContainer.getLogs(), mqttToCloudPubSubRouteClientId, mqttTopic);

    // Assert that the Cloud Pub/Sub client that the route creates connected
    assertCloudPubSubClientConnected(cloudPubsubContainer.getLogs());

    // Ensure that what we received is what we expect
    assertThat(messageBody).isEqualTo(receivedMessageBody);
  }
}
