# Development environment

To set up a development environment, we designed a
[Visual Studio Code Dev Container](https://code.visualstudio.com/docs/devcontainers/containers)
that includes all the necessary tooling and Visual Studio Code (Visual Studio
Code) extensions that you need to work on this project. We use this dev
container to build the project from both Visual Studio Code and the
command-line.

## Dev container configuration

To inspect the development environment container image configuration and build
descriptors, refer to the contents of the `.devcontainer` directory:

- [.devcontainer/devcontainer.json](../.devcontainer/devcontainer.json):
  development container creation and access directives
  ([reference](https://code.visualstudio.com/docs/remote/devcontainerjson-reference)).
- [.devcontainer/Dockerfile](../.devcontainer/Dockerfile): dev container image
  build descriptor
  ([reference](https://docs.docker.com/engine/reference/builder/)).

For more information about creating containerized development environments,
refer to
[Create a development container](https://code.visualstudio.com/docs/remote/create-dev-container).

## Develop inside a container running on a remote host

If you don't have a container runtime engine on your local host, but you have
one available on a remote host, you can connect to the remote host and use that
container runtime. For more information, refer to
[Develop on a remote Docker host](https://code.visualstudio.com/remote/advancedcontainers/develop-remote-host).

## Requirements

To setup a development environment you need:

- A POSIX-compliant shell
- An OCI-compatible container runtime. Tested with Docker for Linux 20.10.21
- Visual Studio Code, if you need to modify any part of this set of software
  components. Other editors and IDEs might work fine.

## Run the test suite

To ensure that things work as expected, we developed a comprehensive integration
test suite that uses containerized instances of Mosquitto (an open-source MQTT
broker) and the Cloud Pub/Sub emulator to simulate a runtime environment.

You can run the test suite either from Visual Studio Code, or from the
command-line, after cloning this repository.

### Run Java unit and integration tests from Visual Studio Code

To run tests from Visual Studio Code:

1.  Open the root directory of this repository with Visual Studio Code as a
    workspace. Visual Studio should prompt you to start the Dev Container.
1.  Open the `Java Projects` panel or open the JUnit test file from
    `src/test/java`.
1.  Click on the _play_ icon near the test or the test suite that you want to
    run.

### Build the project and run the test suite from the command-line

To run tests from the command-line, do the following:

1.  Open a POSIX-compliant shell.
1.  Change your working directory to the root directory of this repository.
1.  Run the build process:

    ```sh
    scripts/build.sh
    ```

### Code linting

This project runs two code linters:

- [super-linter](https://github.com/github/super-linter) (actually, a collection
  of linters)
- [Spotless](https://github.com/diffplug/spotless)

Both run as part of the build process.

#### Automatically fix linting errors with Spotless

To automatically fix linting errors that Spotless finds, do the following:

1.  Open a POSIX-compliant shell.
1.  Change your working directory to the root directory of this repository.
1.  Run the build process:

    ```sh
    scripts/build.sh --fix-linting-errors
    ```

`super-linter` doesn't support automatically fixing errors.

#### Lint configuration

All the linters have their configuration stored in the `config/lint` directory.
Additionally, some linters shipped within `super-linter` also take the
[EditorConfig configuration file](../.editorconfig) into account.

## Details about the build process

For more information about the build process, refer to
[Build and release processes](./build-release-processes.md)
