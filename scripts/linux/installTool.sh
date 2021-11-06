#!/usr/bin/env bash

# Common Script Header Begin
# Tips: all the quotes  --> "'`
# Tips: other chars --> ~

trap ctrl_c INT

UNAME_S=$(uname -s)
readonly UNAME_S

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

# readonly current_dir="$(pwd)"
script_path="$(readlink_ -f "${BASH_SOURCE[0]}")"
readonly script_path
script_dir="$(getScriptDir "${script_path}")"
readonly script_dir
# readonly script_file="$(basename "${script_path}")"
# readonly script_name="${script_file%\.*}"
# readonly script_ext="$([[ ${script_file} == *.* ]] && echo ".${script_file##*.}" || echo '')"

# Common Script Header End

# Script Begin

architectureOs() {
  uname -m
}

# shellcheck disable=SC2120
sAPPS_PATH() {
  local -r APPS_DIR_NAME=${1:-APPs}
  APPS_PATH="${HOME}/${APPS_DIR_NAME}"
  [ -d "/data" ] && APPS_PATH="/data/${APPS_DIR_NAME}"
  echo "APPS_PATH [${APPS_PATH}]"
  mkdir -p "${APPS_PATH}"
}

architectureNim() {
  local -r lLinuxArchitecture=$(architectureOs)
  local lArchitecture=${lLinuxArchitecture}
  case ${lLinuxArchitecture} in
    aarch64*)
      lArchitecture="arm64"
      ;;
    x86_64*)
      lArchitecture="x64"
      ;;
  esac
  echo "${lArchitecture}"
}

urlNimDevel() {
  local -r lArchitecture=$(architectureNim)
  curl -sSL https://api.github.com/repos/nim-lang/nightlies/releases | jq -r "[ .[]?.assets[] | select(.browser_download_url | test(\"latest-devel/linux_${lArchitecture}\")) | {updated_at, browser_download_url} ] | sort_by(.updated_at) | reverse | .[0].browser_download_url"
}

urlNimVersion() {
  local -r lArchitecture=$(architectureNim)
  curl -sSL https://api.github.com/repos/nim-lang/nightlies/releases | jq -r "[ .[]?.assets[] | select(.browser_download_url | test(\"latest-version-\")) | select(.browser_download_url | test(\"linux_$lArchitecture\")) | {updated_at, browser_download_url} ] | sort_by(.browser_download_url) | reverse | .[0].browser_download_url"
}

nim_i() {
  local -r TOOL_NAME="NIM"
  local -r TOOL_URL="${1:-$(urlNimDevel)}"
  sAPPS_PATH
  local -r APP_PATH="${APPS_PATH}/nim"
  local -r BASHRC_PATH="${HOME}/.bashrc"
  (hash curl 2>/dev/null || sudo apt -y install curl) \
    && (hash jq 2>/dev/null || sudo apt -y install jq) \
    && curl -o nim.tar.xz -sSL "${TOOL_URL}" \
    && (rm -rf "$(dirname "$(dirname "$(which nim)")")" 2>/dev/null \
      || rm -rf "${APP_PATH}" 2>/dev/null \
      || true) \
    && tar -xvf nim.tar.xz 1>/dev/null 2>&1 \
    && rm nim.tar.xz || true \
    && mv nim-* "${APP_PATH}" \
    && export PATH="${APP_PATH}/bin${PATH:+:$PATH}" \
    && sed "/### +++ ${TOOL_NAME^^} +++ ###/,/### --- ${TOOL_NAME^^} --- ###/d" -i "$BASHRC_PATH" \
    && {
      echo "### +++ ${TOOL_NAME^^} +++ ###"
      echo "[ -d \"${APP_PATH}/bin\" ] && export PATH=\"${APP_PATH}/bin\${PATH:+:\$PATH}\""
      echo "### --- ${TOOL_NAME^^} --- ###"
    } >>"$BASHRC_PATH" \
    && which nim \
    && nim --version
  return $?
}

zig_i() {
  sAPPS_PATH
  TOOL_NAME="zig"
  local -r APP_PATH="${APPS_PATH}/${TOOL_NAME}"
  local -r BASHRC_PATH="${HOME}/.bashrc"
  local -r lLinuxArchitecture=$(architectureOs)
  local lArchitecture=${lLinuxArchitecture}
  (hash curl || sudo apt -y install curl) \
    && (hash jq || sudo apt -y install jq) \
    && curl -o zig.tar.xz -sSL "$(curl -slL "https://ziglang.org/download/index.json" \
      | jq -r ".master[\"${lArchitecture}-linux\"].tarball")" \
    && (rm -rf "$(dirname "$(which zig)")" 2>/dev/null \
      || rm -rf "${APP_PATH}" 2>/dev/null \
      || true) \
    && tar -xvf zig.tar.xz 1>/dev/null 2>&1 \
    && rm zig.tar.xz || true \
    && mv zig-linux-"${lArchitecture}"* "${APP_PATH}" \
    && export PATH="${APP_PATH}${PATH:+:$PATH}" \
    && sed "/### +++ ${TOOL_NAME^^} +++ ###/,/### --- ${TOOL_NAME^^} --- ###/d" -i "${BASHRC_PATH}" \
    && {
      echo "### +++ ${TOOL_NAME^^} +++ ###"
      echo "[ -d \"${APP_PATH}\" ] && export PATH=\"${APP_PATH}\${PATH:+:\$PATH}\""
      echo "### --- ${TOOL_NAME^^} --- ###"
    } >>"${BASHRC_PATH}" \
    && which ${TOOL_NAME} \
    && ${TOOL_NAME} version
}

