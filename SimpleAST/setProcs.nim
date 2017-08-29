

template `+=`* [T] (aSet:set[T], aValueToAdd: T) =
    aSet.incl({aValueToAdd})


template `+=`* [T] (aSet:set[T], aSetToAdd:set[T]) =
    aSet.incl(aSetToAdd)

