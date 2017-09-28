
import unittest
import os
import osproc
import strutils

import simpleAST


suite "unit-test suite":

  test "newSimpleASTNode":
    let lSimpleASTNode = newSimpleASTNode("TEST")
    assert(lSimpleASTNode.hasChildren == false)
    assert(lSimpleASTNode.name == "TEST")

  test "asASTStr":
    let 
      lTestStringRif = "pappo(pappo(\\\\())peppo(\\(())pippo()poppo(\\)())puppo(pappo()))"
      lSimpleASTNode = lTestStringRif.asSimpleASTNode
    assert(not lSimpleASTNode.isNil)
    if (not lSimpleASTNode.isNil):
      let lTestString = lSimpleASTNode.asASTStr
      assert(lTestString == lTestStringRif)
