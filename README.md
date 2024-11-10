# Overview

This repository consists of a `docker-compose` file and a companion script (`run.sh`) that will create the following services:

- [Coder](https://coder.com/docs) with a minimal template accessible at http://localhost:7080 (default credentials: `admin@coder.com`/`SomeSecurePassword!`),
- [PostgreSQL](https://www.postgresql.org/docs/) database,
- [Prometheus](https://prometheus.io/docs/) and [postgres_exporter](https://github.com/prometheus-community/postgres_exporter) with preconfigured targets for Coder and PostgreSQL, accessible at http://localhost:9090,
- [Grafana](https://grafana.com/docs/) with preconfigured dashboards for Coder and PostgreSQL, accessible at http://localhost:3000 (anonymous login).

The companion script will create a number of workspaces from a predefined template.
The workspaces have no persistent storage, thus any data will be deleted when stopped.
Additionally, the workspaces will stop after 1 hour, and automatically start at 8:00 AM the next day.

**Needless to say, this entire setup is completely insecure and should not be exposed to the wild internet. YOU HAVE BEEN TOLD.**

# Usage

Run the provided script `./run.sh`.
It accepts the following arguments:
- `CONCURRENCY`: Number of concurrent workspaces to create (default: 3),
- `NUM_WORKSPACES`: Number of workspaces to create (default: 10),
- `CODER_IMAGE`: Coder image to use (default: `ghcr.io/coder/coder:latest`),
- `VERBOSE`: Enable verbose output (default: false).

# Cleanup

Automated cleanup is currently not implemented.
To clean up manually:
- Stop the services: `docker-compose down`, (optionally, add `-v` to also remove the volumes)
- Remove any remaing Docker containers: `docker rm -f $(docker ps -a -q)`
