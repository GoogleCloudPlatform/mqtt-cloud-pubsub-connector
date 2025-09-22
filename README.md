# MQTT <-> Cloud Pub/Sub connector

The **MQTT <-> Cloud Pub/Sub connector** is a set of software components aimed
at interfacing [MQTT](https://mqtt.org/) brokers and clients with
[Cloud Pub/Sub](https://cloud.google.com/pubsub).

This is not an official Google product.

## Assumptions

The MQTT <-> Cloud Pub/Sub connector works under the following assumptions:

- It currently supports forwarding messages from MQTT topics to Cloud Pub/Sub
  topics. Support for the other way around may come in a future release,
  depending on demand.
- It doesn't map any MQTT semantics to Cloud Pub/Sub semantics, and vice versa.
- It doesn't support any kind of message processing. If you need any processing,
  you need to implement a message processing pipeline.
- It's not a MQTT broker.
- It expects that you provisioned and configured the MQTT broker to connect to,
  and the necessary Cloud Pub/Sub topics and subscriptions.
- It doesn't map MQTT client identities to Google Cloud identities.

## Design and architecture

For more information about the design and the architecture of the MQTT <-> Cloud
Pub/Sub connector, refer to the following documents:

- [Overall design](docs/design.md)
- [Development environment guide](docs/development-environment.md)
- [Build and release processes](docs/build-release-processes.md)
- [Authentication](docs/authentication.md)
- [Configuration](docs/configuration.md)

## Provision a test and validation runtime environment on Google Cloud

For more information about provisioning and configuring a test and validation
runtime environment on Google Cloud, see
[Provision a test and validation runtime environment on Google Cloud document](docs/provision-deploy-google-cloud-gke.md).

## Contribute to this project

For more information about how to contribute to this project, refer to
[CONTRIBUTING](CONTRIBUTING.md).
