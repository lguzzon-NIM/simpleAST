
import strutils
import sequtils
from os import `/`, splitFile, ExeExt, DirSep

include "scriptsEnvVarNames.nim"


const
  gcWindowsStr = "windows"
  gcLinuxStr = "linux"
  gcMacOsXStr = "macosx"
  gcAmd64 = "amd64"
  gcArm64 = "arm64"
  gcI386 = "i386"

  gcNimFileExt = "nim"

  gcBuildDirName = "builds"
  gcCacheDirName = "caches"
  gcTargetDirName = "targets"
  gcTestDirName = "tests"

  gcTestDir = gcTestDirName

  gcBuildDir = gcBuildDirName
  gcBuildTargetDir = gcBuildDir / gcTargetDirName
  gcRepoURL = "https://github.com/lguzzon-NIM/" & "n" & "imTemplate.git"

  gcGCC = "gcc"
  gcZIG = "zig"
  gcCLang = "clang"
  gcCCDefault = gcGCC

  # --gc:refc|markAndSweep|boehm|go|none|regions
  # switch "gc", "refc" - zig KO
  # switch "gc", "markAndSweep" - zig KO
  # switch "gc", "boehm" - zig ok
  # switch "gc", "regions" - zig ok
  # switch "gc", "arc" ???
  # switch "gc", "orc" ???
  gcGCDefault = "refc"

var gReleaseOption = false


proc getTargetOS (): string =
  if existsEnv(gcTargetOSEnvVarName):
    getEnv(gcTargetOSEnvVarName)
  else:
    hostOS


proc getTargetCPU (): string =
  if existsEnv(gcTargetCpuEnvVarName):
    getEnv(gcTargetCpuEnvVarName)
  else:
    hostCPU

proc getCC (): string =
  if existsEnv(gcCCEnvVarName):
    getEnv(gcCCEnvVarName)
  else:
    gcCCDefault


var gCCVersion = ""
proc getCCVersion(): string =
  if ("" == gCCVersion):
    let lExec = gorgeEx(getCC() & " --version")
    gCCVersion = lExec.output.splitLines[0].split()[^1]
  return gCCVersion


proc getAbi(): string =
  if existsEnv(gcABIEnvVarName):
    getEnv(gcABIEnvVarName)
  else:
    if (getTargetOS() in [gcMacOsXStr, gcWindowsStr]):
      "gnu"
    else:
      "musl"


proc getGC(): string =
  # https://nim-lang.org/docs/gc.html
  # refc|markAndSweep|boehm|go|none|regions
  # arc|orc
  if existsEnv(gcGCEnvVarName):
    result = getEnv(gcGCEnvVarName)
  else:
    result = gcGCDefault


proc splitCmdLine (): tuple[options, command, params: string] =
  var lIndex = 1
  let lCount: int = paramCount()
  var lResult = ""
  while lIndex <= lCount:
    let lParam0 = paramStr(lIndex)
    if lParam0.startsWith('-'):
      lResult &= " \"$1\""%[paramStr(lIndex)]
      lIndex.inc
    else:
      break
  result.options = lResult.strip()
  if (lIndex <= lCount):
    result.command = paramStr(lIndex).strip()
    lIndex.inc
  lResult = ""
  while lIndex <= lCount:
    lResult &= " " & paramStr(lIndex)
    lIndex.inc
  result.params = lResult.strip()


proc getReleaseOption(): bool =
  gReleaseOption = gReleaseOption or ("release" == splitCmdLine().params)
  result = gReleaseOption


proc setReleaseOption(aValue: bool): bool =
  gReleaseOption = aValue
  result = gReleaseOption


proc getOsCpuCompilerName(): string =
  let lTargetCPU = getTargetCPU()
  case lTargetCPU
  of "js":
    result = "$1"%[lTargetCPU]
  else:
    let lCC = getCC()
    if (gcZIG == lCC):
      result = "$1-$2-$3-$4-$5"%[getTargetOS(), lTargetCPU, getGC(), lCC, getABI()]
    else:
      result = "$1-$2-$3-$4"%[getTargetOS(), lTargetCPU, getGC(), lCC]
  if getReleaseOption():
    result = "$1-release"%[result]


