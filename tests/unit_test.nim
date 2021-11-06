
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

  test "asSimpleASTNode only name":
    let
      lTestStringRif = "pappo"
      lSimpleASTNode = lTestStringRif.asSimpleASTNode
    assert(not lSimpleASTNode.isNil)
    assert(lSimpleASTNode.name == lTestStringRif)

  test "asASTStr name":
    let
      lTestStringRif = "pappo"
      lSimpleASTNode = lTestStringRif.asSimpleASTNode
    assert(not lSimpleASTNode.isNil)
    if (not lSimpleASTNode.isNil):
      let lTestString = lSimpleASTNode.asASTStr
      assert(lTestString == lTestStringRif)

  test "asASTStr":
    let
      lTestStringRif = "pappo(pappo(\\\\)peppo(\\()pippo()poppo(\\))puppo(pappo))"
      lSimpleASTNode = lTestStringRif.asSimpleASTNode
    assert(not lSimpleASTNode.isNil)
    if (not lSimpleASTNode.isNil):
      let lTestString = lSimpleASTNode.asASTStr
      assert(lTestString == lTestStringRif)

  test "asASTStr Extended":
    let
      lTestStringRifOld = "pappo(pappo(\\\\())peppo(\\(())pippo()poppo(\\)())puppo(pappo())pippo())"
      lTestStringRifNew = "pappo(pappo(\\\\)peppo(\\()pippo()poppo(\\))puppo(pappo)pippo)"
      lSimpleASTNodeOld = lTestStringRifOld.asSimpleASTNode
      lSimpleASTNodeNew = lTestStringRifNew.asSimpleASTNode
    assert(not lSimpleASTNodeOld.isNil)
    assert(not lSimpleASTNodeNew.isNil)
    if (not lSimpleASTNodeOld.isNil):
      let
        lTestString = lSimpleASTNodeOld.asASTStr
      assert(lTestString == lTestStringRifNew)
    if (not lSimpleASTNodeNew.isNil):
      let
        lTestString = lSimpleASTNodeNew.asASTStr
      assert(lTestString == lTestStringRifNew)

  test "newSimpleASTNode":
    let
      lSimpleASTNode1 = newSimpleASTNode()
      lSimpleASTNode2 = newSimpleASTNode(lSimpleASTNode1.name)
    assert("" == lSimpleASTNode2.name)
