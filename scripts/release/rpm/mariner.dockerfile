ARG image=mcr.microsoft.com/cbl-mariner/base/core:2.0

FROM ${image} AS build-env
ARG cli_version=dev

RUN tdnf update -y
RUN tdnf install -y binutils file rpm-build gcc libffi-devel python3-devel openssl-devel make diffutils patch dos2unix perl sed

WORKDIR /azure-cli

COPY . .

# Mariner 2.0 only has 'python3' package, which is currently (2022-12-09) Python 3.9.
# It has no version-specific packages like 'python39'.
RUN dos2unix ./scripts/release/rpm/azure-cli.spec && \
    REPO_PATH=$(pwd) CLI_VERSION=$cli_version PYTHON_PACKAGE=python3 PYTHON_CMD=python3 \
    rpmbuild -v -bb --clean scripts/release/rpm/azure-cli.spec && \
    cp /usr/src/mariner/RPMS/x86_64/azure-cli-${cli_version}-1.cm2.x86_64.rpm /azure-cli-dev.rpm

FROM ${image} AS execution-env

RUN tdnf update -y
RUN tdnf install -y python3 rpm

COPY --from=build-env /azure-cli-dev.rpm ./
RUN rpm -i ./azure-cli-dev.rpm && \
    az --version
