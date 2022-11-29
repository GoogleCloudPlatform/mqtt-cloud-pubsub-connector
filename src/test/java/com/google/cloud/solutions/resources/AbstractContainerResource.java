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

import static org.assertj.core.api.Assertions.assertThat;

import io.quarkus.test.common.QuarkusTestResourceLifecycleManager;
import io.smallrye.config.PropertiesConfigSource;
import java.io.IOException;
import java.lang.annotation.Annotation;
import java.net.URL;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import org.eclipse.microprofile.config.ConfigProvider;
import org.eclipse.microprofile.config.spi.ConfigBuilder;
import org.eclipse.microprofile.config.spi.ConfigProviderResolver;
import org.jboss.logging.Logger;
import org.slf4j.LoggerFactory;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.output.Slf4jLogConsumer;
import org.testcontainers.junit.jupiter.Container;

public abstract class AbstractContainerResource implements QuarkusTestResourceLifecycleManager {

  public static final String CONTAINER_IMAGE_PROPERTY_KEY = "containerImage";

  private static ConfigProviderResolver configProviderResolver = ConfigProviderResolver.instance();
  private static final Logger LOG = Logger.getLogger(AbstractContainerResource.class);

  private String containerImageId;

  // Parametrizing this with <?> (reminder: <?> means unknown type)
  // to avoid https://github.com/testcontainers/testcontainers-java/issues/238
  @Container private GenericContainer<?> container;

  // Subclasses may need this to parametrize endpoints
  protected String containerHostname;

  /**
   * Build the properties map to return from by the start method, eventually added to the properties
   * that are common for all concrete implementations.
   *
   * @return the Map of properties to return
   */
  protected abstract Map<String, String> buildAdditionalConfigurationProperties();

  /**
   * Configure the {@link org.testcontainers.containers.GenericContainer GenericContainer} to start.
   *
   * @param container The container to customize
   * @return the GenericContainer that the lifecycle manager will start
   */
  protected abstract GenericContainer<?> configureContainer(GenericContainer<?> container);

  /**
   * Get the class of the {@link java.lang.annotation.Annotation Annotation} used to mark fields to
   * inject the {@link org.testcontainers.containers.GenericContainer GenericContainer} object
   *
   * @return a {@link java.lang.Class Class} object representing the Annotation
   */
  protected abstract Class<? extends Annotation> getContainerInjectionAnnotationClass();

  @Override
  public void init(Map<String, String> initArgs) {
    // Manually initialize a property source that reads application.properties
    // because Quarkus doesn't support doing this automatically in classes that
    // implement QuarkusTestResourceLifecycleManager
    LOG.info("Initializing the property source...");
    ConfigBuilder configBuilder = configProviderResolver.getBuilder();
    Enumeration<URL> propertyFiles = null;
    ClassLoader classLoader = AbstractContainerResource.class.getClassLoader();
    try {
      propertyFiles = classLoader.getResources("application.properties");
      Set<PropertiesConfigSource> propertyConfigSources = new HashSet<>();
      while (propertyFiles != null && propertyFiles.hasMoreElements()) {
        URL propertyFile = propertyFiles.nextElement();
        propertyConfigSources.add(new PropertiesConfigSource(propertyFile));
      }
      configBuilder.withSources(propertyConfigSources.toArray(new PropertiesConfigSource[0]));
    } catch (IOException e) {
      LOG.errorv(e, "Cannot add property file as a configuration source");
      e.printStackTrace();
    }

    try {
      configProviderResolver.registerConfig(configBuilder.build(), classLoader);
    } catch (IllegalStateException e) {
      LOG.infof(
          "There's already a configuration source registered for the %s class loader. Skipping property source registration.",
          classLoader.getName());
    }

    // Manually fetch properties because configuration injection is not yet
    // available when building Quarkus test resources
    String containerImageIdPropertyID = initArgs.get(CONTAINER_IMAGE_PROPERTY_KEY);
    containerImageId =
        ConfigProvider.getConfig().getValue(containerImageIdPropertyID, String.class);
    assertThat(containerImageId).isNotBlank();

    // Create the container and customize its configuration
    LOG.infof("Creating a container based on the %s container image.", containerImageId);
    container = new GenericContainer<>(containerImageId);
    LOG.infof(
        "Configuring the container based on the %s container image before starting it.",
        containerImageId);
    container = configureContainer(container);
  }

  @Override
  public void inject(TestInjector testInjector) {
    testInjector.injectIntoFields(
        container,
        new TestInjector.AnnotatedAndMatchesType(
            getContainerInjectionAnnotationClass(), GenericContainer.class));
  }

  @Override
  public Map<String, String> start() {
    container.start();

    // This logger's only purpose is to consume logs coming from containers using
    // the Slf4jLogConsumer
    org.slf4j.Logger slf4jLogger = LoggerFactory.getLogger(AbstractContainerResource.class);
    // Add a log consumer to the Testcontainers container as to have the logs from
    // the MQTT container output to the test logger.
    final Slf4jLogConsumer containerLogConsumer =
        new Slf4jLogConsumer(slf4jLogger).withSeparateOutputStreams();
    container.followOutput(containerLogConsumer);

    // This may not be localhost, so we need to get it from the container runtime
    containerHostname = container.getHost();
    Map<String, String> configurationProperties = new HashMap<>();
    LOG.infof("Container hostname: %s", containerHostname);

    // Add additional properties
    configurationProperties.putAll(buildAdditionalConfigurationProperties());

    return configurationProperties;
  }

  @Override
  public void stop() {
    if (container != null) {
      container.stop();
    }
  }

  public GenericContainer<?> getContainer() {
    return container;
  }

  public String getContainerImageId() {
    return containerImageId;
  }

  public void setContainer(GenericContainer<?> container) {
    this.container = container;
  }

  public void setContainerImageId(String containerImageId) {
    this.containerImageId = containerImageId;
  }
}
