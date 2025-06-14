#!/usr/bin/env bash

PRIMARY=5432
REPLICA=5433

usage() {
  echo
  echo "Usage: $0 port"
  echo
  echo "  simple monitor for 'tst.orders'."
  echo
  exit 1
}

[ "${1}" == "" ] && usage

_port="${1}"

# first time
_last_row=0

while true
do
  _dt=$(date '+%F %X.%N')
  echo "== Status date: ${_dt:0:23}"  # substr to trim msecs

  # get current pointer
  _next_row=$( psql -U tst -p ${_port} -c "select max(id) from orders" -P tuples_only | tr -d ' ' )

  # show all rows since _last_row
  echo
  echo "Batch of data since last iteration in ${_port}... BEGIN"
  echo
  psql -U tst -p ${_port} -c "select * from orders where id > '${_last_row}'" -P pager=off
  echo "Batch of data since last iteration in ${_port}... END"
  echo


  # show total amount of rows
  echo "== Monitoring port is ${_port}"
  echo "== Total amount of rows in table: [${_next_row}]"
  echo

  # dramatic pause
  echo "Ctrl+C to stop..."
  sleep 10
  echo

  # update pointer for next iteration
  _last_row=${_next_row}

done