shfmt_i() {
  local -r lLinuxArchitecture=$(architectureOs)
  local lArchitecture=${lLinuxArchitecture}
  case ${lLinuxArchitecture} in
    aarch64*)
      lArchitecture="arm64"
      ;;
    x86_64*)
      lArchitecture="amd64"
      ;;
  esac
  local -r lGitHubUser="mvdan"
  local -r lGitHubRepo="sh"
  local -r lGitHubApp="shfmt"
  local -r lGitHubAppPath="${script_dir}/${lGitHubApp}"
  local -r lGitHubUserRepo="${lGitHubUser}/${lGitHubRepo}"
  local -r lGitHubAppLatestRelease=$(curl -fsSL -H 'Accept: application/json' "https://github.com/${lGitHubUserRepo}/releases/latest")
  # shellcheck disable=2001
  local -r lGitHubAppLatestReleaseVersion=$(echo "${lGitHubAppLatestRelease}" | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
  sAPPS_PATH
  local -r APP_PATH="${APPS_PATH}/$lGitHubApp"
  local -r BASHRC_PATH="${HOME}/.bashrc"
  mkdir -p "${APP_PATH}" \
    && (hash curl 2>/dev/null || sudo apt -y install curl) \
    && curl -o "${lGitHubAppPath}" -fsSL "https://github.com/${lGitHubUserRepo}/releases/download/${lGitHubAppLatestReleaseVersion}/${lGitHubApp}_${lGitHubAppLatestReleaseVersion}_linux_${lArchitecture}" \
    && chmod +x "${lGitHubAppPath}" \
    && mv "${lGitHubAppPath}" "${APP_PATH}" \
    && export PATH="${APP_PATH}${PATH:+:$PATH}" \
    && sed "/### +++ ${lGitHubApp^^} +++ ###/,/### --- ${lGitHubApp^^} --- ###/d" -i "$BASHRC_PATH" \
    && {
      echo "### +++ ${lGitHubApp^^} +++ ###"
      echo "[ -d \"${APP_PATH}\" ] && export PATH=\"${APP_PATH}\${PATH:+:\$PATH}\""
      echo "### --- ${lGitHubApp^^} --- ###"
    } >>"$BASHRC_PATH" \
    && which ${lGitHubApp} \
    && ${lGitHubApp} -version
  return $?
}

yq_i() {
  local -r lLinuxArchitecture=$(architectureOs)
  local lArchitecture=${lLinuxArchitecture}
  case ${lLinuxArchitecture} in
    aarch64*)
      lArchitecture="arm64"
      ;;
    x86_64*)
      lArchitecture="amd64"
      ;;
  esac
  local -r lGitHubUser="mikefarah"
  local -r lGitHubRepo="yq"
  local -r lGitHubApp="yq"
  local -r lGitHubAppPath="${script_dir}/${lGitHubApp}"
  # local -r lGitHubAppArchivePath="${script_dir}/${lGitHubApp}.tar.xz"
  local -r lGitHubUserRepo="${lGitHubUser}/${lGitHubRepo}"
  local -r lGitHubAppLatestRelease=$(curl -fsSL -H 'Accept: application/json' "https://github.com/${lGitHubUserRepo}/releases/latest")
  # shellcheck disable=2001
  local -r lGitHubAppLatestReleaseVersion=$(echo "${lGitHubAppLatestRelease}" | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
  sAPPS_PATH
  local -r APP_PATH="${APPS_PATH}/$lGitHubApp"
  local -r BASHRC_PATH="${HOME}/.bashrc"
  mkdir -p "${APP_PATH}" \
    && (hash curl 2>/dev/null || sudo apt -y install curl) \
    && curl -o "${lGitHubAppPath}" -fsSL "https://github.com/${lGitHubUserRepo}/releases/download/${lGitHubAppLatestReleaseVersion}/${lGitHubApp}_linux_${lArchitecture}" \
    && chmod +x "${lGitHubAppPath}" \
    && mv "${lGitHubAppPath}" "${APP_PATH}" \
    && export PATH="${APP_PATH}${PATH:+:$PATH}" \
    && sed "/### +++ ${lGitHubApp^^} +++ ###/,/### --- ${lGitHubApp^^} --- ###/d" -i "$BASHRC_PATH" \
    && {
      echo "### +++ ${lGitHubApp^^} +++ ###"
      echo "[ -d \"${APP_PATH}\" ] && export PATH=\"${APP_PATH}\${PATH:+:\$PATH}\""
      echo "### --- ${lGitHubApp^^} --- ###"
    } >>"$BASHRC_PATH" \
    && which ${lGitHubApp} \
    && ${lGitHubApp} --version
  return $?
}