proc getBuildCacheDir (): string =
  gcBuildDir / gcCacheDirName / getOsCpuCompilerName()


proc getBuildCacheTestDir (): string =
  getBuildCacheDir() / gcTestDirName


proc getBuildTargetTestDir (): string =
  "$1-$2"%[gcBuildTargetDir, gcTestDirName] / getOsCpuCompilerName()


proc getNameFromDir(aPath: string): string =
  result = aPath.splitFile.name
  let lRFind = result.rFind({'-'})
  if (lRFind > -1):
    result.delete(lRFind, result.len.pred())


proc getSourceDir(): string =
  result = "."


proc getNimVerbosity (): string =
  if existsEnv(gcNimVerbosityEnvVarName):
    getEnv(gcNimVerbosityEnvVarName)
  else:
    "0"


proc getBinaryFileNameNoExt (): string =
  "$1-$2"%[thisDir().getNameFromDir(), getOsCpuCompilerName()]


proc getBinaryFileExt (): string =
  if ("js" == getTargetCPU()):
    # Check it with this command line: nim --putenv:NIM_VERBOSITY="3" --putenv:NIM_TARGET_CPU="js" CTest
    ".js"
  else:
    if (gcWindowsStr == getTargetOS()):
      ".exe"
    else:
      ""


proc getBinaryFileName (): string =
  getBinaryFileNameNoExt() & getBinaryFileExt()


proc getBuildBinaryFilePath (): string =
  gcBuildTargetDir / getBinaryFileName()


template selfExecWithDefaults (aCommand: string) =
  var lCmdLine = splitCmdLine()
  if ("0" == getNimVerbosity()) and (not lCmdLine.options.contains("--hint")):
    lCmdLine.options &= " --hints:off"
  let lCommand = lCmdLine.options & " " & aCommand.strip() & " " &
      lCmdLine.params
  if lcIsNimble:
    exec(selfExe().splitFile.dir / "nim " & lCommand.strip())
  else:
    selfExec(lCommand.strip())


template dependsOn (tasks: untyped) =
  for taskName in astToStr(tasks).split({',', ' '}):
    selfExecWithDefaults(taskName)


proc build_create () =
  for Dir in @[getBuildCacheDir(), gcBuildTargetDir, getBuildTargetTestDir()]:
    if (not dirExists(Dir)):
      mkdir Dir


proc Dirs (aDirPath: string): seq[string] =
  result = newSeq[string]()
  result.add(aDirPath)
  for lChildDirPath in listDirs(aDirPath):
    result.add(Dirs(lChildDirPath))


proc findTestFiles (): seq[string] =
  result = newSeq[string]()
  for lDirPath in Dirs(gcTestDir):
    for lFilePath in listFiles(lDirPath):
      if lFilePath.endsWith("_test.nim"):
        result.add(lFilePath)


proc getZigTarget(): string =
  var lTargetCPU = getTargetCPU()
  case lTargetCPU:
  of gcAmd64:
    lTargetCPU = "x86_64"
  of gcArm64:
    lTargetCPU = "aarch64"
  else:
    discard

  var lTargetOS = getTargetOS()
  case lTargetOS
  of "macosx":
    lTargetOS = "macos"
  else:
    discard

  "$1-$2-$3"%[lTargetCPU, lTargetOS, getAbi()]


