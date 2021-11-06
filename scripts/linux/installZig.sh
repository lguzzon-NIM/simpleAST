#!/usr/bin/env bash

export APPS_DIR_NAME=APPs
export APPS_PATH="${HOME}/${APPS_DIR_NAME}"
[ -d "/data" ] && APPS_PATH="/data/${APPS_DIR_NAME}"
echo "APPS_PATH [${APPS_PATH}]"
mkdir -p "${APPS_PATH}"

readonly lLinuxArchitecture=$(uname -m)
echo "Linux Architecture: ${lLinuxArchitecture}"
lArchitecture=${lLinuxArchitecture}
# case ${lLinuxArchitecture} in
#   aarch64*)
#     lArchitecture="arm64"
#     ;;
#   x86_64*)
#     lArchitecture="x64"
#     ;;
# esac
echo "Tool  Architecture: ${lArchitecture}"

TOOL_NAME="ZIG"

(hash curl || sudo apt -y install curl) \
  && (hash jq || sudo apt -y install jq) \
  && curl -o zig.tar.xz -sSL "$(curl -slL "https://ziglang.org/download/index.json" \
    | jq -r ".master[\"${lArchitecture}-linux\"].tarball")" \
  && (rm -rf "$(dirname "$(which zig)")" 2>/dev/null \
    || rm -rf "$APPS_PATH/zig" 2>/dev/null \
    || true) \
  && tar -xvf zig.tar.xz 1>/dev/null 2>&1 \
  && rm zig.tar.xz || true \
  && mv zig-linux-"${lArchitecture}"* "$APPS_PATH/zig" \
  && export PATH="$APPS_PATH/zig${PATH:+:$PATH}" \
  && sed "/### +++ ${TOOL_NAME} +++ ###/,/### --- ${TOOL_NAME} --- ###/d" -i "${HOME}/.bashrc" \
  && {
    echo "### +++ ${TOOL_NAME} +++ ###"
    echo "[ -d \"$APPS_PATH/zig\" ] && export PATH=\"$APPS_PATH/zig\${PATH:+:\$PATH}\""
    echo "### --- ${TOOL_NAME} --- ###"
  } >>"${HOME}/.bashrc" \
  && zig version
