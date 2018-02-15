#!/bin/bash
set -e
set -o pipefail
set -o xtrace

readonly aptGetCmd="sudo -E apt-get -y -qq"
readonly aptGetInstallCmd="${aptGetCmd} --no-install-suggests --no-install-recommends install"

#Before Install
if [ -z ${NIM_BRANCH+x} ]; then
	export NIM_BRANCH=master
fi
if [ -z ${USE_GCC+x} ]; then
	export USE_GCC=4.8
fi
if [ -z ${NIM_VERBOSITY+x} ]; then
	export NIM_VERBOSITY=0
fi
sudo -E add-apt-repository -y ppa:ubuntu-toolchain-r/test
${aptGetCmd} update
${aptGetInstallCmd} "gcc-${USE_GCC}" "g++-${USE_GCC}" git
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${USE_GCC} 10
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${USE_GCC} 10
sudo update-alternatives --set gcc "/usr/bin/gcc-${USE_GCC}"
sudo update-alternatives --set g++ "/usr/bin/g++-${USE_GCC}"
${aptGetCmd} autoremove
gcc --version

#Install
pushd .
mkdir -p toCache
readonly lDownloadPath=dl
mkdir -p ${lDownloadPath}

pushd ${lDownloadPath}

#Install UPX
readonly lUPXVersion=$(git ls-remote --tags "https://github.com/upx/upx.git" | awk '{print $2}' | grep -v '{}' | awk -F"/" '{print $3}' | tail -1 | sed "s/v//g")
curl -z upx.txz -o upx.txz -L "https://github.com/upx/upx/releases/download/v${lUPXVersion}/upx-${lUPXVersion}-amd64_linux.tar.xz"
tar -xvf upx.txz
export PATH
PATH="$(pwd)/upx-${lUPXVersion}-amd64_linux${PATH:+:$PATH}" || true

popd

compile() {
	./bin/nim c koch
	./koch boot -d:release
	./koch tools -d:release
}

readonly lNimAppPath=toCache/nim-${NIM_BRANCH}-${USE_GCC}
if [ ! -x ${lNimAppPath}/bin/nim ]; then
	git clone -b ${NIM_BRANCH} --depth 1 git://github.com/nim-lang/nim ${lNimAppPath}/
	pushd ${lNimAppPath}
	git clone --depth 1 git://github.com/nim-lang/csources csources/
	pushd csources
	sh build.sh
	popd
	rm -rf csources
	compile
	popd
else
	pushd ${lNimAppPath}
	git fetch origin
	if ! git merge FETCH_HEAD | grep "Already up-to-date"; then
		compile
	fi
	popd
fi
popd
rm -f nim.cfg
if [ "${NIM_TARGET_OS}" = "windows" ]; then
	echo "------------------------------------------------------------ targetOS: ${NIM_TARGET_OS}"
	rm -rdf ~/.wine
	${aptGetInstallCmd} mingw-w64 wine
	if [ "${NIM_TARGET_CPU}" = "i386" ]; then
		echo "------------------------------------------------------------ targetCPU: ${NIM_TARGET_CPU}"
		export WINEARCH=win32
		{
			echo i386.windows.gcc.path = \"/usr/bin\"
			echo i386.windows.gcc.exe = \"i686-w64-mingw32-gcc\"
			echo i386.windows.gcc.linkerexe = \"i686-w64-mingw32-gcc\"
			echo gcc.options.linker = \"\"
		} >nim.cfg
	else
		echo "------------------------------------------------------------ targetCPU: ${NIM_TARGET_CPU}"
		export WINEARCH=win64
		if [ "${NIM_TARGET_CPU}" = "amd64" ]; then
			{
				echo amd64.windows.gcc.path = \"/usr/bin\"
				echo amd64.windows.gcc.exe = \"x86_64-w64-mingw32-gcc\"
				echo amd64.windows.gcc.linkerexe = \"x86_64-w64-mingw32-gcc\"
				echo gcc.options.linker = \"\"
			} >nim.cfg
		fi
	fi
	wine hostname
else
	if [ "${NIM_TARGET_OS}" = "linux" ]; then
		echo "------------------------------------------------------------ targetOS: ${NIM_TARGET_OS}"
		if [ "${NIM_TARGET_CPU}" = "i386" ]; then
			echo "------------------------------------------------------------ targetCPU: ${NIM_TARGET_CPU}"
			${aptGetInstallCmd} gcc-${USE_GCC}-multilib g++-${USE_GCC}-multilib gcc-multilib g++-multilib
		fi
	fi
fi

#Before Script
export PATH
PATH="$(pwd)/${lNimAppPath}/bin${PATH:+:$PATH}" || true

#Script
nim Settings
nim CTest release