proc setCC() =
  let lCC = getCC()
  if lCC.startsWith(gcZIG):
    let lBuildCacheDir = getBuildCacheDir()
    when defined(windows):
      let lZigCC = lBuildCacheDir / "zigCC.bat"
      const lZigCCContent = """
@zig cc $2%*
"""
      if (getReleaseOption()):
        lZigCC.writeFile(lZigCCContent%[lBuildCacheDir, "-s -target " & getZigTarget() & " "])
      else:
        lZigCC.writeFile(lZigCCContent%[lBuildCacheDir, "-target " & getZigTarget() & " "])
    else:
      let lZigCC = lBuildCacheDir / "zigCC.sh"
      const lZigCCContent = """
#!/usr/bin/env bash
set -e
set -o pipefail
# set -o xtrace
# echo zig cc $2"$$@"
zig cc $2"$$@"
"""
      if (getReleaseOption()):
        lZigCC.writeFile(lZigCCContent%[lBuildCacheDir, "-s -target " & getZigTarget() & " "])
      else:
        lZigCC.writeFile(lZigCCContent%[lBuildCacheDir, "-target " & getZigTarget() & " "])
      exec("chmod +x \"$1\""%[lZigCC])
    switch "cc", "clang"
    switch "clang.exe", lZigCC
    switch "clang.linkerexe", lZigCC
  else:
    switch "cc", lCC
  case lCC
  of gcGCC:
    if (gcMacOsXStr != getTargetOS()):
      let lCCMajor = getCCVersion().split('.')[0]
      case lCCMajor
      of "4":
        switch "passL", "-static"
      else:
        switch "passL", "-static -no-pie"
  of gcZIG:
    if (gcMacOsXStr == getTargetOS()):
      switch "passL", "-static"
    else:
      switch "passL", "-static -no-pie"
      if (gcWindowsStr == getTargetOS()):
        switch "clang.options.linker", ""
        switch "clang.cpp.options.linker", ""
  else:
    discard


proc switchCommon () =
  let lNimVerbosity = getNimVerbosity()
  switch "verbosity", lNimVerbosity
  setCC()
  switch "mm", getGC()
  if getReleaseOption():
    switch "define", "release"
    switch "define", "quick"
    switch "define", "danger"
    switch "checks", "off"
    switch "assertions", "off"
    switch "bound_checks", "off"
    switch "embedsrc", "off"
    when NimVersion < "1.5.0":
      switch "dead_code_elim", "on"
    switch "debugger", "off"
    switch "excessiveStackTrace", "off"
    switch "field_checks", "off"
    switch "line_dir", "off"
    switch "linetrace", "off"
    when NimVersion < "1.5.0":
      switch "nilchecks", "off"
    switch "obj_checks", "off"
    switch "opt", "speed"
    switch "overflow_checks", "off"
    switch "range_checks", "off"
    switch "stacktrace", "off"
    if (gcZIG == getCC()):
      if (gcMacOsXStr != getTargetOS()):
        switch "passC", "-flto"
        switch "passL", "-flto"
    else:
      switch "passC", "-flto"
      switch "passL", "-flto"
  else:
    switch "embedsrc", "on"
  switch "out", getBuildBinaryFilePath()
  switch "nimcache", getBuildCacheDir()
  switch "app", "console"
  let lTargetCPU = getTargetCPU()
  case lTargetCPU
  of "js":
    discard
  else:
    switch "os", getTargetOS()
    switch "cpu", lTargetCPU
    if ("0" == lNimVerbosity):
      switch "hints", "off"
    case hostOS
    of gcLinuxStr:
      if ((gcAmd64 == hostCPU) and (gcI386 == lTargetCPU)):
        switch "passC", "-m32"
        switch "passL", "-m32"
    of gcWindowsStr:
      discard


proc getTestBinaryFilePath (aSourcePath: string): string =
  result = "$1_$2$3"%[getBuildTargetTestDir() / splitFile(aSourcePath).name,
                         getOsCpuCompilerName(),
                         getBinaryFileExt()]


const
  lcTestAppFileNameEnvVarName = "testAppFileName"


