
import unittest
import os
import osproc
import strutils

import SimpleAst.strProcs


suite "strProcs unit-test suite":

  test "strToEscapedStr with char an set":
    let 
      lTestStringRif = "TEST"
      lString = lTestStringRif.strToEscapedStr('\\', {'T', 'E'})
      lTestString = "\\T\\ES\\T"
    assert(lTestString == lString)
  
  test "strToEscapedStr with string":
    let 
      lTestStringRif = "TEST"
      lString = lTestStringRif.strToEscapedStr("\\TE")
      lTestString = "\\T\\ES\\T"
    assert(lTestString == lString)

  test "strToEscapedStr and escapeStrToStr":
    let 
      lTestStringRif = "a test string"
      lString = lTestStringRif.strToEscapedStr('\\', {' ', 'i'})
      lTestString = lString.escapedStrToStr('\\')
    assert(lTestString == lTestStringRif)
