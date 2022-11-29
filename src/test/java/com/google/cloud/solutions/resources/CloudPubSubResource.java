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

import com.google.api.gax.core.CredentialsProvider;
import com.google.api.gax.core.NoCredentialsProvider;
import com.google.api.gax.grpc.GrpcTransportChannel;
import com.google.api.gax.rpc.FixedTransportChannelProvider;
import com.google.cloud.pubsub.v1.SubscriptionAdminClient;
import com.google.cloud.pubsub.v1.SubscriptionAdminSettings;
import com.google.cloud.pubsub.v1.TopicAdminClient;
import com.google.cloud.pubsub.v1.TopicAdminSettings;
import com.google.cloud.solutions.routes.MqttToCloudPubSubRoute;
import com.google.pubsub.v1.ProjectSubscriptionName;
import com.google.pubsub.v1.Subscription;
import com.google.pubsub.v1.Topic;
import com.google.pubsub.v1.TopicName;
import io.grpc.ManagedChannel;
import io.grpc.ManagedChannelBuilder;
import java.io.IOException;
import java.lang.annotation.Annotation;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import org.eclipse.microprofile.config.ConfigProvider;
import org.jboss.logging.Logger;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.wait.strategy.Wait;

public class CloudPubSubResource extends AbstractContainerResource {

  private static final Logger LOG = Logger.getLogger(CloudPubSubResource.class);

  public static final String CLOUD_PUB_SUB_CONTAINER_TCP_PORT_PROPERTY_KEY =
      "com.google.cloud.solutions.mqtt-client.cloud-pubsub-container-tcp-port-number";
  public static final String CLOUD_PUB_SUB_DESTINATION_TOPIC_SUBSCRIPTION_NAME_PROPERTY_KEY =
      "com.google.cloud.solutions.mqtt-client.cloud-pubsub-destination-topic-subscription-name";
  public static final String CLOUD_PUB_SUB_ENDPOINT_PROPERTY_KEY =
      "camel.component.google-pubsub.endpoint";

  private Topic destinationTopic;
  private Subscription destinationTopicSubscription;

  private String cloudPubSubDestinationTopicName;
  private String cloudPubSubProjectId;
  private String cloudPubSubDestinationTopicSubscriptionName;

  private Integer cloudPubsubTcpPort;
  private Integer cloudPubSubTcpMappedPort;

  private SubscriptionAdminClient subscriptionAdminClient;
  private TopicAdminClient topicAdminClient;

  @Override
  protected Map<String, String> buildAdditionalConfigurationProperties() {
    cloudPubSubTcpMappedPort = this.getContainer().getMappedPort(cloudPubsubTcpPort);
    final String cloudPubSubEndpoint = containerHostname + ":" + cloudPubSubTcpMappedPort;

    return Map.ofEntries(entry(CLOUD_PUB_SUB_ENDPOINT_PROPERTY_KEY, cloudPubSubEndpoint));
  }

  @Override
  protected GenericContainer<?> configureContainer(GenericContainer<?> container) {
    cloudPubsubTcpPort =
        ConfigProvider.getConfig()
            .getValue(CLOUD_PUB_SUB_CONTAINER_TCP_PORT_PROPERTY_KEY, Integer.class);
    cloudPubSubDestinationTopicName =
        ConfigProvider.getConfig()
            .getValue(
                MqttToCloudPubSubRoute.CLOUD_PUB_SUB_DESTINATION_TOPIC_NAME_PROPERTY_KEY,
                String.class);
    cloudPubSubProjectId =
        ConfigProvider.getConfig()
            .getValue(MqttToCloudPubSubRoute.CLOUD_PUB_SUB_PROJECT_ID_PROPERTY_KEY, String.class);
    cloudPubSubDestinationTopicSubscriptionName =
        ConfigProvider.getConfig()
            .getValue(
                CloudPubSubResource.CLOUD_PUB_SUB_DESTINATION_TOPIC_SUBSCRIPTION_NAME_PROPERTY_KEY,
                String.class);

    // Setting the host port to listen on all interfaces because it listens on
    // localhost only by default
    container
        .withCommand("gcloud beta emulators pubsub start --host-port=0.0.0.0:" + cloudPubsubTcpPort)
        .withExposedPorts(cloudPubsubTcpPort)
        .waitingFor(Wait.forLogMessage(".* This is the Google Pub/Sub fake.*", 1))
        .waitingFor(
            Wait.forLogMessage(".* Server started, listening on " + cloudPubsubTcpPort + ".*", 1))
        .waitingFor(Wait.forListeningPort());

    return container;
  }

