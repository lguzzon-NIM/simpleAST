#!/usr/bin/env bash

export CHOOSENIM_NO_ANALYTICS=1
export GITBIN=$HOME/.choosenim/git/bin
export PATH=$HOME/.nimble/bin:$GITBIN:$PATH

if ! type -P choosenim &>/dev/null; then
  echo "Fresh install"
  mkdir -p $GITBIN
  if [[ $TRAVIS_OS_NAME == "windows" ]]; then
    export EXT=.exe
    # Setup git outside "Program Files", space breaks cmake sh.exe
    cd $GITBIN/..
    curl -sSL -s "https://github.com/git-for-windows/git/releases/download/v2.23.0.windows.1/PortableGit-2.23.0-64-bit.7z.exe" -o portablegit.exe
    7z x -y -bd portablegit.exe
    cd -
  fi

  export CHOOSENIM_CHOOSE_VERSION="$NIM_TAG_SELECTOR --latest"
  curl https://nim-lang.org/choosenim/init.sh -sSf >init.sh
  sh init.sh -y
  cp $HOME/.nimble/bin/choosenim$EXT $GITBIN/.

  # Copy DLLs for choosenim
  if [[ $TRAVIS_OS_NAME == "windows" ]]; then
    cp $HOME/.nimble/bin/*.dll $GITBIN/.
  fi
else
  echo "Already installed"
  rm -rf $HOME/.choosenim/current
  choosenim update $NIM_TAG_SELECTOR --latest
  choosenim $NIM_TAG_SELECTOR
fi

if [[ $TRAVIS_OS_NAME == "osx" ]]; then
  # Work around https://github.com/nim-lang/Nim/issues/12337 fixed in 1.0+
  ulimit -n 8192
fi
