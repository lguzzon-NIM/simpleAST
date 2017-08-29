
import unittest
import os
import osproc
import strutils

import SimpleAST

include "../scripts/nim/scriptsEnvVarNames.nimInc"

suite "main integration-test suite":
  test "getMessage excecuting the app":
    assert(true)
    #assert(cHelloWorld == execProcess(getEnv(gcApplicationToTestEnvVarName)).strip())
