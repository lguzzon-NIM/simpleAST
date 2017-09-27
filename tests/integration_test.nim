
import unittest
import os
import osproc
import strutils

import simpleAST

include "../scripts/nim/scriptsEnvVarNames.nimInc"

suite "integration-test suite":
  
  test "getMessage excecuting the app":
    assert(true)
    #assert(cHelloWorld == execProcess(getEnv(gcApplicationToTestEnvVarName)).strip())
