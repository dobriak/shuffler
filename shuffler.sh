#!/bin/bash
set -e
# Shuffler by Julian Neytchev
# Reshufle all files in a directory so they end up being in
# numbered subdirectories, no more than a given number of
# files per subdirectory.

SCRIPTNAME=$( cd "$( dirname ${0} )" && pwd -P)/$(basename ${0})
TARGET=files/
MAXFILES=10
SAVEIFS=${IFS}
IFS=$(echo -en "\n\b")
trap cleanup EXIT

function cleanup(){
  echo "Done"
  IFS=${SAVEIFS}
}

function getFileCount(){
  #1 directory
  find ${1} -maxdepth 1 -type f | grep -v ${SCRIPTNAME} | wc -l
}

function getRandomFiles(){
  #1 directory; 2 number of files
  echo "$(find ${1} -maxdepth 1 -type f | grep -v ${SCRIPTNAME} | sort -R | head -n ${2})"
}

function getNextDirectory(){
  #1 directory
  local last_dir=$(find ${1} -maxdepth 1 -type d | sort | tail -n 1)
  # 10# is prepended to force a base-10 evaluation
  printf '%03d' $(( 10#${last_dir##*/}+1 ))
}

function showUsage(){
  echo "Script for shuffling a specified number of files into subdirectories."
  echo "Usage: ${SCRIPTNAME} [-d <directory/>] [-n <number of files>] [-h]"
}

# Main

#Checking the cli parameters for overrides
if (( $# > 0 )); then
  while getopts ":d:n:h" opt; do
    case ${opt} in
      d)
        TARGET=${OPTARG}
        ;;
      n)
        MAXFILES=${OPTARG}
        ;;
      h)
        showUsage
        exit 0
        ;;
      \?)
        echo "Invalid option: -${OPTARG}"
        showUsage
        exit 1
        ;;
      :)
        echo "Option -${OPTARG} requires an argument."
        showUsage
        exit 1
        ;;
    esac
  done
fi

#Sanitizing input
if [ "${TARGET: -1}" != "/" ]; then
  echo "Appending / to ${TARGET}"
  TARGET=${TARGET}/
fi

if ! [[ "${MAXFILES}" =~ ^[0-9]+$ ]]; then
  echo "${MAXFILES} is not a number."
  exit 1
fi


#Move files from folders with more than MAXFILES files
echo "Trimming longer directories..."
for dir in ${TARGET}*/; do
    filecount=$(getFileCount ${dir})
    if  ((${filecount} > ${MAXFILES})) ; then
      filediff=$(( ${filecount} - ${MAXFILES} ))
      #Move random filediff files
      for extrafile in $(getRandomFiles ${dir} ${filediff}); do
        echo "(Trimming) Moving ${extrafile} to ${TARGET}"
        mv "${extrafile}" "${TARGET}"
      done
    fi
done

#Fill out directories that have less than MAXFILES
echo "Appending to shorter directories..."
for dir in ${TARGET}*/; do
    filecount=$(getFileCount ${dir})
    to_filecount=$(getFileCount ${TARGET})
    #Only if there are files in TARGET
    if (( ${to_filecount} > 0)); then
      if  ((${filecount} < ${MAXFILES})) ; then
        filediff=$(( ${MAXFILES} - ${filecount} ))
        upper=$(( ${filediff} < ${to_filecount} ? ${filediff} : ${to_filecount}))
        for extrafile in $(getRandomFiles ${TARGET} ${upper}); do
          echo "(Appending) Moving ${extrafile} to ${dir}"
          mv "${extrafile}" "${dir}"
        done
      fi
    fi
done

#Create additional directories as needed
echo "Adding additional directories if needed..."
to_filecount=$(getFileCount ${TARGET})
while (( ${to_filecount} > 0)); do
  new_dir=$(getNextDirectory ${TARGET})
  echo "Creating new directory ${TARGET}${new_dir}"
  mkdir ${TARGET}${new_dir}
  upper=$(( ${MAXFILES} > ${to_filecount} ? ${to_filecount} : ${MAXFILES} ))
  for extrafile in $(getRandomFiles ${TARGET} ${upper}); do
    echo "(Populating) Moving ${extrafile} to ${TARGET}${new_dir}"
    mv "${extrafile}" "${TARGET}${new_dir}"
  done

  to_filecount=$(getFileCount ${TARGET})
done
