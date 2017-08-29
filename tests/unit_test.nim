
import unittest
import os
import osproc
import strutils

import SimpleAst


suite "main unit-test suite":
  test "newSimpleASTNode":
    let lSimpleASTNode = newSimpleASTNode("TEST")
    assert(lSimpleASTNode.name == "TEST")
  test "asASTStr":
    let lTestStringRif = "pappo(pappo(\\\\())peppo(\\(())pippo()poppo(\\)())puppo(pappo()))"
    let lSimpleASTNode = lTestStringRif.asSimpleASTNode
    let lTestString = lSimpleASTNode.asASTStr
    assert(lTestString == lTestStringRif)
