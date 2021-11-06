#!/usr/bin/env bash

# Common Script Header Begin
# Tips: all the quotes  --> "'`
# Tips: other chars --> ~

trap ctrl_c INT

readonly UNAME_S=$(uname -s)

function ctrl_c() {
  echo "** Trapped CTRL-C"
  [[ -z "$(jobs -p)" ]] || kill "$(jobs -p)"
}

readlink_() {
  if [[ $UNAME_S == "Darwin" ]]; then
    (which greadlink >/dev/null 2>&1 || brew install coreutils >/dev/null 2>&1)
    greadlink "$@"
  else
    readlink "$@"
  fi
}

function getScriptDir() {
  local lScriptPath="$1"
  local ls
  local link
  # Need this for relative symlinks.
  while [ -h "${lScriptPath}" ]; do
    ls="$(ls -ld "${lScriptPath}")"
    link="$(expr "${ls}" : '.*-> \(.*\)$')"
    if expr "${link}" : '/.*' >/dev/null; then
      lScriptPath="${link}"
    else
      lScriptPath="$(dirname "${lScriptPath}")/${link}"
    fi
  done
  readlink_ -f "${lScriptPath%/*}"
}

readonly current_dir="$(pwd)"
readonly script_path="$(readlink_ -f "${BASH_SOURCE[0]}")"
readonly script_dir="$(getScriptDir "${script_path}")"
readonly script_file="$(basename "${script_path}")"
readonly script_name="${script_file%\.*}"
readonly script_ext="$([[ ${script_file} == *.* ]] && echo ".${script_file##*.}" || echo '')"

# Setting up APPs variables
APPS_DIR_NAME=APPs
APPS_PATH="${HOME}/${APPS_DIR_NAME}"
[ -d "/data" ] && APPS_PATH="/data/${APPS_DIR_NAME}"
echo "APPS_PATH [${APPS_PATH}]"
mkdir -p "${APPS_PATH}"

TOOL_NAME="code-server"
INSTALL_METHOD="detect"
CODE_SERVER_DIR_NAME="${TOOL_NAME}"
CODE_SERVER_PATH="${APPS_PATH}/${CODE_SERVER_DIR_NAME}"
USER_DATA_PATH="${CODE_SERVER_PATH}/user-data"
EXTENSIONS_PATH="${CODE_SERVER_PATH}/extensions"
TOOL_NAME_LOG_FILE="${script_dir}/${TOOL_NAME}_log.txt"
TOOL_NAME_PID_FILE="${script_dir}/${TOOL_NAME}_pid.txt"

resetINotify() {
  # https://unix.stackexchange.com/questions/13751/kernel-inotify-watch-limit-reached
  echo "System settings fs.inotify.max_user_watches -- Begin"
  FILE_TO_UPDATE_PATH="/etc/sysctl.conf"
  TOOL_NAME="vscode"
  sed "/### +++ ${TOOL_NAME} +++ ###/,/### --- ${TOOL_NAME} --- ###/d" -i "$FILE_TO_UPDATE_PATH" \
    && {
      echo "### +++ ${TOOL_NAME} +++ ###"
      echo "fs.inotify.max_user_watches=524288"
      echo "### --- ${TOOL_NAME} --- ###"
    } >>"$FILE_TO_UPDATE_PATH"
  sysctl fs.inotify.max_user_watches=524288
  sysctl -p
  echo "System settings fs.inotify.max_user_watches -- End"
}

startCodeServer() {
  TOOL_COMMAND="code-server"
  #--method [detect | standalone]
  if [ "${INSTALL_METHOD}" == "standalone" ]; then
    TOOL_COMMAND="${CODE_SERVER_PATH}/bin/${TOOL_COMMAND}"
    FILE_TO_UPDATE_PATH="${HOME}/.bashrc"
    sed "/### +++ ${TOOL_NAME} +++ ###/,/### --- ${TOOL_NAME} --- ###/d" -i "$FILE_TO_UPDATE_PATH" \
      && {
        echo "### +++ ${TOOL_NAME} +++ ###"
        echo "[ -d \"${CODE_SERVER_PATH}/bin\" ] && export PATH=\"${CODE_SERVER_PATH}/bin\${PATH:+:\$PATH}\""
        echo "### --- ${TOOL_NAME} --- ###"
      } >>"$FILE_TO_UPDATE_PATH"
  fi
  PASSWORD=rat1onaL nohup "${TOOL_COMMAND}" --auth password --bind-addr 0.0.0.0:443 --cert --disable-telemetry --user-data-dir "${USER_DATA_PATH}" --extensions-dir "${EXTENSIONS_PATH}" >"${TOOL_NAME_LOG_FILE}" 2>&1 &
  echo $! >"${TOOL_NAME_PID_FILE}"
}

stopCodeServer() {
  if [ -f "${TOOL_NAME_PID_FILE}" ]; then
    pkill -SIGINT -P "$(cat "${TOOL_NAME_PID_FILE}")"
    rm "${TOOL_NAME_PID_FILE}"
  fi
}

restartCodeServer() {
  stopCodeServer
  startCodeServer
}

updateCodeServer() {
  stopCodeServer

  resetINotify

  mkdir -p "${CODE_SERVER_PATH}"
  mkdir -p "${USER_DATA_PATH}"
  mkdir -p "${EXTENSIONS_PATH}"

  echo "Installing code-server in path [${CODE_SERVER_PATH}] as ${INSTALL_METHOD}"
  curl -fsSL https://code-server.dev/install.sh | sh -s -- --method "${INSTALL_METHOD}" --prefix "${CODE_SERVER_PATH}"
  [ -d "/${HOME}/.cache/code-server" ] && rm -Rf "/${HOME}/.cache/code-server"

  startCodeServer
}

installCodeServer() {
  stopCodeServer
  [ -d "${CODE_SERVER_PATH}" ] && rm -Rf "${CODE_SERVER_PATH}"
  updateCodeServer
}

main() {
  local -r helpString=$(printf '%s\n%s' "Help, valid options are :" "$(tr "\n" ":" <"${script_path}" | grep -o '# Commands start here:.*# Commands finish here' | tr ":" "\n" | grep -o '^ *\-[^)]*)' | sed 's/.$//' | sed 's/^ *//' | sed 's/^\(.\)/    \1/' | sort)")

  if [ "$#" -gt 0 ]; then

    while [ "$#" -gt 0 ]; do
      case $1 in
        # Commands start here
        -c | --copyToServer) (
          scp "${script_path}" "$2"':~/installCodeServer.sh' \
            && ssh "$2" chmod +x '~/installCodeServer.sh'
        ) && shift ;;
        -i | --installCodeServer) (installCodeServer) ;;
        -r | --restartCodeServer) (restartCodeServer) ;;
        -s | --startCodeServer) (startCodeServer) ;;
        -st | --stopCodeServer) (stopCodeServer) ;;
        -u | --updateCodeServer) (updateCodeServer) ;;
        # Commands finish here
        *) echo "${helpString}" | more ;;
      esac
      shift
    done

  else
    echo "${helpString}" | more
  fi
}

main "$@"

exit $?

# ps -A -o pid= -o ppid= -o cmd= | grep "auth password --bind-addr 0.0.0.0:443"
# ps -A -o pid= -o ppid= -o cmd= | grep "code-server\ --auth"
# $ kill -- -<PPID>
# For example, with this process tree:
# UID        PID  PPID  C STIME  TTY         TIME CMD
# ubuntu   11096     1  0 05:36 ?        00:00:00 /bin/bash ./parent.sh
# ubuntu   11097 11096  0 05:36 ?        00:00:00 /bin/bash ./child.sh
# ubuntu   11098 11097  0 05:36 ?        00:00:00 sleep 1000

# root@v0:~# ps -A -o pid= -o ppid= -o cmd= | grep "--auth password --bind-addr 0.0.0.0:443"
#  1902     1 /usr/lib/code-server/lib/node /usr/lib/code-server --auth password --bind-addr 0.0.0.0:443 --cert --disable-telemetry
#  1920  1902 /usr/lib/code-server/lib/node /usr/lib/code-server --auth password --bind-addr 0.0.0.0:443 --cert --disable-telemetry
# root@v0:~# which code-server
# /usr/bin/code-server

# /data/DEVs/GITs/GITLABs/farmafiches-mobile
