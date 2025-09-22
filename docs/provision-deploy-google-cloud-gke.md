# Provision a test and validation runtime environment on Google Kubernetes Engine

To provision and configure an environment to perform testing and validation
experiments on Google Cloud, we provide the necessary infrastructure-as-code
descriptors:

- `terraform`: This directory contains all the necessary
  [Terraform](https://www.terraform.io/) descriptors to provision the runtime
  environment in an existing
  [Google Cloud project](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy#projects).
- `terraform-init`: This directory contains all the necessary Terraform
  descriptors to provision a Google Cloud project and a Google Cloud Storage
  bucket to use as a remote
  [Terraform backend](https://developer.hashicorp.com/terraform/language/settings/backends/configuration).

To provision a test and validation runtime environment on Google Cloud, you
need:

- A POSIX-compliant shell
- An OCI-compatible container runtime. Tested with Docker for Linux 20.10.21

To provision the resources for the testing and validation runtime environment,
do the following:

1.  Change your working directory to the root directory of this repository.
1.  Provision the environment on Google Cloud by following either the
    [Provision the environment on Google Cloud in a new project](#provision-the-environment-on-google-cloud-in-a-new-project)
    section or the
    [Provision the environment on Google Cloud in an existing project](#provision-the-environment-on-google-cloud-in-an-existing-project)
    section.

## Provision the environment on Google Cloud in a new project

To provision all the Google Cloud resources for the testing and validation
runtime environment, including a Google Cloud project to create those resources
into, and a Cloud Storage bucket to store Terraform backend data, do the
following:

1.  Run the cloud resources provisioning script:

    ```sh
    scripts/provision-cloud-infrastructure.sh
    ```

    The script guides you in providing the necessary configuration data.

### Necessary permissions to provision the environment in a new project

To provision the environment in a new project, you need to authenticate against
Google Cloud using an account that has the necessary permissions in your Google
Cloud Organization. For more information about the necessary roles and
permissions, refer to:

- [Creating a project](https://cloud.google.com/resource-manager/docs/creating-managing-projects#creating_a_project)
- [Enable billing for a project](https://cloud.google.com/billing/docs/how-to/modify-project#enable_billing_for_a_project)
- [Creating a Cloud Storage bucket](https://cloud.google.com/storage/docs/creating-buckets)
- The permissions listed
  [in the next section](#necessary-permissions-to-provision-the-environment-in-an-existing-project)

## Provision the environment on Google Cloud in an existing project

If you provisioned the environment by following the guidance in
[Provision the environment on Google Cloud in a new project](#provision-the-environment-on-google-cloud-in-a-new-project),
skip this section.

If you want to provision a test and validation runtime environment in an
existing Google Cloud project, do the following:

1.  Create a Google Cloud project.
1.  Create a Cloud Storage bucket to store Terraform backend data.
1.  Run the cloud resources provisioning script:

    ```sh
    scripts/provision-cloud-infrastructure.sh --no-provision-google-cloud-project
    ```

    The script guides you in providing the necessary configuration data.

### Necessary permissions to provision the environment in an existing project

To provision the environment in an existing project, you need to authenticate
against Google Cloud using an account that has the necessary permissions in your
Google Cloud Organization:

- `roles/artifactregistry.admin` to create and manage repositories.
- `roles/compute.instanceAdmin.v1` to create and manage Compute Engine
  instances.
- `roles/compute.networkAdmin` to create and manage network resources, such as
  Cloud Routers and Cloud Firewall rules.
- `roles/container.admin` to create and manage GKE clusters.
- `roles/pubsub.admin` to create Cloud Pub/Sub subscriptions and topics, and to
  configure IAM.

For more information about the necessary roles and permissions, refer to:

- [Artifact Registry roles and permissions](https://cloud.google.com/artifact-registry/docs/access-control#permissions)
- [Compute Engine roles and permissions](https://cloud.google.com/compute/docs/access/iam)
- [GKE access control](https://cloud.google.com/kubernetes-engine/docs/concepts/access-control)
- [GKE IAM roles](https://cloud.google.com/kubernetes-engine/docs/how-to/iam#roles)
- [Cloud Pub/Sub IAM roles](https://cloud.google.com/pubsub/docs/access-control#roles)

## Deploy workloads

To deploy workloads in the GKE cluster, do the following:

1.  Run the workload build script:

    ```sh
    scripts/build.sh
    ```

1.  Run the workload deployment script:

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

To delete all the resources and workloads in the environment, run the following
command:

```sh
scripts/provision-cloud-infrastructure.sh --terraform-subcommand "destroy"
```