proc getSourceMainFile (): string =
  let lMainFile = getSourceDir() / thisDir().getNameFromDir() & "." & gcNimFileExt
  if fileExists(lMainFile):
    result = lMainFile
  else:
    let lMessage = "Not found source [$1] in [$2]"%[lMainFile, thisDir()]
    raiseAssert(lMessage)


proc getLatestTagOfGitRepo(aRepoUrl: string): string =
  let lExec = gorgeEx("git ls-remote --tags $1"%[aRepoURL])
  var lMaxTagStr = "0"
  result = ""
  for lString in lExec.output.splitlines:
    let lTag = lString.rsplit('/', 1)
    if (lTag.len > 1):
      if (not lTag[1].contains('^')):
        let lNumbers = lTag[1].split('.')
        var lNumberStr = ""
        for lIndex in 0..5:
          if (lIndex < lNumbers.len):
            lNumberStr &= lNumbers[lIndex].align(8, '0')
          else:
            lNumberStr &= "".align(8, '0')
        if (lNumberStr > lMaxTagStr):
          lMaxTagStr = lNumberStr
          result = lTag[1]


proc setCompile(aFilePath: string) =
  let lTargetCPU = getTargetCPU()
  var lCommand = "compileToC"
  case lTargetCPU
  of "js":
    lCommand = "js"
  else:
    discard
  setCommand lCommand, aFilePath


mode = if ("0" == getNimVerbosity()): ScriptMode.Silent else: ScriptMode.Verbose


task Tasks, "list all tasks":
  selfExecWithDefaults("--listCmd")


task Settings, "display all settings":
  let lCC = getCC()
  let lABI =
    if (gcZIG == lCC):
      "  Using ABI   : [$1] <- $$$2\n" % [getAbi(), gcABIEnvVarName]
    else:
      "\n"
  let lInfos = """
  Interpreter : [$1]
  Version     : [$7]
  Source Dir  : [$4]
  Source Main : [$5]
  Target OS   : [$2] <- $$$10
  Target CPU  : [$3] <- $$$11
  Compiler CC : [$8] <- $$$12
  Using GC    : [$9] <- $$$13
  Binary File : [$6]
"""
  echo lInfos%[if lcIsNimble: "Nimble" else: "Nim",
               getTargetOS(),
               getTargetCPU(),
               getSourceDir(),
               getSourceMainFile(),
               getBuildBinaryFilePath(),
               NimVersion,
               lCC,
               getGC(),
               gcTargetOSEnvVarName,
               gcTargetCpuEnvVarName,
               gcCCEnvVarName,
               gcGCEnvVarName] & lABI


task CreateNew, "create a new project from " & "n" & "imTemplate":
  #To avoid string replace ... ;)
  let lString = gcRepoURL.rsplit('/', 1)[1].splitFile.name


  proc checkProjectName(aProjectName: string, aValidCharSet: set[char]): bool =
    result = true
    for lChar in aProjectName:
      if (not (lChar in aValidCharSet)):
        result = false
        break


  proc resetProjectDir(aProjectDir, aNewProjectName: string) =
    var lFSItemsToMove = newSeq[(string, string)]()
    rmDir(aProjectDir / ".git")
    for lDirPath in Dirs(aProjectDir):
      for lFilePath in listFiles(lDirPath):
        let lOldString = lFilePath.splitFile
        let lNewString = lOldString.name.replace(lString, aNewProjectName)
        if (lNewString != lOldString.name):
          lFSItemsToMove.add((lFilePath, lOldString.dir / lNewString &
              lOldString.ext))
    for lDirPath in Dirs(aProjectDir):
      let lOldString = lDirPath.splitFile
      let lNewString = lOldString.name.replace(lString, aNewProjectName)
      if (lNewString != lOldString.name):
        lFSItemsToMove.add((lDirPath, lOldString.dir / lNewString &
            lOldString.ext))
    for lToMove in lFSItemsToMove:
      lToMove[0].mvFile(lToMove[1])
    for lDirPath in Dirs(aProjectDir):
      for lFilePath in listFiles(lDirPath):
        let lOldString = lFilePath.readFile
        let lNewString = lOldString.replace(lString, aNewProjectName)
        if (lNewString != lOldString):
          lFilePath.writeFile(lNewString)

  let lNewProjectName = splitCmdLine().params
  let lValidCharSet = {'a' .. 'z', 'A' .. 'Z', '0' .. '9', '_'}
  let lParentDir = thisDir() / ".."
  if ("" == lNewProjectName):
    echo "Please provide new project name as param"
    return
  if (not checkProjectName(lNewProjectName, lValidCharSet)):
    echo "Please provide a project name containing valid chars in $1"%[$lValidCharSet]
    return
  let lNewProjectDir = lParentDir / lNewProjectName
  let lTag = getLatestTagOfGitRepo(gcRepoURL)
  echo "Cloning [$1] tag [$3] to [$2]"%[gcRepoURL, lNewProjectDir, lTag]
  discard gorgeEx("git clone -b \"$3\" --single-branch $1 $2"%[gcRepoURL,
      lNewProjectDir, lTag])
  echo "Resetting files and dirs ..."
  resetProjectDir(lNewProjectDir, lNewProjectName)
  echo "... done"


