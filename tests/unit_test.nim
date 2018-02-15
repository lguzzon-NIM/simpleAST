
import unittest

import simpleAST


suite "unit-test suite":

  test "newSimpleASTNode":
    let lSimpleASTNode = newSimpleASTNode("TEST")
    assert(lSimpleASTNode.children.isNil)
    assert(lSimpleASTNode.name == "TEST")

  test "asASTStr":
    let 
      lTestStringRif = "pappo(pappo(\\\\())peppo(\\(())pippo()poppo(\\)())puppo(pappo()))"
      lSimpleASTNode = lTestStringRif.asSimpleASTNode
    assert(not lSimpleASTNode.isNil)
    if (not lSimpleASTNode.isNil):
      let lTestString = lSimpleASTNode.asASTStr
      assert(lTestString == lTestStringRif)
