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

import com.google.cloud.solutions.profiles.AbstractTestProfile;
import com.google.cloud.solutions.resources.CloudPubSubResource;
import com.google.cloud.solutions.resources.InjectCloudPubSubContainer;
import com.google.cloud.solutions.resources.InjectMqttBrokerContainer;
import java.util.List;
import java.util.UUID;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;
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

public abstract class AbstractMqttToCloudPubSubMessageExchangeTest {

  private static final Logger LOG =
      Logger.getLogger(AbstractMqttToCloudPubSubMessageExchangeTest.class);

  @Inject CamelContext camelContext;

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

  @ConfigProperty(name = MqttToCloudPubSubRoute.MQTT_TOPIC_PROPERTY_KEY)
  @Inject
  String mqttTopic;

  @ConfigProperty(name = AbstractTestProfile.MQTT_TOPICS_TO_PUBLISH_TO_PROPERTY_KEY)
  @Inject
  String mqttTopicsToPublishTo;

  /**
   * Assert that a client connected to the Cloud Pub/Sub emulator by inspecting the emulator logs.
   *
   * @param cloudPubSubLogContents The contents of the Cloud Pub/Sub emulator logs
   */
  protected void assertCloudPubSubClientConnected(String cloudPubSubLogContents) {
    assertThat(cloudPubSubLogContents).isNotBlank();
    assertThat(cloudPubSubLogContents).contains("Detected HTTP/2 connection");
  }

