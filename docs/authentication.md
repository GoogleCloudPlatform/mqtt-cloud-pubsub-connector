# MQTT <-> Cloud Pub/Sub Connector authentication

Each instance of the **MQTT <-> Cloud Pub/Sub Connector** needs to authenticate
against two systems:

- MQTT broker
- Cloud Pub/Sub

## Authenticate against MQTT brokers

(WIP, to update after we expose authentication configuration)

## Authenticate against Cloud Pub/Sub

The **MQTT <-> Cloud Pub/Sub Connector** uses
[Application Default Credentials](https://cloud.google.com/docs/authentication#adc) to authenticate
against Cloud Pub/Sub.

When deploying the connector on Google Kubernetes Engine, we recommend that you use
[Workload Identity](https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity)
to configure authentication. For an example of this approach, refer to the
[Provision a test and validation runtime environment on Google Cloud document](./provision-deploy-google-cloud-gke.md).

When deploying the connector on Google Compute Engine, you need to configure a service account
and attach it to a Google Compute Engine instance. For more information, refer to
[Google Cloud services that support attaching a service account](https://cloud.google.com/docs/authentication/provide-credentials-adc#attached-sa).
