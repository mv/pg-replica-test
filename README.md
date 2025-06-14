# Postgres Replica Test

A small docker based lab to test Postgres v17 replication.


## Proposal

- to build a new Pg container from the latest available packages from Alpine Linux.
- start a `db-primary` container and a `db-replica` container.
- share `wal` archive files via an internal mount point.
- implement replication via Log Shipping.
- execute a script that generates random batches of `INSERT` rows.
- use a terminal window to monitor the insertions at `db-primary`.
- use another terminal window to monitor the insertions at `db-replica`.


## Diagram

Initial diagram:

![Postgres Replica Test](docs/pg-replica-test.1.png)


## FAQ

### 1. Why Docker and not Vagrant/Virtubalbox?

* Because of the challenge of provisioning via `Dockerfile` instead of using a `Vagrantfile`.
* Because of less RAM/Disk resources that Docker uses less when compared to Virtualbox.
* Because of how easier to is to share the solution via a container image versus a vbox file.
* Because of how easy is to create a volume shared between `'n'` containers.


### 2. Why using Postgres Log Shipping and not Streaming?

Both solutions are good enough.</br>

At configuration level, Log shipping pre-requisite is the presence of a common storage and some minimal parameters in `postgresql.conf`.

Streaming pre-requisites are:
  - IP address of the `primary` node (used in the connection string of `postgresql.conf`)
  - IP address of the `replica` node (used in the `pg_hba.conf`)
  - a replication `user/password` (used in the `pg_hba.conf`)
  - configuration of `pg_hba.conf`
  - parameters in `postgresql.conf`

At runtime level, using log shipping adds to a nice effect of realizing the steps taken by `checkpoint > archive > ship > restore`.

The observed delay between servers is not a bug, but a feature that demonstrates how the replication mechanism is keeping the flow of data up-to-date.



