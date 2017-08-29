
import unittest
import os
import osproc
import strutils

import SimpleAst


suite "unit-test suite":

  test "newSimpleASTNode":
    let lSimpleASTNode = newSimpleASTNode("TEST")
    assert(lSimpleASTNode.name == "TEST")

  test "asASTStr":
    let 
      lTestStringRif = "pappo(pappo(\\\\())peppo(\\(())pippo()poppo(\\)())puppo(pappo()))"
      lSimpleASTNode = lTestStringRif.asSimpleASTNode
      lTestString = lSimpleASTNode.asASTStr
    assert(lTestString == lTestStringRif)
