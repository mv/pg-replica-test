#!/usr/bin/env bash

# MacOS/BSD
DICT="data/usr-share-dict-web2a.txt"

_qtd_lines=$( wc -l ${DICT} | awk '{print $1}' | tr -d ' ')


while true
do
  # Batch: amount of INSERTS
  # Sizes: 10, 20, 30 or 40 rows
  _ins_batch=$( shuf -i 1-4 -n 1 )
  _ins_size=$(( ${_ins_batch} * 10 ))

  echo "$(date '+%F %X') BATCH: ${_ins_size} rows: BEGIN"

  for i in $(seq 1 ${_ins_size})
  do
    # Generate data
    _dict_line=$( shuf -n 1 -i 1-${_qtd_lines} )
    _dict_name=$( cat -n ${DICT} | grep -w ${_dict_line} | awk '{print $2,$3}' )

    _prod_qtty=$( shuf -n 1 -i 1-10 )
    _prod_name=${_dict_name^} # Bash: Capitalize

    printf "$(date '+%F %X') Insert: [%02d] Qty: %2d, Product: ${_prod_name}\n" ${i} ${_prod_qtty}

    psql -U orders -q -c "INSERT INTO orders (product_name,quantity,md5_hash) VALUES ('${_prod_name}','${_prod_qtty}',md5('${_prod_name}'));"

  done

  echo "$(date '+%F %X') BATCH: ${_ins_qtd} rows: END"
  echo
  echo "Ctrl+C to stop..."
  sleep 5

done
