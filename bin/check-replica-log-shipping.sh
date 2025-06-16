#!/usr/bin/env bash


_begin=$(date '+%F %X')
echo
echo "BEGIN: ${_begin}"

while true
do
  _status=$(psql -U postgres -h 127.0.0.1 -p 5433 postgres -c '\d tst.orders' 2>&1)

  echo "${_status}" | grep 'Did not find any relation named' 2>&1>/dev/null
  _tst=$?

  if [ ${_tst} == 0 ]
  then printf  "CHECK: $(date '+%F %X')  [Waiting for log switch to reach replica... (from 30s to 5min)]\r"
  else break
  fi

# echo "Ctrl+C to stop..."
  sleep 1
done

_end=$(date '+%F %X')
echo
echo "CHECK: $(date '+%F %X')  Checkpoint reached. Table created."
echo "END  : ${_end}"
echo