  private FixedTransportChannelProvider createChannelProvider() {
    ManagedChannel channel =
        ManagedChannelBuilder.forTarget(
                String.format("%s:%s", containerHostname, cloudPubSubTcpMappedPort))
            .usePlaintext()
            .build();

    return FixedTransportChannelProvider.create(GrpcTransportChannel.create(channel));
  }

  private Subscription createSubscription(
      SubscriptionAdminClient subscriptionClient,
      Topic topic,
      String subscriptionName,
      String projectId) {
    LOG.infof(
        "Creating %s Cloud Pub/Sub subscription in project %s for %s topic...",
        subscriptionName, projectId, topic.getName());
    ProjectSubscriptionName projectSubscriptionName =
        ProjectSubscriptionName.of(projectId, subscriptionName);
    Subscription.Builder subscriptionBuilder =
        Subscription.newBuilder()
            .setName(projectSubscriptionName.toString())
            .setTopic(topic.getName())
            .setAckDeadlineSeconds(10);

    return subscriptionClient.createSubscription(subscriptionBuilder.build());
  }

  private SubscriptionAdminClient createSubscriptionAdminClient() {
    LOG.info("Creating Cloud Pub/Sub subscription admin client...");
    FixedTransportChannelProvider channelProvider = createChannelProvider();
    CredentialsProvider credentialsProvider = NoCredentialsProvider.create();

    try {
      return SubscriptionAdminClient.create(
          SubscriptionAdminSettings.newBuilder()
              .setTransportChannelProvider(channelProvider)
              .setCredentialsProvider(credentialsProvider)
              .build());
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
  }

  private Topic createTopic(TopicAdminClient topicClient, String topicName, String projectId) {
    LOG.infof("Creating %s Cloud Pub/Sub topic in project %s...", topicName, projectId);
    Topic topic = Topic.newBuilder().setName(TopicName.of(projectId, topicName).toString()).build();
    return topicClient.createTopic(topic);
  }

  private TopicAdminClient createTopicAdminClient() {
    LOG.info("Creating Cloud Pub/Sub topic admin client...");
    FixedTransportChannelProvider channelProvider = createChannelProvider();
    CredentialsProvider credentialsProvider = NoCredentialsProvider.create();

    try {
      return TopicAdminClient.create(
          TopicAdminSettings.newBuilder()
              .setTransportChannelProvider(channelProvider)
              .setCredentialsProvider(credentialsProvider)
              .build());
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
  }

  @Override
  protected Class<? extends Annotation> getContainerInjectionAnnotationClass() {
    return InjectCloudPubSubContainer.class;
  }

  @Override
  public Map<String, String> start() {
    Map<String, String> configurationProperties = super.start();

    // We need to create this topic manually when using the emulator.
    // We assume that this task will be handled by external tooling when pointing to
    // a real Cloud Pub/Sub instance
    topicAdminClient = createTopicAdminClient();
    destinationTopic =
        createTopic(topicAdminClient, cloudPubSubDestinationTopicName, cloudPubSubProjectId);

    // We use this subscription to verify that the route is correctly forwarding
    // messages to Cloud Pub/Sub
    subscriptionAdminClient = createSubscriptionAdminClient();
    destinationTopicSubscription =
        createSubscription(
            subscriptionAdminClient,
            destinationTopic,
            cloudPubSubDestinationTopicSubscriptionName,
            cloudPubSubProjectId);

    return configurationProperties;
  }

  @Override
  public void stop() {
    subscriptionAdminClient.deleteSubscription(destinationTopicSubscription.getName());
    topicAdminClient.deleteTopic(destinationTopic.getName());

    topicAdminClient.shutdown();
    subscriptionAdminClient.shutdown();

    try {
      topicAdminClient.awaitTermination(5, TimeUnit.SECONDS);
      subscriptionAdminClient.awaitTermination(5, TimeUnit.SECONDS);
    } catch (InterruptedException e) {
      throw new RuntimeException(e);
    }
    super.stop();
  }
}
