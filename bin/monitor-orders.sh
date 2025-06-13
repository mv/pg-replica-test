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
  date '+%F %X.%N'

  # get current pointer
  _next_row=$( psql -U tst -p ${_port} -c "select max(id) from orders" -P tuples_only )

  # show all rows since _last_row
  echo
  echo "Dataset since last insertion [${_port}]..."
  echo
  psql -U tst -p ${_port} -c "select * from orders where id > '${_last_row}'" -P pager=off

  # show current amount of rows
  echo
  echo "Monitoring port: [${_port}]"
  echo "Current amount of rows: [${_next_row}]"
  echo

  # dramatic pause
  echo "Ctrl+C to stop..."
  sleep 10
  echo

  # update pointer for next iteration
  _last_row=${_next_row}

done
