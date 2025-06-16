#!/usr/bin/env bash


# Setup tasks for log streaming
psql -U postgres -h 127.0.0.1 -p 5432 postgres < sql/ddl/schema.tst.sql
psql -U tst      -h 127.0.0.1 -p 5432 postgres < sql/ddl/orders.tab.sql


psql -U postgres -h 127.0.0.1 -p 5432 postgres < sql/user.replication.sql

