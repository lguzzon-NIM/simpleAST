#!/bin/bash
set -e
set -o pipefail
set -o xtrace

readonly sudoCmd="sudo -E"
readonly aptGetCmd="${sudoCmd} apt-get -y -qq"
readonly aptGetInstallCmd="${aptGetCmd} --no-install-suggests --no-install-recommends install"

#Before Install
if [ -z ${NIM_BRANCH+x} ]; then
	export NIM_BRANCH="master"
fi
if [ -z ${USE_GCC+x} ]; then
	export USE_GCC="4.8"
fi
if [ -z ${NIM_VERBOSITY+x} ]; then
	export NIM_VERBOSITY=0
fi

if [ -z ${DISPLAY+x} ]; then
	export DISPLAY=":99.0"
fi

installRepositoryIfNotPresent() {
	local -r lPPAName="$1"
	local lResult=1
	export lResult
	while IFS= read -r -d '' APT; do
		while read -r ENTRY; do
			echo "${ENTRY}" | grep "${lPPAName}"
			lResult=$?
			if [[ "${lResult}" -eq 0 ]]; then
				break
			fi
		done < <(grep -o '^deb http://ppa.launchpad.net/[a-z0-9\-]\+/[a-z0-9\-]\+' "${APT}")
		# https://superuser.com/questions/688882/how-to-test-if-a-variable-is-equal-to-a-number-in-shell
		if [[ "${lResult}" -eq 0 ]]; then
			break
		fi
	done < <(find /etc/apt/ -name \*.list -print0)
	if [[ "${lResult}" -eq 1 ]]; then
		eval "sudo -E add-apt-repository -y ppa:${lPPAName}" &&
			eval "${aptGetCmd} update"
		lResult=$?
	fi
	return ${lResult}
}

installIfNotPresent() {
	local -r lPackageName="$1"
	local -r lPreCommandToRun="${2:-true}"
	local -r lPostCommandToRun="${3:-true}"
	local lResult=0
	if [[ $(dpkg-query -W -f='${Status}' "${lPackageName}" 2>/dev/null | grep -c "ok installed") -eq 0 ]]; then
		eval "${lPreCommandToRun}" &&
			eval "${aptGetInstallCmd} ${lPackageName}" &&
			eval "${lPostCommandToRun}"
		lResult=$?
	fi
	return ${lResult}
}

patchUdev() {
	# shellcheck disable=1004,2143
	[ ! "$(grep -A1 '### END INIT INFO' /etc/init.d/udev | grep 'dpkg --configure -a || exit 0')" ] &&
		sudo sed -i 's/### END INIT INFO/### END INIT INFO\
dpkg --configure -a || exit 0/' /etc/init.d/udev
}

patchUdev
installIfNotPresent "gcc-${USE_GCC}" "installRepositoryIfNotPresent ubuntu-toolchain-r/test"
installIfNotPresent "g++-${USE_GCC}"
installIfNotPresent "git"

sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-${USE_GCC} 10
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-${USE_GCC} 10
sudo update-alternatives --set gcc "/usr/bin/gcc-${USE_GCC}"
sudo update-alternatives --set g++ "/usr/bin/g++-${USE_GCC}"

${aptGetCmd} clean
${aptGetCmd} autoremove

gcc --version

#Install
pushd .
readonly lCachedDir="toCache"
mkdir -p "${lCachedDir}"
readonly lDownloadPath="${lCachedDir}/dl"
mkdir -p ${lDownloadPath}

pushd ${lDownloadPath}

#Install UPX
readonly lUPXVersion=$(git ls-remote --tags "https://github.com/upx/upx.git" | awk '{print $2}' | grep -v '{}' | awk -F"/" '{print $3}' | tail -1 | sed "s/v//g")
if [ ! -d "$(pwd)/upx-${lUPXVersion}-amd64_linux" ]; then
	curl -z upx.txz -o upx.txz -L "https://github.com/upx/upx/releases/download/v${lUPXVersion}/upx-${lUPXVersion}-amd64_linux.tar.xz"
	tar -xvf upx.txz
fi
export PATH
# shellcheck disable=2123
PATH="$(pwd)/upx-${lUPXVersion}-amd64_linux${PATH:+:$PATH}" || true

popd

compile() {
	./bin/nim c koch
	./koch boot -d:release
	./koch tools -d:release
}

readonly lNimAppPath="${lCachedDir}/nim-${NIM_BRANCH}-${USE_GCC}"
if [ ! -x ${lNimAppPath}/bin/nim ]; then
	git clone --single-branch -b ${NIM_BRANCH} git://github.com/nim-lang/nim ${lNimAppPath}/
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
	if [[ $(git merge FETCH_HEAD | grep -c "Already up[ -]to[ -]date") -eq 0 ]]; then
		compile
	fi
	popd
fi
popd
rm -f nim.cfg
if [[ "${NIM_TARGET_OS}" == "windows" ]]; then
	echo "------------------------------------------------------------ targetOS: ${NIM_TARGET_OS}"
	export WINEPREFIX=~/.wineNIM
	${sudoCmd} dpkg --add-architecture i386
	${aptGetCmd} update

	installIfNotPresent mingw-w64
	installIfNotPresent wine
	if [[ "${NIM_TARGET_CPU}" == "i386" ]]; then
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
		if [[ "${NIM_TARGET_CPU}" == "amd64" ]]; then
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
	if [[ "${NIM_TARGET_OS}" == "linux" ]]; then
		echo "------------------------------------------------------------ targetOS: ${NIM_TARGET_OS}"
		if [[ "${NIM_TARGET_CPU}" == "i386" ]]; then
			echo "------------------------------------------------------------ targetCPU: ${NIM_TARGET_CPU}"
			installIfNotPresent gcc-${USE_GCC}-multilib
			installIfNotPresent g++-${USE_GCC}-multilib
			installIfNotPresent gcc-multilib
			installIfNotPresent g++-multilib
		fi
	fi
fi

#Before Script
export PATH
PATH="$(pwd)/${lNimAppPath}/bin${PATH:+:$PATH}" || true

#Script
nim Settings
nim CTest release