task Clean, "clean the project":
  if dirExists("nimcache"):
    "nimcache".rmDir()
  let lFileToRemove = "$1.$2"%[thisDir().getNameFromDir(), ExeExt]
  if fileExists(lFileToRemove):
    lFileToRemove.rmFile()
  if dirExists(gcBuildDir):
    gcBuildDir.rmDir()
  else:
    echo "Nothing to clean"


task CompileTest_OSLinux_OSWindows, "":
  switchCommon()
  switch "path", getSourceDir()
  switch "nimcache", getBuildCacheTestDir()
  let lFilePath = lcTestAppFileNameEnvVarName.getEnv()
  switch "out", lFilePath.getTestBinaryFilePath()
  setCompile(lFilePath)


task CompileAndRunTest_OSLinux_OSWindows, "":
  dependsOn CompileTest_OSLinux_OSWindows
  exec("$1=\"$2\" wine \"$3\" 2>/dev/null"%[gcApplicationToTestEnvVarName,
      getBuildBinaryFilePath(), lcTestAppFileNameEnvVarName.getEnv().getTestBinaryFilePath()])


task CompileAndRunTest, "":
  let lFilePath = lcTestAppFileNameEnvVarName.getEnv()
  switchCommon()
  if (gcLinuxStr == getTargetOS()):
    switch "threads", "on"
  switch "path", getSourceDir()
  switch "nimcache", getBuildCacheTestDir()
  switch "out", getTestBinaryFilePath(lFilePath)
  switch "putenv", "$1=\"$2\""%[gcApplicationToTestEnvVarName,
      getBuildBinaryFilePath()]
  switch "run"
  setCompile(lFilePath)


task Test, "test/s the project":
  dependsOn Build
  for lFilePath in findTestFiles():
    var lCommandToExec = "CompileAndRunTest"
    case hostOS
    of gcLinuxStr:
      if (gcWindowsStr == getTargetOS()):
        lCommandToExec = "CompileAndRunTest_OSLinux_OSWindows"
    selfExecWithDefaults("\"--putenv:$1=$2\" $3"%[lcTestAppFileNameEnvVarName,
        lFilePath, lCommandToExec])


task CTest, "clean and test/s the project":
  dependsOn Clean Test


task BuildBinary, "":
  dependsOn Settings NInstallDeps
  build_create()
  switchCommon()
  setCompile(getSourceMainFile())


task Build, "build the project":
  if (not fileExists(getBuildBinaryFilePath())):
    dependsOn BuildBinary
    if ("js" == getTargetCPU()):
      discard
    else:
      if getReleaseOption():
        if (gcMacOsXStr == getTargetOS()):
          if (gcZIG != getCC()):
            exec "strip " & getBuildBinaryFilePath()
        else:
          exec "strip --strip-all " & getBuildBinaryFilePath()
        try:
          exec "upx --best " & getBuildBinaryFilePath()
        except:
          echo "ERROR!!! UPX goes wrong but we continue ..."


