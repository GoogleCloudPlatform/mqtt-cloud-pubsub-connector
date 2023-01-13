# Provision a test and validation runtime environment on Google Kubernetes Engine

To provision and configure an environment to perform testing and validation experiments
on Google Cloud, we provide the necessary infrastructure-as-code descriptors:

- `terraform`: This directory contains all the necessary [Terraform](https://www.terraform.io/)
    descriptors to provision the runtime environment in an existing
    [Google Cloud project](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy#projects).
- `terraform-init`: This directory contains all the necessary Terraform descriptors
    to provision a Google Cloud project and a Google Cloud Storage bucket to use as a
    remote [Terraform backend](https://developer.hashicorp.com/terraform/language/settings/backends/configuration).

To provision a test and validation runtime environment on Google Cloud, you need:

- A POSIX-compliant shell
- An OCI-compatible container runtime. Tested with Docker for Linux 20.10.21

To provision the resources for the testing and validation runtime environment, do the following:

1. Change your working directory to the root directory of this repository.
1. Provision the environment on Google Cloud by following either the [Provision the environment on Google Cloud in a new project](#provision-the-environment-on-google-cloud-in-a-new-project)
    section or the [Provision the environment on Google Cloud in an existing project](#provision-the-environment-on-google-cloud-in-an-existing-project) section.

## Provision the environment on Google Cloud in a new project

To provision all the Google Cloud resources for the testing and validation runtime environment, including a Google Cloud
project to create those resources into, and a Cloud Storage bucket to store Terraform backend data, do the following:

1. Run the cloud resources provisioning script:

    ```sh
    scripts/provision-cloud-infrastructure.sh
    ```

    The script guides you in providing the necessary configuration data.

## Provision the environment on Google Cloud in an existing project

If you provisioned the environment by following the guidance in [Provision the environment on Google Cloud in a new project](#provision-the-environment-on-google-cloud-in-a-new-project),
skip this section.

If you want to provision a test and validation runtime environment in an existing Google Cloud project, do the following:

1. Create a Google Cloud project.
1. Create a Cloud Storage bucket to store Terraform backend data.
1. Run the cloud resources provisioning script:

    ```sh
    scripts/provision-cloud-infrastructure.sh --no-provision-google-cloud-project
    ```

    The script guides you in providing the necessary configuration data.

## Deploy workloads

1. Run the workload build script:

    ```sh
    scripts/build.sh
    ```

1. Run the workload deployment script:

    ```sh
    scripts/deploy-workloads.sh
    ```

## Clean up

To delete all the resources and workloads in the environment, run the following command:

```sh
scripts/provision-cloud-infrastructure.sh --terraform-subcommand "destroy"
```
