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

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import javax.enterprise.context.ApplicationScoped;
import javax.inject.Inject;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.component.google.pubsub.GooglePubsubConstants;
import org.apache.camel.component.paho.mqtt5.PahoMqtt5Constants;
import org.apache.camel.spi.SupervisingRouteController;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

@ApplicationScoped
public class MqttToCloudPubSubRoute extends RouteBuilder {

  private static final Logger LOG = Logger.getLogger(MqttToCloudPubSubRoute.class);

  public static final String CLOUD_PUB_SUB_PROJECT_ID_PROPERTY_KEY =
      "com.google.cloud.solutions.mqtt-client.cloud-pubsub-project-id";
  public static final String CLOUD_PUB_SUB_DESTINATION_TOPIC_NAME_PROPERTY_KEY =
      "com.google.cloud.solutions.mqtt-client.cloud-pubsub-destination-topic-name";
  public static final String MQTT_TOPIC_PROPERTY_KEY =
      "com.google.cloud.solutions.mqtt-client.mqtt-topic";

  public static final String MQTT_CLIENT_ID_PREFIX = "camel-paho-";
  public static final String MQTT_CLIENT_ID_FROM_SOURCE_TOPIC_PREFIX = "from-source-topic-";
  public static final String MQTT_TO_CLOUD_PUB_SUB_ROUTE_ID_PREFIX = "mqtt-to-cloud-pubsub-route-";

  public static final String SOURCE_MQTT_TOPIC_HEADER_NAME = "source-mqtt-topic-name";

  @ConfigProperty(name = CLOUD_PUB_SUB_PROJECT_ID_PROPERTY_KEY)
  @Inject
  String cloudPubSubProjectId;

  @ConfigProperty(name = CLOUD_PUB_SUB_DESTINATION_TOPIC_NAME_PROPERTY_KEY)
  @Inject
  String cloudPubSubDestinationTopicName;

  private String mqttFromSourceTopicClientId;

  private String mqttToCloudPubSubRouteId;

  @ConfigProperty(name = MQTT_TOPIC_PROPERTY_KEY)
  @Inject
  String mqttSourceTopic;

  public MqttToCloudPubSubRoute() {
    UUID uuid = UUID.randomUUID();
    mqttFromSourceTopicClientId =
        MQTT_CLIENT_ID_PREFIX + MQTT_CLIENT_ID_FROM_SOURCE_TOPIC_PREFIX + uuid;
    mqttToCloudPubSubRouteId = MQTT_TO_CLOUD_PUB_SUB_ROUTE_ID_PREFIX + uuid;
  }

  @Override
  public void configure() throws Exception {
    SupervisingRouteController supervising = getCamelContext().getRouteController().supervising();
    supervising.setBackOffDelay(200);
    supervising.setIncludeRoutes("paho-mqtt5:*");

    // Configure the client id as an endpoint parameter instead of using a component
    // parameter (and the corresponding property)
    // so that we can have each client connecting with its own (dynamically
    // generated) unique client id. See
    // https://camel.apache.org/components/3.18.x/paho-mqtt5-component.html for
    // details about the configuration options
    String routeStart =
        "paho-mqtt5:" + mqttSourceTopic + "?" + "clientId=" + mqttFromSourceTopicClientId;

    String routeDestination =
        "google-pubsub:" + cloudPubSubProjectId + ":" + cloudPubSubDestinationTopicName;

    LOG.infof("Apache Camel route start: %s", routeStart);
    LOG.infof("Apache Camel route destination: %s", routeDestination);

    from(routeStart)
        .id(mqttToCloudPubSubRouteId)
        .process(
            exchange -> {
              String mqttTopic =
                  exchange.getIn().getHeader(PahoMqtt5Constants.MQTT_TOPIC, String.class);
              Map<String, String> headers = new HashMap<>();
              headers.put(SOURCE_MQTT_TOPIC_HEADER_NAME, mqttTopic);
              exchange.getIn().setHeader(GooglePubsubConstants.ATTRIBUTES, headers);
            })
        .to(routeDestination);
  }

  public String getFromSourceTopicMqttClientId() {
    return mqttFromSourceTopicClientId;
  }

  public String getMqttToCloudPubSubRouteId() {
    return mqttToCloudPubSubRouteId;
  }
}
