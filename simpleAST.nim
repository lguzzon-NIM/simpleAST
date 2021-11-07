
import simpleAST/strProcs

when NimVersion > "0.18.0":
  {.experimental: "notnil".}

type
  SimpleASTNodeRef* = ref SimpleASTNodeObject
  SimpleASTNode* = SimpleASTNodeRef not nil
  SimpleASTNodeSeq* = seq[SimpleASTNode]
  SimpleASTNodeObject* {.final.} = object
    FName: string
    FParent: SimpleASTNodeRef
    FParentIndex: Natural
    FChildren: SimpleASTNodeSeq


template newSimpleASTNode*(aName: string = ""): SimpleASTNode =
  SimpleASTNode(FName: aName)


template name*(aSimpleASTNode: SimpleASTNode): string =
  aSimpleASTNode.FName


func value*(aSimpleASTNode: SimpleASTNode): string {.inline.} =
  let lChildren = aSimpleASTNode.FChildren
  if (0 == lChildren.len):
    result = aSimpleASTNode.name
  else:
    for lChild in lChildren:
      result &= lChild.value


func addChild*(aSimpleASTNode, aChild: SimpleASTNode): bool {.inline.} =
  result = aChild.FParent.isNil
  if result:
    aChild.FParentIndex = aSimpleASTNode.FChildren.len
    aSimpleASTNode.FChildren.add(aChild)
    aChild.FParent = aSimpleASTNode


func setValue*(aSimpleASTNode: SimpleASTNode, aValue: string): bool {.inline.} =
  result = ((0 == aSimpleASTNode.FChildren.len) and aSimpleASTNode.addChild(
      SimpleASTNode(FName: aValue)))


template parent*(aSimpleASTNode: SimpleASTNode): SimpleASTNodeRef =
  aSimpleASTNode.FParent


template parentIndex*(aSimpleASTNode: SimpleASTNode): Natural =
  aSimpleASTNode.FParentIndex


template children*(aSimpleASTNode: SimpleASTNode): SimpleASTNodeSeq =
  aSimpleASTNode.FChildren


const
  lcBackSlash = '\\'
  lcOpen = '('
  lcClose = ')'
  lcEscapeChars: set[char] = {lcOpen, lcClose}


func asASTStr*(aSimpleASTNode: SimpleASTNode): string {.inline.} =
  result = aSimpleASTNode.name.strToEscapedStr(lcBackSlash, lcEscapeChars)
  let lContinue = ("" == result) or
    (aSimpleASTNode.children.len > 0) or
    (let lRef = aSimpleASTNode.parent; ((not lRef.isNil) and
      (lRef.children.len != aSimpleASTNode.parentIndex+1)))
  if lContinue:
    result &= lcOpen
    for lChild in aSimpleASTNode.children:
      result &= lChild.asASTStr
    result &= lcClose


func asSimpleASTNode*(aASTStr: string): SimpleASTNodeRef {.inline.} =
  var lIndex = 0
  var lStartIndex = lIndex
  var lASTRootNode: SimpleASTNodeRef
  let lLen = aASTStr.len
  while lIndex < lLen:
    case aASTStr[lIndex]
    of lcOpen:
      let lASTNode = SimpleASTNode(
        FName: aASTStr.substr(lStartIndex,
                              lIndex.pred).escapedStrToStr(lcBackSlash))
      if (not lASTRootNode.isNil):
        let lAddChild = lASTRootNode.addChild(lASTNode)
        assert(lAddChild, "AddChild reurned false adding aNode")
      lASTRootNode = lASTNode
      lStartIndex = lIndex.succ
    of lcClose:
      if (not lASTRootNode.isNil):
        if (lStartIndex < lIndex.pred):
          let lAddChild = lASTRootNode.addChild(SimpleASTNode(
            FName: aASTStr.substr(lStartIndex,
                                  lIndex.pred).escapedStrToStr(lcBackSlash)))
          assert(lAddChild, "AddChild reurned false adding aNode")
        lStartIndex = lIndex.succ
        if (not lASTRootNode.parent.isNil):
          lASTRootNode = lASTRootNode.parent
        else:
          if lIndex == lLen.pred:
            result = lASTRootNode
          break
      else:
        break
    of lcBackSlash:
      lIndex.inc
    else:
      discard
    lIndex.inc
  if (lStartIndex < lIndex.pred):
    result = SimpleASTNode(
            FName: aASTStr.substr(lStartIndex,
                                  lIndex.pred).escapedStrToStr(lcBackSlash))
