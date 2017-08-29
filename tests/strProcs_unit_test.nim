
import unittest
import os
import osproc
import strutils

import SimpleAst.strProcs


suite "strProcs unit-test suite":
    test "strToEscapedStr with char an set":
        let lTestStringRif = "TEST"
        let lString = lTestStringRif.strToEscapedStr('\\', {'T', 'E'})
        let lTestString = "\\T\\ES\\T"
        assert(lTestString == lString)
    test "strToEscapedStr with string":
        let lTestStringRif = "TEST"
        let lString = lTestStringRif.strToEscapedStr("\\TE")
        let lTestString = "\\T\\ES\\T"
        assert(lTestString == lString)
    test "strToEscapedStr and escapeStrToStr":
        let lTestStringRif = "a test string"
        let lString = lTestStringRif.strToEscapedStr('\\', {' ', 'i'})
        let lTestString = lString.escapedStrToStr('\\')
        assert(lTestString == lTestStringRif)
