#!/bin/bash
MOVEFROM=files/*/

function randomString(){
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1
}

function randomInt(){
  echo $(( ( RANDOM % ${2} )  + ${1} ))
}

for dir in ${MOVEFROM}; do
  echo "Cleanup of ${dir}*"
  rm -f ${dir}*
  echo "Generating random files in ${dir}"
  from=$(randomInt 1 5)
  to=$(randomInt 5 21)
  for i in $( seq ${from} ${to}); do
    touch ${dir}"file${i}"$(randomString)".txt"
    if (($(randomInt 0 2) == 0)); then
      touch ${dir}"file${i} with spaces "$(randomString)".txt"
    fi
  done
done

echo "Done"
