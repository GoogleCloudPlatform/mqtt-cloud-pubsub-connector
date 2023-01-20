# MQTT <-> Cloud Pub/Sub Connector configuration

To configure the MQTT <-> Cloud Pub/Sub Connector, you need to provide the necessary configuration
to:

- Connect to and authenticate against the MQTT broker
- Connect to and authenticate against Cloud Pub/Sub
- Map MQTT topics to Cloud Pub/Sub topics

The MQTT <-> Cloud Pub/Sub Connector configuration reads two property files to configure the
connection to MQTT brokers and Cloud Pub/Sub:

- `application.properties`
- `application-prod.properties`

Both files must be available in a `config` directory in the runtime environment. For example, if you
deploy the MQTT <-> Cloud Pub/Sub Connector in the `/app` directory, you need to create the property
files in the `/app/config` directory.

Having two files allows you to split the configuration. For example, you may use
`application.properties` for environment-independent configuration settings, and
`application-prod.properties` for environment-dependent configuration settings. The
[deploy-workloads.sh script](../scripts/deploy-workloads.sh) contains an example of this approach.

For more information about how to configure authentication against MQTT brokers and Cloud Pub/Sub,
refer to [MQTT <-> Cloud Pub/Sub Connector authentication](./authentication.md).

## Configure connections to MQTT brokers

To configure a connection to an MQTT broker, provide the following options:

```java
camel.component.paho-mqtt5.broker-url=tcp://<broker-hostname>:<broker-port-number>
```

Where:

- `<broker-hostname>` is the hostname or fully qualified name of the MQTT broker to connect to.
- `<broker-port-number>` is the port number where the MQTT broker is listening for connections.

## Configure connections to Cloud Pub/Sub

To configure the connection to Cloud Pub/Sub, provide the following options:

```java
com.google.cloud.solutions.mqtt-client.cloud-pubsub-project-id=<cloud-pubsub-project-id>
```

Where:

- `<cloud-pubsub-project-id>` is the Google Cloud project ID where you provisioned the Cloud Pub/Sub
    instance to connect to.

## Map a MQTT topic to a Cloud Pub/Sub topic

To map a MQTT topic to a Cloud Pub/Sub topic, provide the following options:

```java
com.google.cloud.solutions.mqtt-client.mqtt-topic=<source-mqtt-topic>
com.google.cloud.solutions.mqtt-client.cloud-pubsub-destination-topic-name=<destination-cloud-pubsub-topic>
```

Where:

- `<source-mqtt-topic>` is the source MQTT topic. The MQTT <-> Cloud Pub/Sub Connector will forward
    messages sent to this MQTT topic to Cloud Pub/Sub.
- `<destination-cloud-pubsub-topic>` is the destination Cloud Pub/Sub topic. The Connector will
    forward MQTT messages to this topic.

### Map multiple MQTT topics to a Cloud Pub/Sub topic

The `<source-mqtt-topic>` configuration option supports
[wildcard MQTT subscriptions](https://docs.oasis-open.org/mqtt/mqtt/v5.0/os/mqtt-v5.0-os.html#_Toc3901242).
By setting it a wildcard MQTT subscription, you can forward MQTT messages sent to the MQTT topics
that match with the wildcard subscription to the Cloud Pub/Sub topic that you configured with the
`<destination-cloud-pubsub-topic>` option, as described above.

## Other configuration options

Part of the MQTT <-> Cloud Pub/Sub Connector uses Apache Camel, but not all Apache Camel
configuration options are supported. We performed some limited testing of the following options:

- `camel.component.paho-mqtt5.lazy-start-producer`

For more information about these options, refer to:

- [Apache Camel Paho MQTT 5 component](https://camel.apache.org/components/latest/paho-mqtt5-component.html)
- [Apache Camel Google Cloud Pub/Sub component](https://camel.apache.org/components/latest/google-pubsub-component.html)
