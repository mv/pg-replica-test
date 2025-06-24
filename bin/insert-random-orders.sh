#!/usr/bin/env bash

# db-primary
export PGDATABASE=postgres
export PGHOST=127.0.0.1
export PGPORT=5432

export PGUSER=tst
export PGPASSWORD=tst


# Source of products
# from MacOS/BSD
DICT="data/usr-share-dict-web2a.txt"
_qtd_lines=$( wc -l ${DICT} | awk '{print $1}' | tr -d ' ')

_dict_item=() # bash array
_line_no=1    # array index
while IFS= read -r line
do  # each file line_no is now the array index
    _dict_item[${_line_no}]="$line"
    (( _line_no++ ))
done < ${DICT}


##
## Run it
##
while true
do
  # Batch: amount of INSERTS
  # Sizes: 10, 20, 30 or 40 rows
  _ins_batch=$( shuf -i 1-4 -n 1 )
  _ins_size=$(( ${_ins_batch} * 10 ))

  echo "$(date '+%F %X') BATCH: ${_ins_size} rows: BEGIN"

  for i in $(seq 1 ${_ins_size})
  do
    # Generate random product

    # Pick a random line number from DICT file
    _dict_line=$( shuf -n 1 -i 1-${_qtd_lines} )
    # v1: grep the line by number
#   _dict_name=$( cat -n ${DICT} | grep -w ${_dict_line} | awk '{print $2,$3}' )
    # v2: get the line number from array
    _dict_name=${_dict_item[${_dict_line}]}
    _prod_name=${_dict_name^} # Bash: Capitalize

    # Generate random quantity
    _prod_qtty=$( shuf -n 1 -i 1-10 )

    printf "$(date '+%F %X') Insert: [%02d] Qty: %2d, Product: ${_prod_name}\n" ${i} ${_prod_qtty}

    psql -U tst -q -c "INSERT INTO tst.orders (product_name,quantity,md5_hash) VALUES ('${_prod_name}','${_prod_qtty}',md5('${_prod_name}'));"

  done

  echo "$(date '+%F %X') BATCH: ${_ins_qtd} rows: END"
  echo
  echo "Ctrl+C to stop..."
  sleep 5

done