  /**
   * Assert that an MQTT client connected to the MQTT broker by inspecting the MQTT broker logs.
   *
   * @param mqttBrokerLogContents The contents of the MQTT broker logs
   * @param mqttClientId The ID of the MQTT client that connected to the MQTT broker
   */
  protected void assertMqttClientConnected(String mqttBrokerLogContents, String mqttClientId) {
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
  protected void assertMqttClientDisconnected(String mqttBrokerLogContents, String mqttClientId) {
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
  protected void assertMqttClientPublishedMessage(
      String mqttBrokerLogContents, String mqttClientId, String mqttTopicName) {
    assertThat(mqttBrokerLogContents).isNotBlank();
    assertThat(mqttClientId).isNotBlank();
    assertThat(mqttTopicName).isNotBlank();

    assertThat(mqttBrokerLogContents)
        .containsPattern(
            "Received PUBLISH from "
                + mqttClientId
                + " \\(([a-z][0-9], ){4}'"
                + Pattern.quote(mqttTopicName));
  }

  /**
   * Assert that an MQTT client subscribed to a MQTT topic by inspecting the MQTT broker logs.
   *
   * @param mqttBrokerLogContents The contents of the MQTT broker logs
   * @param mqttClientId The ID of the MQTT client that subscribed to the topic
   * @param mqttTopicName The name of the MQTT topic
   */
  protected void assertMqttClientSubscribedToTopic(
      String mqttBrokerLogContents, String mqttClientId, String mqttTopicName) {
    assertThat(mqttBrokerLogContents).isNotBlank();
    assertThat(mqttClientId).isNotBlank();
    assertThat(mqttTopicName).isNotBlank();

    assertThat(mqttBrokerLogContents)
        .containsPattern("Received SUBSCRIBE from " + mqttClientId + "\n[0-9]*:\\s*");
  }

  /**
   * Generate a List of MQTT topics from a CSV String (likely from a property or a property file).
   *
   * @param mqttTopicsToPublishTo CSV list of MQTT topics
   * @return a List of MQTT topics
   */
  protected List<String> generateMqttTopics(String mqttTopicsToPublishTo) {
    assertThat(mqttTopicsToPublishTo).isNotBlank();

    List<String> processedMqttTopicsToPublishTo =
        Stream.of(mqttTopicsToPublishTo.split(",", -1)).collect(Collectors.toList());

    assertThat(processedMqttTopicsToPublishTo).isNotEmpty();

    return processedMqttTopicsToPublishTo;
  }

  protected void sendMqttMessage(
      ProducerTemplate producerTemplate, String mqttEndpointUrl, String mqttMessageBody) {
    assertThat(producerTemplate).isNotNull();
    assertThat(mqttEndpointUrl).isNotBlank();
    assertThat(mqttMessageBody).isNotBlank();
    LOG.infof(
        "Sending MQTT message (payload: %s) to %s endpoint", mqttMessageBody, mqttEndpointUrl);
    producerTemplate.sendBody(mqttEndpointUrl, mqttMessageBody);
  }

  @Test
  public void testRouteUnsecuredMqttMessageToCloudPubSub() {
    // Set a MQTT client ID that we use in this test to check a few things, such as
    // if the client actually connected to the MQTT broker
    String testMqttClientId =
        MqttToCloudPubSubRoute.MQTT_CLIENT_ID_PREFIX + "test-client-" + UUID.randomUUID();

    assertThat(mqttBrokerContainer).isNotNull();

    List<String> processedMqttTopicsToPublishTo = generateMqttTopics(mqttTopicsToPublishTo);
    int expectedMqttMessagesCount = processedMqttTopicsToPublishTo.size();
    assertThat(expectedMqttMessagesCount).isGreaterThan(0);

    // To proceed only when messages are successfully processed
    NotifyBuilder notifyBuilder =
        new NotifyBuilder(camelContext).whenCompleted(expectedMqttMessagesCount).create();

    String messageBodyPrefix = "test-message-body-";
    ProducerTemplate producerTemplate = camelContext.createProducerTemplate();
    // Send messages to MQTT topics
    for (String processedMqttTopic : processedMqttTopicsToPublishTo) {
      // Build the Apache Camel component endpoint URL to connect to the containerized
      // MQTT broker. We call this the "test MQTT client".
      // We need one endpoint URL for each MQTT topic to send messages to
      String mqttEndpointUrl =
          "paho-mqtt5:" + processedMqttTopic + "?" + "clientId=" + testMqttClientId;
      LOG.infof("Sending a MQTT message to %s endpoint", mqttEndpointUrl);

      // Publish a message in a MQTT topic using the test MQTT client
      String messageBody = messageBodyPrefix + processedMqttTopic;
      sendMqttMessage(producerTemplate, mqttEndpointUrl, messageBody);
    }

    // Stop the producer because we don't need to send further messages
    LOG.infof("Stopping the producer template...");
    producerTemplate.stop();

    // Check that the conditions we set for the test case are verified
    assertThat(notifyBuilder.matches());

    String cloudPubSubEndpointUrl =
        "google-pubsub:"
            + cloudPubSubProjectId
            + ":"
            + cloudPubSubDestinationTopicSubscriptionName
            + "?"
            + "synchronousPull=true";
    LOG.infof("Setting the Cloud Pub/Sub endpoint URL to: %s", cloudPubSubEndpointUrl);

    // No need to create multiple consumers because if we want to receive from multiple MQTT
    // topics, we can use a MQTT wildcard topic subscription
    ConsumerTemplate consumerTemplate = camelContext.createConsumerTemplate();

    // Receive messages from the Cloud Pub/Sub emulator
    for (String processedMqttTopic : processedMqttTopicsToPublishTo) {
      LOG.infof("Receiving message from %s endpoint...", cloudPubSubEndpointUrl);
      Exchange exchange = consumerTemplate.receive(cloudPubSubEndpointUrl, 5000L);
      assertThat(exchange).isNotNull();
      Message receivedMessage = exchange.getMessage();
      String receivedMessageBody = receivedMessage.getBody(String.class);
      consumerTemplate.doneUoW(exchange);

      // Check that the test MQTT client published a message in the MQTT topic we
      // expect
      assertMqttClientPublishedMessage(
          mqttBrokerContainer.getLogs(), testMqttClientId, processedMqttTopic);

      String expectedMessageBody = messageBodyPrefix + processedMqttTopic;
      // Ensure that what we received is what we expect
      assertThat(expectedMessageBody).isEqualTo(receivedMessageBody);
    }

    // Stop the consumer template because we don't need to receive any new messages
    consumerTemplate.stop();

    // Check that the test MQTT clinet disconnected
    assertMqttClientDisconnected(mqttBrokerContainer.getLogs(), testMqttClientId);

    // Check that the Apache Camel route connected to the MQTT broker, and
    // subscribed to an MQTT topic.
    // We don't test the disconnection because Quarkus shuts down the route after
    // the test is completed.
    String mqttToCloudPubSubRouteClientId = mqttToCloudPubSubRoute.getFromSourceTopicMqttClientId();
    assertMqttClientConnected(mqttBrokerContainer.getLogs(), mqttToCloudPubSubRouteClientId);
    // We don't need to test multiple subscriptions because we use MQTT wildcards for that use case
    assertMqttClientSubscribedToTopic(
        mqttBrokerContainer.getLogs(), mqttToCloudPubSubRouteClientId, mqttTopic);

    // Assert that the Cloud Pub/Sub client that the route creates connected to
    // the Cloud Pub/Sub emulator
    assertCloudPubSubClientConnected(cloudPubsubContainer.getLogs());
  }
}