upx_i() {
  local -r lLinuxArchitecture=$(architectureOs)
  local lArchitecture=${lLinuxArchitecture}
  case ${lLinuxArchitecture} in
    aarch64*)
      lArchitecture="arm64"
      ;;
    x86_64*)
      lArchitecture="amd64"
      ;;
  esac
  local -r lGitHubUser="upx"
  local -r lGitHubRepo="upx"
  local -r lGitHubApp="upx"
  local -r lGitHubUserRepo="${lGitHubUser}/${lGitHubRepo}"
  local -r lGitHubAppArchivePath="${script_dir}/${lGitHubApp}.tar.xz"
  sAPPS_PATH
  local -r APP_PATH="${APPS_PATH}/$lGitHubApp"
  local -r BASHRC_PATH="${HOME}/.bashrc"
  (hash curl 2>/dev/null || sudo apt -y install curl 2>/dev/null) \
    && (hash git 2>/dev/null || sudo apt -y install git 2>/dev/null) \
    && (hash xz 2>/dev/null || sudo apt -y install xz-utils 2>/dev/null)
  local -r lUPXVersion=$(git ls-remote --tags "https://github.com/upx/upx.git" \
    | awk '{print $2}' \
    | grep -v '{}' \
    | awk -F"/" '{print $3}' \
    | tail -1 \
    | sed "s/v//g")
  local -r lUpxUrl="https://github.com/upx/upx/releases/download/v${lUPXVersion}/upx-${lUPXVersion}-${lArchitecture}_linux.tar.xz"
  curl -o "${lGitHubAppArchivePath}" -fsSL "${lUpxUrl}" \
    && tar -xvf "${lGitHubAppArchivePath}" 1>/dev/null 2>&1 \
    && rm "${lGitHubAppArchivePath}" || true \
    && rm -rf "${APP_PATH}" || true \
    && mv "upx-${lUPXVersion}-${lArchitecture}_linux" "${APP_PATH}" \
    && export PATH="${APP_PATH}${PATH:+:$PATH}" \
    && sed "/### +++ ${lGitHubApp^^} +++ ###/,/### --- ${lGitHubApp^^} --- ###/d" -i "$BASHRC_PATH" \
    && {
      echo "### +++ ${lGitHubApp^^} +++ ###"
      echo "[ -d \"${APP_PATH}\" ] && export PATH=\"${APP_PATH}\${PATH:+:\$PATH}\""
      echo "### --- ${lGitHubApp^^} --- ###"
    } >>"$BASHRC_PATH" \
    && which ${lGitHubApp} \
    && ${lGitHubApp} --version
}

main() {
  local -r helpString=$(printf '%s\n%s' "Help, valid options are :" "$(tr "\n" ":" <"${script_path}" | grep -o '# Commands start here:.*# Commands finish here' | tr ":" "\n" | grep -o '^ *\-[^)]*)' | sed 's/.$//' | sed 's/^ *//' | sed 's/^\(.\)/    \1/' | sort)")
  if [[ $# -gt 0 ]]; then
    local lOption
    while [ "$#" -gt 0 ]; do
      lOption=$(tr ':' '_' <<<"$1")
      case $lOption in
        # Commands start here
        -h | --help) echo "${helpString}" ;;
        -t | --test)
          echo "$@"
          break
          ;;
        -archNim | --architectureNim) architectureNim ;;
        -archOs | --architectureOs) architectureOs ;;
        -urlNimDevel | --urlNimDevel) urlNimDevel ;;
        -urlNimVersion | --urlNimVersion) urlNimVersion ;;
        -nim_i | --nimInstall)
          if [ "$2" == "" ]; then
            nim_i
          else
            nim_i "$2"
            shift
          fi
          ;;
        -shfmt_i | --shfmtInstall) shfmt_i ;;
        -upx_i | --upxInstall) upx_i ;;
        -yq_i | --yqInstall) yq_i ;;
        -zig_i | --zigInstall) zig_i ;;
        # Commands finish here
        *)
          echo "Error: can't understand --> $lOption <-- as option/parameter"
          echo "${helpString}"
          return 1
          ;;
      esac
      shift
    done
  else
    echo "${helpString}"
    return 1
  fi
  # set +x
  return $?
}

main "$@"
exit $?

# Script End
