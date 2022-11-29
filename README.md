# MQTT <-> Cloud Pub/Sub connector

The **MQTT <-> Cloud Pub/Sub connector** is a set of software components aimed
at interfacing [MQTT](https://mqtt.org/) brokers and clients with
[Cloud Pub/Sub](https://cloud.google.com/pubsub).

## Development environment

To setup a development environment, we designed a [Visual Studio Code Dev Container](https://code.visualstudio.com/docs/devcontainers/containers)
that includes all the necessary tooling and Visual Studio Code (VS Code) extensions that you
need to work on this project. We use this dev container to build the project from
both VS Code and the command line.

### Dev container configuration

To inspect the development environment container image configuration and build descriptors,
refer to the contents of the `.devcontainer` directory:

- [.devcontainer/devcontainer.json](.devcontainer/devcontainer.json): development container creation and access directives ([reference](https://code.visualstudio.com/docs/remote/devcontainerjson-reference)).
- [.devcontainer/Dockerfile](.devcontainer/Dockerfile): dev container image build descriptor ([reference](https://docs.docker.com/engine/reference/builder/)).

For more information about creating containerized development environments,
refer to [Create a development container](https://code.visualstudio.com/docs/remote/create-dev-container).

### Develop inside a container running on a remote host

If you don't have a container runtime engine on your local host, but you have one available on
a remote host, you can connect to the remote host and use that container runtime.
For more information, refer to
[Develop on a remote Docker host](https://code.visualstudio.com/remote/advancedcontainers/develop-remote-host).

### Requirements

To setup a development environment you need:

- A POSIX-compliant shell
- An OCI-compatible container runtime. Tested with Docker for Linux 20.10.21
- Visual Studio Code, if you need to modify any part of this set of software components. Other editors and IDEs might work fine.

### Run the test suite

To ensure that things work as expected, we developed a comprehensive integration test suite that uses
containerized instances of Mosquitto (an open-source MQTT broker) and the Cloud Pub/Sub emulator to
simulate a runtime environment.

You can run the test suite either from Visual Studio Code, or from the command line, after cloning this
repository.

#### Run tests from Visual Studio Code

To run tests from Visual Studio Code:

1. Open the root directory of this repository with Visual Studio Code as a workspace.
    Visual Studio should prompt you to start the Dev Container.
2. Open the `Java Projects` panel or open the a JUnit test file from `src/test/java`.
3. Click on the _play_ icon near the test or the test suite that you want to run.

#### Run tests from the command line

To run tests from the command line, do the following:

1. Open a POSIX-compliant shell.
2. Change your working directory to the root directory of this repository.
3. Run the build process:

    ```sh
    scripts/build.sh
    ```

#### Automatically fix linting errors

To automatically fix linting errors that the linter finds, do the following:

1. Open a POSIX-compliant shell.
2. Change your working directory to the root directory of this repository.
3. Run the build process:

    ```sh
    scripts/build.sh --fix-linting-errors
    ```

### Details about the command line build process

To build this project from the command line, we use the same dev container that
we designed to build the project from inside VS Code. The build process does the
following:

1. Run a dev container instance to build the process.
1. Run the project build process inside the dev container.
1. The project build process:
    1. Builds all the project assets.
    1. Runs the unit tests suite.
    1. Runs the containers that the integration tests suite needs.
    1. Runs the integration tests suite.
    1. Finalizes the project build by packaging project assets.

All these container management tools share the same container runtime environment.