task CBuild, "clean and build the project":
  dependsOn Clean Build


task BuildToDeploy, "build the project ready to deploy":
  var lDeploy = ""
  let lCC = getCC()
  if (gcZIG == lCC):
    lDeploy &= "\"--clang.options.speed=" & get("clang.options.speed").replace(
        "-O3", "-O4") & "\" "
  else:
    if (gcCLang == lCC):
      lDeploy &= "\"--clang.options.speed=" & get("clang.options.speed").replace(
          "-O3", "-O4") & "\" "
    else:
      lDeploy &= "\"--gcc.options.speed=" & get("gcc.options.speed").replace(
          "-O3", "-O4") & "\" "
  lDeploy &= "Test release"
  selfExecWithDefaults(lDeploy)


task CBuildToDeploy, "clean and build the project ready to deploy":
  dependsOn Clean BuildToDeploy


task Run, "run the project ex: nim --putenv:runParams=\"<Parameters>\" run":
  dependsOn Build
  let params =
    if existsEnv("runParams"):
      " " & getEnv("runParams")
    else:
      ""
  let command = ((if ("js" == getTargetCPU()):
    "node "
  else:
    "") &
    (getBuildBinaryFilePath() & params)).strip()
  command.exec()


task CRun, "clean and run the project ex: nim --putenv:runParams=\"<Parameters>\" run":
  dependsOn Clean Run


task UpdateScript, "update this script to latest release in " & "n" & "imTemplate [uses svn on github]":
  let lFromScript = "scripts/nim/scriptsIncludes.nim"
  lFromScript.cpFile(lFromScript & "_OLD")
  exec("svn export --force \"$1/tags/$2/$3\" \"$3\""%[gcRepoURL,
      getLatestTagOfGitRepo(gcRepoURL), lFromScript])


task NInstall, "install project using nimble":
  exec(selfExe().splitFile.dir / "nimble -y install")


task NInstallDeps, "install project dependencies using nimble":
  exec(selfExe().splitFile.dir / "nimble -y install -d")


task NUninstall, "uninstall project using nimble":
  exec(selfExe().splitFile.dir / "nimble -y uninstall " & thisDir().getNameFromDir())


task NCompile, "compile using nimble":
  dependson Clean
  exec(selfExe().splitFile.dir / "nimble -y c " & getSourceMainFile())


task Util_TravisEnvMat, "generate the complete travis-ci env matrix":
  const
    lEnvs = @[@[gcTargetOSEnvVarName, gcLinuxStr, gcWindowsStr],
              @[gcTargetCpuEnvVarName, gcAmd64, gcI386],
              @[gcGCCVersionToUseEnvVarName, "9"],
              @[gcNimTagSelector, "version", "devel"],
              @[gcGCEnvVarName, "refc", "arc"]]
    lEnvsLow = lEnvs.low
    lEnvsHigh = lEnvs.high
  var
    lResult = ""

  proc lGetEnvValue(aResult: string, aIndex: int) =
    if (aIndex <= lEnvsHigh):
      var lHeader = aResult
      lHeader.addSep(" ")
      lHeader &= lEnvs[aIndex][0] & "="
      for lIndex in 1..lEnvs[aIndex].high:
        lGetEnvValue(lHeader & lEnvs[aIndex][lIndex], aIndex + 1)
    else:
      lResult &= "- '" & aResult & "'\n"

  lGetEnvValue("", lEnvsLow)
  echo lResult


