#!/usr/bin/env bash

set -x

(hash wget 2>/dev/null || sudo apt -y install wget) \
  && (hash git 2>/dev/null || sudo apt -y install git) \
  && (hash xz 2>/dev/null || sudo apt -y install xz-utils)
readonly lUPXVersion=$(git ls-remote --tags "https://github.com/upx/upx.git" \
  | awk '{print $2}' \
  | grep -v '{}' \
  | awk -F"/" '{print $3}' \
  | tail -1 \
  | sed "s/v//g")
echo "${lUPXVersion}"
readonly lLinuxArchitecture=$(uname -m)
echo "${lLinuxArchitecture}"
lArchitecture=${lLinuxArchitecture}
case ${lLinuxArchitecture} in
  aarch64*)
    lArchitecture="arm64"
    ;;
  x86_64*)
    lArchitecture="amd64"
    ;;
esac
echo ${lArchitecture}

readonly lUpxUrl="https://github.com/upx/upx/releases/download/v${lUPXVersion}/upx-${lUPXVersion}-${lArchitecture}_linux.tar.xz"
echo "${lUpxUrl}"
wget -O upx.tar.xz "${lUpxUrl}" \
  && tar -xvf upx.tar.xz \
  && rm upx.tar.xz || true \
  && rm -rf "${HOME}/.upx" || true \
  && mv "upx-${lUPXVersion}-${lArchitecture}_linux" "${HOME}/.upx" \
  && export PATH="$HOME/.upx${PATH:+:$PATH}" \
  && echo 'export PATH="$HOME/.upx${PATH:+:$PATH}"' >>"${HOME}/.bashrc" \
  && upx --version
