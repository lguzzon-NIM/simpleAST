#!/usr/bin/env bash

export APPS_DIR_NAME=APPs
export APPS_PATH="${HOME}/${APPS_DIR_NAME}"
[ -d "/data" ] && APPS_PATH="/data/${APPS_DIR_NAME}"
echo "APPS_PATH [${APPS_PATH}]"
mkdir -p "${APPS_PATH}"

(hash make &>/dev/null || sudo apt -y install build-essential || sudo apt update && sudo apt -y install build-essential) \
  && (hash git || sudo apt -y install git) \
  && pushd "${APPS_PATH}" \
  && ( 
    ([ -d v ] || git clone "https://github.com/vlang/v") \
      && cd v \
      && make \
      && sudo ./v symlink \
      && v doctor \
      ;
    popd || exit 1
  )
