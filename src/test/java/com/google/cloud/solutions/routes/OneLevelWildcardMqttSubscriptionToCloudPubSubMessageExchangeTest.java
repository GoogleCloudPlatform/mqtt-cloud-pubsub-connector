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

import com.google.cloud.solutions.profiles.OneLevelWildcardMqttSubscriptionProfile;
import com.google.cloud.solutions.resources.AbstractContainerResource;
import com.google.cloud.solutions.resources.CloudPubSubResource;
import com.google.cloud.solutions.resources.MqttBrokerResource;
import io.quarkus.test.common.QuarkusTestResource;
import io.quarkus.test.common.ResourceArg;
import io.quarkus.test.junit.QuarkusTest;
import io.quarkus.test.junit.TestProfile;

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
@TestProfile(OneLevelWildcardMqttSubscriptionProfile.class)
public class OneLevelWildcardMqttSubscriptionToCloudPubSubMessageExchangeTest
    extends AbstractMqttToCloudPubSubMessageExchangeTest {}
