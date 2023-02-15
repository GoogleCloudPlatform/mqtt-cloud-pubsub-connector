# MQTT <-> Cloud Pub/Sub Connector build and release processes

In this document, we describe the build processes.

At this point, there's no release process defined. This may change in the future
based on demand.

## Details about the build process

To build this project from the command-line, we use the same dev container that
we designed to build the project from inside VS Code. For more information about
the development environment and the dev container, refer to [Development environment](./development-environment.md).

The build process does the following:

1. Runs a dev container instance.
2. Starts the project build process inside the dev container instance.

The project build process does the following:

1. Runs code linters.
2. Builds all the project assets.
3. Runs the unit tests suite.
4. Runs the containers that the integration tests suite needs.
5. Runs the integration tests suite.
6. Finalizes the project build by packaging project assets.

All these container management tools share the same container runtime environment.

For more information about how to start the build process, refer to
[Development environment](./development-environment.md).
