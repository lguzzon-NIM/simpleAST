#!/usr/bin/env bash
set -e
set -o pipefail
set -o xtrace

readonly lShellCheckOS=$(uname -s)
readonly lOS=${lShellCheckOS,,}
echo "${lOS}"

readonly lShellCheckVersion=$(git ls-remote --tags "https://github.com/koalaman/shellcheck.git" \
  | awk '{print $2}' \
  | grep -v '{}' \
  | awk -F"/" '{print $3}' \
  | tail -1 \
  | sed "s/v//g")
echo "${lShellCheckVersion}"
readonly lLinuxArchitecture=$(uname -m)
echo "${lLinuxArchitecture}"

lArchitecture=${lLinuxArchitecture}
# case ${lLinuxArchitecture} in
# aarch64*)
#     lArchitecture="arm64"
#     ;;
# x86_64*)
#     lArchitecture="amd64"
#     ;;
# esac
echo "${lArchitecture}"

readonly scversion="latest" # or "v0.4.7", or "latest"
wget -qO- "https://github.com/koalaman/shellcheck/releases/download/${scversion?}/shellcheck-${scversion?}.${lOS}.${lArchitecture}.tar.xz" | tar -xJv
sudo cp "shellcheck-${scversion}/shellcheck" /usr/bin/
shellcheck --version
