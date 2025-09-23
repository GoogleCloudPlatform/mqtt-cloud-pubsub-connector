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

/**
 * This class provides the configuration values to run a test that maps a single MQTT with a Cloud
 * Pub/Sub topic.
 */
public class SingleMqttTopicNameProfile extends AbstractMqttToCloudPubSubTest {

  @Override
  public String getConfigProfile() {
    return "single-mqtt-topic-profile";
  }

  @Override
  String getMqttTopicsToPublishTo() {
    return getMqttTopicName();
  }

  @Override
  String getMqttTopicName() {
    return "single-mqtt-test-topic";
  }
}
