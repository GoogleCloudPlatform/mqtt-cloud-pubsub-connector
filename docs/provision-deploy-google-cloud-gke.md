# Provision a test and validation runtime environment on Google Kubernetes Engine

To provision and configure an environment to perform testing and validation experiments
on Google Cloud, we provide the necessary infrastructure-as-code descriptors:

- `terraform`: This directory contains all the necessary [Terraform](https://www.terraform.io/)
    descriptors to provision the runtime environment in a
    [Google Cloud project](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy#projects).

To provision a test and validation runtime environment on Google Cloud, you need:

- A POSIX-compliant shell
- An OCI-compatible container runtime. Tested with Docker for Linux 20.10.21

To provision the resources for the testing and validation runtime environment, do the following:

1. Change your working directory to the root directory of this repository.
1. Run the cloud resources provisioning script:

    ```sh
    scripts/provision-cloud-infrastructure.sh
    ```

    The script guides you in providing the necessary configuration data.

## Necessary permissions to provision the environment in a new project

To provision the environment in a new project, you need to authenticate against
Google Cloud using an account that has the necessary permissions in your Google
Cloud Organization. For more information about the necessary roles and
permissions, refer to:

- [Creating a project](https://cloud.google.com/resource-manager/docs/creating-managing-projects#creating_a_project)
- [Enable billing for a project](https://cloud.google.com/billing/docs/how-to/modify-project#enable_billing_for_a_project)
- [Creating a Cloud Storage bucket](https://cloud.google.com/storage/docs/creating-buckets)
- The permissions listed [in the next section](#necessary-permissions-to-provision-the-environment-in-an-existing-project)

## Necessary permissions to provision the environment in an existing project

To provision the environment in an existing project, you need to authenticate
against Google Cloud using an account that has the necessary permissions in your
Google Cloud Organization:

- `roles/artifactregistry.admin` to create and manage repositories.
- `roles/compute.instanceAdmin.v1` to create and manage Compute Engine instances.
- `roles/compute.networkAdmin` to create and manage network resources, such as Cloud Routers and Cloud Firewall rules.
- `roles/container.admin` to create and manage GKE clusters.
- `roles/pubsub.admin` to create Cloud Pub/Sub subscriptions and topics, and to configure IAM.

For more information about the necessary roles and permissions, refer to:

- [Artifact Registry roles and permissions](https://cloud.google.com/artifact-registry/docs/access-control#permissions)
- [Compute Engine roles and permissions](https://cloud.google.com/compute/docs/access/iam)
- [GKE access control](https://cloud.google.com/kubernetes-engine/docs/concepts/access-control)
- [GKE IAM roles](https://cloud.google.com/kubernetes-engine/docs/how-to/iam#roles)
- [Cloud Pub/Sub IAM roles](https://cloud.google.com/pubsub/docs/access-control#roles)

## Deploy workloads

To deploy workloads in the GKE cluster, do the following:

1. Run the workload build script:

    ```sh
    scripts/build.sh
    ```

1. Run the workload deployment script:

    ```sh
    scripts/deploy-workloads.sh
    ```

### Necessary permissions to deploy workloads

To deploy workloads in the GKE cluster, you need the following, you need to
authenticate against Google Cloud using an account that has the necessary
permissions in your Google Cloud Organization:

- `roles/container.developer` to access Kubernetes APIs.

For more information about the necessary roles and permissions, refer to:

- [GKE access control](https://cloud.google.com/kubernetes-engine/docs/concepts/access-control)
- [GKE IAM rolese](https://cloud.google.com/kubernetes-engine/docs/how-to/iam#roles)

## Clean up

To delete all the resources and workloads in the environment, run the following command:

```sh
scripts/provision-cloud-infrastructure.sh --terraform-subcommand "destroy"
```
