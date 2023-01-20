/*
 * Copyright 2023 Google LLC
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

package com.google.cloud.solutions.profiles;

import com.google.cloud.solutions.routes.MqttToCloudPubSubRoute;
import io.quarkus.test.junit.QuarkusTestProfile;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

/**
 * This class provides the base to implement a test profile to dynamically inject configuration
 * values in the test, instead of relying on static property files.
 *
 * <p>Tests activating profiles based on this one aren't required to perform any validation on the
 * structure of the MQTT subscription. This is a task for the MQTT broker.
 *
 * <p>The configuration options added here are merged with the ones coming from other configuration
 * sources that Quarkus considers.
 */
public abstract class AbstractTestProfile implements QuarkusTestProfile {

  public static final String MQTT_TOPICS_TO_PUBLISH_TO_PROPERTY_KEY =
      "com.google.cloud.solutions.mqtt-client.mqtt-topics-to-publish-to";

  /**
   * Get the MQTT topic name to subscribe to.
   *
   * @return the MQTT topic name to subscribe to
   */
  abstract String getMqttTopicName();

  /**
   * Get the comma-separated MQTT topic list to publish messages to.
   *
   * @return the MQTT topic name to subscribe to
   */
  abstract String getMqttTopicsToPublishTo();

  @Override
  public Map<String, String> getConfigOverrides() {
    Map<String, String> properties = new HashMap<>();
    properties.put(MqttToCloudPubSubRoute.MQTT_TOPIC_PROPERTY_KEY, getMqttTopicName());
    properties.put(MQTT_TOPICS_TO_PUBLISH_TO_PROPERTY_KEY, getMqttTopicsToPublishTo());

    return Collections.unmodifiableMap(properties);
  }
}