task FormatSourceFiles, "format source files using nimpretty":
  if (gorgeEx("nimpretty --version").exitCode != 0):
    echo "Error nimpretty not present in path!!!"
  else:
    var lFilesToFormat: seq[string] = @[]
    var lDirsToSearch = @["."]
    const lcStartWith = "." & DirSep & "."
    while lDirsToSearch.len > 0:
      let lDirToSearch = lDirsToSearch.pop()
      let lFilesToAdd = listFiles(lDirToSearch)
      lFilesToFormat.add(lFilesToAdd.filter(
        proc (aItem: string): bool = aItem.contains(".nim"))
      )
      let lDirsToAdd = listDirs(lDirToSearch)
      lDirsToSearch.add(lDirsToAdd.filter(
        proc (aItem: string): bool = not (aItem.startsWith(lcStartWith) or
            aItem.startsWith("." & DirSep & gcBuildDir)))
      )
    let lCurrentDir = getCurrentDir()
    while lFilesToFormat.len > 0:
      let lFileToFormat = lCurrentDir / lFilesToFormat.pop()
      echo "Formatting [$1]"%[lFileToFormat]
      let lExec = gorgeEx("nimpretty --indent:2 --maxLineLen:256 \"$1\""%[lFileToFormat])
      if (lExec.exitCode != 0):
        echo "Error!!!"
      if (lExec.output.len > 0):
        echo lExec.output


task FormatShfmtFiles, "format shfmt files":
  if (gorgeEx("shfmt -version").exitCode != 0):
    echo "Error shfmt not present in path!!!"
  else:
    let lCurrentDir = getCurrentDir()
    const lCommandFmt = "shfmt -w -bn -ci -i 2 -f -s \"$1\""
    let lExec = gorgeEx(lCommandFmt%[lCurrentDir])
    if (lExec.exitCode != 0):
      echo "Error!!!"
    if (lExec.output.len > 0):
      var lFilesToFormat = lExec.output.splitLines(false).filter(
        proc (aItem: string): bool = aItem != ""
      )
      while lFilesToFormat.len > 0:
        let lFileToFormat = lFilesToFormat.pop()
        echo "Formatting [$1]"%[lFileToFormat]
        let lExec = gorgeEx(lCommandFmt%[lFileToFormat])
        if (lExec.exitCode != 0):
          echo "Error!!!"
        if (lExec.output.len > 0):
          echo lExec.output


task FormatYamlFiles, "format yaml files using yq":
  if (gorgeEx("yq --version").exitCode != 0):
    echo "Error yq not present in path!!!"
  else:
    var lFilesToFormat: seq[string] = @[]
    var lDirsToSearch = @["."]
    const lcStartWith = "." & DirSep & "."
    while lDirsToSearch.len > 0:
      let lDirToSearch = lDirsToSearch.pop()
      let lFilesToAdd = listFiles(lDirToSearch)
      lFilesToFormat.add(lFilesToAdd.filter(
        proc (aItem: string): bool = aItem.contains(".yml") or aItem.contains(".yaml"))
      )
      let lDirsToAdd = listDirs(lDirToSearch)
      lDirsToSearch.add(lDirsToAdd.filter(
        proc (aItem: string): bool = not (aItem.startsWith(lcStartWith) or
            aItem.startsWith("." & DirSep & gcBuildDir)))
      )
    let lCurrentDir = getCurrentDir()
    while lFilesToFormat.len > 0:
      let lFileToFormat = lCurrentDir / lFilesToFormat.pop()
      echo "Formatting [$1]"%[lFileToFormat]
      let lExec = gorgeEx("yq eval 'sortKeys(..)' \"$1\" -P -I2 > yq.tmp && mv yq.tmp \"$1\""%[lFileToFormat])
      if (lExec.exitCode != 0):
        echo "Error!!!"
      if (lExec.output.len > 0):
        echo lExec.output


task CheckProject, "project checking ...":
  dependsOn Settings NInstallDeps
  build_create()
  switchCommon()
  setCommand "check", getSourceMainFile()


task Lint, "project linting ...":
  dependsOn CheckProject FormatSourceFiles FormatShfmtFiles FormatYamlFiles
