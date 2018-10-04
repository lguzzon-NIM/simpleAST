
import unittest

import simpleAST


suite "unit-test suite":

  test "newSimpleASTNode":
    let lSimpleASTNode = newSimpleASTNode("TEST")
    assert(lSimpleASTNode.children.len == 0)
    assert(lSimpleASTNode.children == @[])
    assert(lSimpleASTNode.name == "TEST")

  test "SimpleASTNode add":
    let lSimpleASTNode = newSimpleASTNode("TEST")
    assert(lSimpleASTNode.addChild(newSimpleASTNode("Child")))
    assert(lSimpleASTNode.children[0].name == "Child")

  test "asASTStr":
    let 
      lTestStringRif = "pappo(pappo(\\\\())peppo(\\(())pippo()poppo(\\)())puppo(pappo()))"
      lSimpleASTNode = lTestStringRif.asSimpleASTNode
    assert(not lSimpleASTNode.isNil)
    if (not lSimpleASTNode.isNil):
      let lTestString = lSimpleASTNode.asASTStr
      assert(lTestString == lTestStringRif)
