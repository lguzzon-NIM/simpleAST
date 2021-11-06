#!/usr/bin/env bash

export APPS_DIR_NAME=APPs
export APPS_PATH="${HOME}/${APPS_DIR_NAME}"
[ -d "/data" ] && APPS_PATH="/data/${APPS_DIR_NAME}"
echo "APPS_PATH [${APPS_PATH}]"
mkdir -p "${APPS_PATH}"

lLinuxArchitecture=$(uname -m)
readonly lLinuxArchitecture

echo "Linux Architecture: ${lLinuxArchitecture}"
lArchitecture=${lLinuxArchitecture}
case ${lLinuxArchitecture} in
  aarch64*)
    lArchitecture="arm64"
    ;;
  x86_64*)
    lArchitecture="x64"
    ;;
esac
echo "Tool  Architecture: ${lArchitecture}"

TOOL_NAME="NIM"
TOOL_URL="$(curl -sSL https://api.github.com/repos/nim-lang/nightlies/releases | jq -r "[ .[]?.assets[] | select(.browser_download_url | test(\"latest-devel/linux_$lArchitecture\")) | {updated_at, browser_download_url} ] | sort_by(.updated_at) | reverse | .[0].browser_download_url")"
case $1 in
  latestVersion*)
    TOOL_URL="$(curl -sSL https://api.github.com/repos/nim-lang/nightlies/releases | jq -r "[ .[]?.assets[] | select(.browser_download_url | test(\"latest-version-\")) | select(.browser_download_url | test(\"linux_$lArchitecture\")) | {updated_at, browser_download_url} ] | sort_by(.browser_download_url) | reverse | .[0].browser_download_url")"
    ;;
esac

APP_PATH="$APPS_PATH/nim"
BASHRC_PATH="${HOME}/.bashrc"
(hash curl 2>/dev/null || sudo apt -y install curl) \
  && (hash jq 2>/dev/null || sudo apt -y install jq) \
  && curl -o nim.tar.xz -sSL "${TOOL_URL}" \
  && (rm -rf "$(dirname "$(dirname "$(which nim)")")" 2>/dev/null \
    || rm -rf "$APP_PATH" 2>/dev/null \
    || true) \
  && tar -xvf nim.tar.xz \
  && rm nim.tar.xz || true \
  && mv nim-* "$APP_PATH" \
  && export PATH="$APP_PATH/bin${PATH:+:$PATH}" \
  && sed "/### +++ ${TOOL_NAME} +++ ###/,/### --- ${TOOL_NAME} --- ###/d" -i "$BASHRC_PATH" \
  && {
    echo "### +++ ${TOOL_NAME} +++ ###"
    echo "[ -d \"$APP_PATH/bin\" ] && export PATH=\"$APP_PATH/bin\${PATH:+:\$PATH}\""
    echo "### --- ${TOOL_NAME} --- ###"
  } >>"$BASHRC_PATH" \
  && nim --version
