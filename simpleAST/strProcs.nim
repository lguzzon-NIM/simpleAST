
import setProcs


proc strToEscapedStr*(aString: string, aEscapeChar: char, aEscapeCharSet: set[char]): string {.inline.} =
  result = newStringOfCap((aString.len * 125) div 100)
  let lEscapeCharSet = aEscapeCharSet + {aEscapeChar}
  for lChar in aString:
    if lChar in lEscapeCharSet:
      result &= aEscapeChar
    result &= lChar


proc strToEscapedStr*(aString, aEscapeChars: string): string {.inline.} =
  var lEscapeCharSet: set[char] = {}
  for lChar in aEscapeChars:
    lEscapeCharSet += lChar
  result = aString.strToEscapedStr(aEscapeChars[0], lEscapeCharSet)


proc escapedStrToStr*(aString: string, aEscapeChar: char): string {.inline.} =
  let lLen = aString.len
  result = newStringOfCap(lLen)
  var lIndex = 0
  while lIndex < lLen:
    if aString[lIndex] == aEscapeChar:
      lIndex.inc
      assert(lIndex < lLen, "escapedStrToStr: lIndex overrun aString.len")
    result &= aString[lIndex]
    lIndex.inc

