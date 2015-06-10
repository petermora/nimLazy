import tables, lists

# Some general patterns in this code, comments:
#
# -  I avoid using "for" cycles for iterators. Although the "items" function is
#    properly defined below, the syntax might change with the language:
#    https://github.com/Araq/Nim/issues/2563
# -  I couldn't use varargs for iterators.
# -  Not much documentation right now, because this package is still experimental.
# -  Too many XDeclaredButNotUsed warning messages.


# emptyIter

proc emptyIter*[T](): iterator(): T =
  ## .. code-block:: Nim
  ##   emptyIter() ->
  result = iterator(): T {.closure.} =
    discard

when isMainModule:
  var thisIsReallyEmpty = emptyIter[int]()
  assert thisIsReallyEmpty() == 0
  assert finished(thisIsReallyEmpty) == true


# yieldAll

template yieldAll*[T](iter: iterator(): T) =
  ## .. code-block:: Nim
  ##   yieldAll(iter) -> for x in iter(): yield
  var iterCopied = iter
  var x = iterCopied()
  while not finished(iterCopied):
    yield x
    x = iterCopied()


# repeat

proc repeat*[T](value: T, n: int = -1): iterator(): T =
  ## .. code-block:: Nim
  ##   repeat(5) -> 5; 5; 5; 5; ...
  ##   repeat(5,n=2) -> 5; 5
  result = iterator(): T {.closure.} =
    var i = 0
    while n == -1 or i < n:
      yield value
      i += 1

when isMainModule:
  var allOverAgain = repeat(5)
  assert allOverAgain() == 5
  assert allOverAgain() == 5

  var allOverJustTwice = repeat(5, 2)
  assert allOverJustTwice() == 5
  assert allOverJustTwice() == 5
  assert allOverJustTwice() == 0


# count

proc count*[T](start: T): iterator(): T =
  ## .. code-block:: Nim
  ##   count(x0) -> x0; x0 + 1; x0 + 2; ...
  result = iterator(): T {.closure.} =
    var x = start
    while true:
      yield x
      x = x+1

proc count*[T](start: T, till: T, step: T = 1, includeLast = false):
                                                      iterator(): T =
  ## .. code-block:: Nim
  ##   count(x0, x1) -> x0; x0 + 1; x0 + 2; ...; x1-1
  result = iterator (): T {.closure.} =
    var x = start
    while x < till or (includeLast and x == till):
      yield x
      x = x + step


when isMainModule:
  var fromTen = count(10)
  assert fromTen() == 10
  assert fromTen() == 11
  assert fromTen() == 12

  var fromTenToThirteen = count(10, 13)
  assert fromTenToThirteen() == 10
  assert fromTenToThirteen() == 11
  assert fromTenToThirteen() == 12
  assert fromTenToThirteen() == 0
  assert finished(fromTenToThirteen)

  var fromTenToThirteenReally = count(10, 13, includeLast = true)
  assert fromTenToThirteenReally() == 10
  assert fromTenToThirteenReally() == 11
  assert fromTenToThirteenReally() == 12
  assert fromTenToThirteenReally() == 13
  assert fromTenToThirteenReally() == 0
  assert finished(fromTenToThirteenReally)

  var fromZeroToOne = count(0.0, 1.0, 0.5)
  assert fromZeroToOne() == 0.0
  assert fromZeroToOne() == 0.5
  assert fromZeroToOne() == 0.0
  assert finished(fromZeroToOne)


# cycle
# TODO: try varargs again, didn't work for iterators

proc cycle*[T](iter: iterator(): T): iterator(): T =
  ## .. code-block:: Nim
  ##   cycle(a;b;c) -> a;b;c;a;b;c;a;...
  result = iterator(): T {.closure.} =
    var cache = newSeq[T]()
    var x = iter()
    while not finished(iter):
      cache.add(x)
      yield x
      x = iter()
    while true:
      for x in cache:
        yield x

proc cycle*[T](iter: iterator(): T,
               iter2: iterator(): T): iterator(): T =
  ## .. code-block:: Nim
  ##   cycle(a;b;c,  d;e) -> a;b;c;d;e;a;b;...
  result = iterator(): T {.closure.} =
    var cache = newSeq[T]()
    var x = iter()
    while not finished(iter):
      cache.add(x)
      yield x
      x = iter()
    x = iter2()
    while not finished(iter2):
      cache.add(x)
      yield x
      x = iter2()
    while true:
      for x in cache:
        yield x

proc cycle*[T](iter: iterator(): T,
               iter2: iterator(): T,
               iter3: iterator(): T): iterator(): T =
  ## .. code-block:: Nim
  ##   cycle(a;b;c,  d;e,  f;g) -> a;b;c;d;e;f;g;a;b;...
  result = iterator(): T {.closure.} =
    var cache = newSeq[T]()
    var x = iter()
    while not finished(iter):
      cache.add(x)
      yield x
      x = iter()
    x = iter2()
    while not finished(iter2):
      cache.add(x)
      yield x
      x = iter2()
    x = iter3()
    while not finished(iter3):
      cache.add(x)
      yield x
      x = iter3()
    while true:
      for x in cache:
        yield x


when isMainModule:
  var cycleOne = count(0,2).cycle()
  assert cycleOne() == 0
  assert cycleOne() == 1
  assert cycleOne() == 0
  assert cycleOne() == 1

  var cycleTwo = cycle(count(0,2), repeat(5,2))
  assert cycleTwo() == 0
  assert cycleTwo() == 1
  assert cycleTwo() == 5
  assert cycleTwo() == 5
  assert cycleTwo() == 0
  assert cycleTwo() == 1


# nop

proc nop*[T](iter: iterator(): T): iterator(): T =
  ## .. code-block:: Nim
  ##   nop(a;b;c;...) -> a;b;c;...
  result = iterator(): T {.closure.} =
    var x = iter()
    while not finished(iter):
      yield x
      x = iter()


when isMainModule:
  var fromTenAgain = count(10)
  assert fromTenAgain() == 10
  assert fromTenAgain.nop()() == 11
  assert fromTenAgain() == 12


# items

iterator items*[T](iter: iterator(): T): T =
  ## .. code-block:: Nim
  ##   items(a;b;c;...) -> yield a; yield b; yield c; ...
  var x = iter()
  while not finished(iter):
    yield x
    x = iter()

when isMainModule:
  var s = newSeq[int]()
  var i = 0
  for x in count(0,10): # implicitly calls items
    s.add(x)
    if i > 20:
      break
    i += 1
  assert s == @[0,1,2,3,4,5,6,7,8,9]


# len

proc len*[T](iter: iterator(): T): int =
  ## .. code-block:: Nim
  ##   len(a;b;c;d) -> 4
  discard iter()
  while not finished(iter):
    result += 1
    discard iter()

when isMainModule:
  assert count(0, 10).len == 10
  assert count(0, 0).len == 0

  

# toSeq

proc toSeq*[T](iter: iterator(): T, limit:int = -1): seq[T] =
  ## .. code-block:: Nim
  ##   toSeq(1;2;3) -> @[1,2,3]
  result = newSeq[T]()
  var x = iter()
  var i = 0
  while not finished(iter) and (limit == -1 or i < limit):
    result.add(x)
    x = iter()
    i += 1

when isMainModule:
  assert count(0).toSeq(limit=5) == @[0, 1, 2, 3, 4]

# reverse

proc reverse*[T](iter: iterator(): T): iterator(): T =
  ## .. code-block:: Nim
  ##    reverse(1;2;3) -> 3;2;1
  result = iterator(): T {.closure.}=
    let s = iter.toSeq
    for i in countdown(s.len-1, 0):
      yield s[i]

when isMainModule:
  assert count(5,10).reverse.toSeq() == @[9, 8, 7, 6, 5]


# $

proc `$`*[T](iter: iterator(): T, limit = 10): string =
  ## .. code-block:: Nim
  ##   $(1;2;3) -> "toIter(@[1, 2, 3])"
  var iterCopied: type(iter)
  deepCopy(iterCopied, iter)
  result = "toIter(" & $toSeq(iterCopied, limit = limit)
  if not finished(iterCopied) and result.len > 0:
    result[result.len-1] = ','
    result = result & " ...]"
  result = result & ")"

when isMainModule:
  let goingToPrint = count(0,3)
  assert `$`(goingToPrint) == "toIter(@[0, 1, 2])"

# first

proc first*[T](iter: iterator(): T): T=
  ## .. code-block:: Nim
  ##   first(a;b;c;d) -> a
  result = iter()
  if finished(iter):
    raise newException(ValueError, "No first item to get")

proc first*[T](iter: iterator(): T, default: T): T=
  ## .. code-block:: Nim
  ##   first(a;b;c;d) -> a
  ##   first(emptyIter(), default=99) -> 99
  result = iter()
  if finished(iter):
    result = default

when isMainModule:
  var fromAHoundred = count(100,102)
  assert fromAHoundred.first() == 100
  assert fromAHoundred.first(99) == 101
  assert fromAHoundred.first(99) == 99


# last

proc last*[T](iter: iterator(): T): T=
  ## .. code-block:: Nim
  ##   last(a;b;c;d) -> d
  var x = iter()
  if finished(iter):
    raise newException(ValueError, "No last item to get")
  while not finished(iter):
    result = x
    x = iter()
 
proc last*[T](iter: iterator(): T, default: T): T=
  ## .. code-block:: Nim
  ##   last(a;b;c;d) -> d
  ##   last(emptyIter(), default=99) -> 99
  var x = iter()
  if finished(iter):
    return default
  while not finished(iter):
    result = x
    x = iter()

when isMainModule:
  assert count(100,110).last() == 109
  assert emptyIter[int]().last(99) == 99


# peek

proc peek*[T](iter: iterator(): T): T=
  ## .. code-block:: Nim
  ##   peek(a;b;c;d) -> a    (without removing)
  var iterCopied: iterator(): T
  deepCopy(iterCopied, iter)
  result = iterCopied()
  if finished(iterCopied):
      raise newException(ValueError, "No first item to peek")

proc peek*[T](iter: iterator(): T, default: T): T=
  ## .. code-block:: Nim
  ##   peek(a;b;c;d) -> a    (without removing)
  ##   peek(emptyIter(), default=99) -> 99
  var iterCopied: iterator(): T
  deepCopy(iterCopied, iter)
  result = iterCopied()
  if finished(iterCopied):
    result = default


when isMainModule:
  var peekableNumbers = count(0)
  assert peekableNumbers() == 0
  assert peekableNumbers.peek() == 1
  assert peekableNumbers.peek() == 1
  assert peekableNumbers() == 1
  assert peekableNumbers() == 2

  var onlyThree = count(0,3)
  assert onlyThree() == 0
  assert onlyThree() == 1
  assert onlyThree() == 2
  assert onlyThree.peek(99) == 99
  assert finished(onlyThree) == false
  assert onlyThree() == 0
  assert onlyThree.peek(123) == 123
  assert finished(onlyThree) == true


# peekList

proc peekList*[T](iter: iterator(): T, n: int): seq[T] =
  ## .. code-block:: Nim
  ##   peekList(a;b;c;d, 2) -> @[a,b]    (without removing)
  var iterCopied: iterator(): T
  deepCopy(iterCopied, iter)
  result = newSeq[T]()
  var x = iterCopied()
  while not finished(iterCopied) and result.len < n:
    result.add(x)
    if result.len < n:
      x = iterCopied()


when isMainModule:
  var wePeekSoMuch = count(0)
  assert wePeekSoMuch.peekList(5) == @[0,1,2,3,4]
  assert wePeekSoMuch.peekList(5) == @[0,1,2,3,4]
  var wePeekTooMuch = count(0,3)
  assert wePeekTooMuch.peekList(5) == @[0,1,2]
  assert wePeekTooMuch.peekList(5) == @[0,1,2]

# hasNext

proc hasNext*[T](iter: var iterator(): T): bool=
  ## .. code-block:: Nim
  ##   hasNext(a;b;c;d) -> true    (without removing)
  ##   hasNext(emptyIter())        -> false
  var iterCopied: iterator(): T
  deepCopy(iterCopied, iter)
  discard iterCopied()
  return not finished(iterCopied)


when isMainModule:
  var count02 = count(0,2)
  assert count02.hasNext == true
  assert count02() == 0
  assert count02() == 1
  assert count02.finished == false
  assert count02.hasNext == false
  assert count02.finished == false
  assert count02() == 0
  assert count02.finished == true
  assert count02.hasNext == false
  assert count02.finished == true


# print

proc print*[T](iter: iterator(): T, comment: string = ""): iterator(): T =
  ## .. code-block:: Nim
  ##   print(a;b;c;d) -> a;b;c;d    (and also printing)
  var quotedComment = comment
  if comment != "":
    quotedComment = "\"" & comment & "\" "
  let (file, line) = instantiationInfo()
  result = iterator(): T =
    var x = iter()
    while not finished(iter):
      echo "DEBUG: ", quotedComment ,"@", file, "(", line, "): ", x
      yield x
      x = iter()

# general macros for injecting variables
import macros

macro injectParam(w: expr, value: expr): stmt =
  result = newNimNode(nnkStmtList)
  var varSection = newNimNode(nnkVarSection)
  if w.len == 0:
    varSection.add(newIdentDefs(ident($w), newEmptyNode(), value))
  else:
    for i in 0..<w.len:
      if w[i].len == 0:
        varSection.add(newIdentDefs(ident($w[i]), newEmptyNode(),
          newNimNode(nnkBracketExpr).add(value, newLit(i))))
      else:
        for j in 0..<w[i].len:
          varSection.add(newIdentDefs(ident($w[i][j]), newEmptyNode(),
            newNimNode(nnkBracketExpr).add(
              newNimNode(nnkBracketExpr).add(value, newLit(i)),
              newLit(j))))
  add(result, varSection)

macro toTuple(w: expr, value: expr, n: int): stmt =
  result = newNimNode(nnkStmtList)
  var varSection = newNimNode(nnkVarSection)
  var par = newNimNode(nnkPar)
  for i in 0..<n.intVal:
    par.add(newNimNode(nnkBracketExpr).add(value, newLit(i)))
  varSection.add(newIdentDefs(ident($w), newEmptyNode(), par))
  add(result, varSection)


# iterate

proc iterate*[T](f: proc(anything: T): T, x0: T): iterator(): T =
  ## .. code-block:: Nim
  ##   iterate(f, x0) -> x0; f(x0); f(f(x0)); ...
  result = iterator(): T {.closure.}=
    var x = x0
    while true:
      yield x
      x = f(x)

template iterateP*[T](params, f: expr, x0: T): iterator(): T =
  ## .. code-block:: Nim
  ##   iterateP(a, a+10, x0) -> x0; x0+10; x0+10+10; ...
  var index = 1
  type T = type(x0)
  iterate(proc(x: T): T =
    injectParam(params, x); var idx{.inject.}=index; index+=1; f, x0)

template iterateIt*[T](f: expr, x0: T): (iterator(): T) =
  ## .. code-block:: Nim
  ##   iterateIt(it*2, x0) -> x0; x0*2; x0*2*2; ...
  iterateP(it, f, x0)

template iterateKV*[T,S](f: expr, x0: (T, S)):
                              (iterator(): (T, S)) =
  ## .. code-block:: Nim
  ##   iterateKV((2*k, 3*v), (1,1)) -> (1,1); (2,3); (4,9); ...
  iterateP((k,v), f, x0)


when isMainModule:
  var posNumbers = iterate(proc (x: int): int = x+1, 1)
  assert posNumbers() == 1
  assert posNumbers() == 2
  assert posNumbers() == 3

  var evenNumbers = iterateIt(it+2, 0)
  assert evenNumbers() == 0
  assert evenNumbers() == 2
  assert evenNumbers() == 4

  var evenNumbers2 = iterateIt(it+2, 0) # recheck, templates are tricky
  assert evenNumbers2() == 0
  assert evenNumbers2() == 2
  assert evenNumbers2() == 4

  var squareNumbers = iterateIt(it+2*idx-1, 0) # the square numbers
  assert squareNumbers() == 0
  assert squareNumbers() == 1
  assert squareNumbers() == 4
  assert squareNumbers() == 9

# take

proc take*[T](iter: iterator(): T, n: int): iterator(): T =
  ## .. code-block:: Nim
  ##   take(1;2;3;4, 3) -> 1;2;3
  ##   take(1;2, 3) -> 1;2
  result = iterator(): T {.closure.}=
    var i = 0
    while i < n:
      i += 1
      var r = iter()
      if finished(iter):
        break
      yield r

when isMainModule:
  var firstThree = count(0).take(3)
  assert firstThree() == 0
  assert firstThree() == 1
  assert firstThree() == 2
  assert firstThree() == 0
  assert finished(firstThree)


# takeWhile

proc takeWhile*[T](iter: iterator(): T, cond: proc(x: T):bool): iterator(): T =
  ## .. code-block:: Nim
  ##  takeWhile(1;2;3;4, proc(x: int): bool = x < 4) -> 1;2;3
  result = iterator(): T {.closure.}=
    var r = iter()
    while not finished(iter) and cond(r):
      yield r
      r = iter()

template takeWhileP*[T](iter: iterator(): T, params, cond: expr): iterator(): T =
  ## .. code-block:: Nim
  ##  takeWhile(1;2;3;4, Q, Q < 4) -> 1;2;3
  var index = 0
  type T = type((var copied = iter; copied()))
  takeWhile(iter, proc(x: T): bool =
    injectParam(params, x); var idx{.inject.}=index; index+=1; cond)

template takeWhileIt*[T](iter: iterator(): T, cond: expr): iterator(): T =
  ## .. code-block:: Nim
  ##   takeWhileIt(1;2;3;4, it < 4) -> 1;2;3
  takeWhileP(iter, it, cond)

# (1;2;3;4, proc(x: int): bool = x < 4) -> 1;2;3
template takeWhileKV*[T](iter: iterator(): T, cond: expr): iterator(): T =
  ## .. code-block:: Nim
  ##   takeWhileKV((1,2);(1,3);(10;4), k == 1) -> (1,2);(1;3)
  takeWhileP(iter, (k,v), cond)

when isMainModule:
  var lessThanFour = count(0).takeWhile(proc(x: int): bool = x<4)
  assert lessThanFour() == 0
  assert lessThanFour() == 1
  assert lessThanFour() == 2
  assert lessThanFour() == 3
  assert lessThanFour() == 0
  assert finished(lessThanFour)

  assert count(1).takeWhileIt(it mod 5 != 0).toSeq() == @[1,2,3,4]
  assert count(1).takeWhileIt(it mod 5 != 0).toSeq() == @[1,2,3,4]

  assert iterateIt((idx,2*idx), (0,0)).takeWhileKV(k+5 > v).toSeq() ==
    @[(0,0), (1,2), (2,4), (3,6), (4,8)]

# takeLast

proc takeLast*[T](iter: iterator(): T, n: int = 1): iterator(): T =
  ## .. code-block:: Nim
  ##   takeLast(1;2;3;4;5, 3) -> 3;4;5
  ##   takeLast(1;2, 3) -> 1;2
  result = iterator(): T {.closure.}=
    var lastItems = newSeq[T]()
    var i = 0
    var x = iter()
    while not finished(iter):
      if lastItems.len < n:
        lastItems.add(x)
      else:
        lastItems[i] = x
        i += 1
        if i == n:
          i = 0
      x = iter()
    var j = i
    if lastItems.len > 0:
      yield lastItems[j]
      j += 1
      if j == n:
        j = 0
      while j != i:
        yield lastItems[j]
        j += 1
        if j == n:
          j = 0


when isMainModule:
  var getLastTwo = count(100, 105).takeLast(2)
  assert getLastTwo() == 103
  assert getLastTwo() == 104
  assert getLastTwo() == 0
  assert finished(getLastTwo)


# drop

proc drop*[T](iter: iterator(): T, n: int = 1): iterator(): T =
  ## .. code-block:: Nim
  ##   drop(1;2;3;4;5, 3) -> 4;5
  ##   drop(1;2, 3) -> 
  result = iterator(): T {.closure.}=
    var i = 0
    var x = iter()
    while not finished(iter):
      if i >= n:
        yield x
      i += 1
      x = iter()

when isMainModule:
  var skipThree = count(0).drop(3)
  assert skipThree() == 3
  assert skipThree() == 4


# dropWhile

proc dropWhile*[T](iter: iterator(): T, cond: proc(x: T):bool): iterator(): T =
  ## .. code-block:: Nim
  ##   dropWhile(1;2;3;4, proc(x: int): bool = x < 4) -> 1;2;3
  result = iterator(): T {.closure.}=
    var r = iter()
    while not finished(iter) and cond(r):
      r = iter()
    while not finished(iter):
      yield r
      r = iter()

template dropWhileP*[T](iter: iterator(): T, params, cond: expr): iterator(): T =
  ## .. code-block:: Nim
  ##   dropWhileP(1;2;3;4, Q, Q < 4) -> 1;2;3
  var index = 0
  type T = type((var copied = iter; copied()))
  dropWhile(iter, proc(x: T): bool =
    injectParam(params, x); var idx{.inject.}=index; index+=1; cond)

template dropWhileIt*[T](iter: iterator(): T, cond: expr): iterator(): T =
  ## .. code-block:: Nim
  ##   dropWhileIt(1;2;3;4, proc(x: int): bool = x < 4) -> 1;2;3
  dropWhileP(iter, it, cond)

template dropWhileKV*[T](iter: iterator(): T, cond: expr): iterator(): T =
  ## .. code-block:: Nim
  ##   dropWhileKV((1,2);(1,3);(10,4), v == 2) -> (1,3);(10,4)
  dropWhileP(iter, (k,v), cond)

when isMainModule:
  var atLeastFour = count(0).dropWhile(proc(x: int): bool = x<4)
  assert atLeastFour() == 4
  assert atLeastFour() == 5
  assert atLeastFour() == 6

  assert count(1).dropWhileIt(it mod 5 != 0).toSeq(limit=3) == @[5,6,7]

  assert iterateIt((idx,2*idx), (0,0)).dropWhileKV(k+5 > v).first() == (5,10)

# dropLast

proc dropLast*[T](iter: iterator(): T, n: int = 1): iterator(): T =
  ## .. code-block:: Nim
  ##   dropLast(1;2;3;4;5, 3) -> 1;2
  ##   dropLast(1;2, 3) -> 
  result = iterator(): T {.closure.}=
    var lastItems = newSeq[T]()
    var x = iter()
    while not finished(iter) and lastItems.len < n:
      lastItems.add(x)
      x = iter()
    if lastItems.len == n:
      var i = 0
      while not finished(iter):
        yield lastItems[i]
        lastItems[i] = x
        i += 1
        if i == n:
          i = 0
        x = iter()


when isMainModule:
  var skipLastThree = count(100, 105).dropLast(2)
  assert skipLastThree() == 100
  assert skipLastThree() == 101
  assert skipLastThree() == 102
  assert skipLastThree() == 0
  assert finished(skipLastThree)


# toTable

proc toTable*[A,B](iter: iterator(): (A,B)): Table[A,B] =
  ## .. code-block:: Nim
  ##   toTable((1,"A");(2,"B");(3,"C")) -> {1: "A", 2: "B", 3: "C"}
  result = initTable[A,B]()
  var x = iter()
  while not finished(iter):
    result[x[0]] = x[1]
    x = iter()

proc toTable*[A,B](iter: iterator(): (A,B),
      aggr: proc(any1, any2: B): B): Table[A,B] =
  ## .. code-block:: Nim
  ##   toTable((1,"A");(2,"B");(3,"C"), (x, y:string) => x&","&y) 
  ##                              -> {1: "A", 2: "B", 3: "C"}
  result = initTable[A,B]()
  var x = iter()
  while not finished(iter):
    if not result.hasKey(x[0]):
      result[x[0]] = x[1]
    else:
      result[x[0]] = aggr(result[x[0]], x[1])
    x = iter()

proc toTableSeq*[A,B](iter: iterator(): (A,B)): Table[A,seq[B]] =
  ## .. code-block:: Nim
  ##   toTableSeq((1,"A");(1,"B");(3,"C")) -> {1: ["A", "B"], 3: ["C"]}
  result = initTable[A,seq[B]]()
  var x = iter()
  while not finished(iter):
    if not result.hasKey(x[0]):
      result[x[0]] = newSeq[B]()
    result.mget(x[0]).add(x[1])
    x = iter()

template toTableP*[A,B](iter: iterator(): (A,B), params, f: expr):
                                                            Table[A,B] =
  ## .. code-block:: Nim
  ##   toTableP((1,"A");(1,"B");(3,"C"), (A,B), A&B) -> {1: "AB", 3: "C"}
  type B = type((var copied = iter; copied()[1]))
  toTable(iter, proc(a, b: B): B =
    injectParam(params, [a,b]); f)


template toTableAB*[A,B](iter: iterator(): (A,B), f: expr): Table[A,B] =
  ## .. code-block:: Nim
  ##   toTableP((1,"A");(1,"B");(3,"C"), a&b) -> {1: "AB", 3: "C"}
  toTableP(iter, (a,b), f)

when isMainModule:
  iterator tableIterator(): (string, string) {.closure.} =
    yield ("Hungary", "Budapest")
    yield ("USA", "Washington")

  assert toTable(tableIterator)["Hungary"] == "Budapest"

  iterator overlappingValues(): (int, string) {.closure.} =
    yield (1, "A")
    yield (1, "B")
    yield (3, "C")
  assert overlappingValues.toTableSeq()[1] == @["A", "B"]
  assert overlappingValues.toTableAB(a&", "&b)[1] == "A, B"

# toIter

proc toIter*[T](s: openArray[T]): iterator(): T =
  ## .. code-block:: Nim
  ##   toIter([1,2,3]) -> 1;2;3
  result = iterator(): T {.closure.}=
    for x in s:
      yield x


proc toIter*[T](s: seq[T]): iterator(): T =
  ## .. code-block:: Nim
  ##   toIter(@[1,2,3]) -> 1;2;3
  result = iterator(): T {.closure.}=
    for x in s:
      yield x

proc toIter*[A, B](t: Table[A, B]): (iterator(): (A, B)) =
  ## .. code-block:: Nim
  ##   toIter({1:"A", 2:"B"}) -> (1,"A");(2,"B")
  result = iterator(): (A, B) {.closure.} =
    for key, value in pairs(t):
      yield (key, value)

when isMainModule:
  assert take(@[1,2,3,4,5].toIter(), 3).toSeq() == @[1,2,3]
  
  var simpleTable = initTable[string, string]()
  simpleTable["one"] = "first number"
  simpleTable["two"] = "second number"
  assert simpleTable.toIter().len == 2


# filter

proc filter*[T](iter: iterator(): T, f: (proc(any :T):bool) ): iterator(): T =
  ## .. code-block:: Nim
  ##   filter(1;2;3;4;5, proc(x: int): bool = x>3) -> 4;5
  result = iterator(): T {.closure.}=
    var x = iter()
    while not finished(iter):
      if f(x):
        yield x
      x = iter()

template filterP*[T](iter: iterator(): T, params, f: expr): iterator(): T =
  ## .. code-block:: Nim
  ##   filter(1;2;3;4;5, Q, Q>3) -> 4;5
  var index = 0
  type T = type((var copied = iter; copied()))
  filter(iter, proc(x: T): bool =
    injectParam(params, x); var idx{.inject.} = index; index+=1; f)

template filterIt*[T](iter: iterator(): T, f: expr): iterator(): T =
  ## .. code-block:: Nim
  ##   filterIt(1;2;3;4;5, it>3) -> 4;5
  filterP(iter, it, f)


template filterKV*[A,B](iter: iterator(): (A,B), f: expr): iterator(): (A,B) =
  ## .. code-block:: Nim
  ##   filterKV(("one", 1);("two", 2);("three", 3), v>1)
  ##                                    -> ("two", 2);("three", 3)
  filterP(iter, (k,v), f)

when isMainModule:
  var oddNumbers = count(0).filter(proc (x: int): bool = x mod 2==1)
  assert oddNumbers() == 1
  assert oddNumbers() == 3
  assert oddNumbers() == 5

  var multipliesOfFive = count(0).filterIt(it mod 5 == 0)
  assert multipliesOfFive() == 0
  assert multipliesOfFive() == 5
  assert multipliesOfFive() == 10

  var multipliesOfFive2 = count(0).filterIt(it mod 5 == 0) #recheck
  assert multipliesOfFive2() == 0
  assert multipliesOfFive2() == 5
  assert multipliesOfFive2() == 10

  var skipFirstFive = count(0).filterIt(idx >= 5)
  assert skipFirstFive() == 5
  assert skipFirstFive() == 6
  assert skipFirstFive() == 7

  var numbersTable = initTable[string, int]()
  numbersTable["one"] = 1
  numbersTable["two"] = 2
  numbersTable["three"] = 3
  assert numbersTable.toIter().filterKV(v>1).len == 2
  assert numbersTable.toIter().filterKV(k == "one").len == 1
  assert numbersTable.toIter().filterIt(it[0]== "one").len == 1


# map

proc map*[T,S](iter: iterator(): T, f: (proc(any: T): S) ): iterator(): S =
  ## .. code-block:: Nim
  ##   map(1;2;3;4;5, f) -> f(1);f(2);f(3);f(4);f(5)
  result = iterator(): S {.closure.}=
    var x = iter()
    while not finished(iter):
      yield f(x)
      x = iter()

template mapP*[T,S](iter: iterator(): T, params, f: expr): iterator(): S =
  ## .. code-block:: Nim
  ##   mapP(1;2;3;4;5, Q, Q+10) -> 11;12;13;14;15
  var index = 0
  type T = type((var copied = iter; copied()))
  type S = type((
    block:
      var empty: T
      injectParam(params, empty)
      var idx{.inject.} = 0;
      f))
  map(iter, proc(x: T): S =
    injectParam(params, x); var idx{.inject.}=index; index+=1; f)

template mapIt*[T,S](iter: iterator(): T, f: expr): iterator(): S =
  ## .. code-block:: Nim
  ##   mapIt(1;2;3;4;5, it+10) -> 11;12;13;14;15
  mapP(iter, it, f) 

template mapKV*[A,B,T](iter: iterator(): (A,B), f: expr):
                                                  iterator(): T =
  ## .. code-block:: Nim
  ##   mapKV(("one", 1);("two", 2);("three", 3), v) -> 1;2;3
  mapP(iter, (k, v), f)

when isMainModule:
  var toString = count(0).map(proc(x: int): string = $x)
  assert toString() == "0"
  assert toString() == "1"
  assert toString() == "2"

  var toString2 = count(0).mapIt($it)
  var copiedStringIter: iterator(): string
  deepCopy(copiedStringIter, toString2)
  assert toString2() == "0"
  assert toString2() == "1"
  assert toString2() == "2"
  assert copiedStringIter() == "0"
  assert copiedStringIter() == "1"

  var toString3 = count(0).mapIt($it) # recheck
  assert toString3() == "0"
  assert toString3() == "1"
  assert toString3() == "2"

  # special case, the original iterator is a variable.
  # This case is the reason for the wrapper function.
  # The deepCopy seems to be broken...
  var fromVariable = count(0)
  var firstCopy = fromVariable.mapIt(10+it)
  var secondCopy: iterator(): int
  deepCopy(secondCopy, firstCopy)
  assert firstCopy() == secondCopy()

  var fruitsOrder = initTable[string, int]()
  fruitsOrder["banana"] = 2
  fruitsOrder["apple"] = 3
  fruitsOrder["kiwi"] = 1
  assert fruitsOrder.toIter.mapKV((v,k)).toTable()[2] == "banana"


# map for 2

proc map*[T,S,U](iter: iterator(): T, f: (proc(anyT: T, anyU: U):S),
                 iter2: iterator(): U): iterator(): S =
  ## .. code-block:: Nim
  ##   map(1;2;3;4;5, f, 10;20;30) -> f(1,10);f(2,20);f(3,30)
  result = iterator(): S {.closure.}=
    var x = iter()
    var y = iter2()
    while not finished(iter) and not finished(iter2):
      yield f(x,y)
      x = iter()
      y = iter2()

when isMainModule:
  assert count(1).map(proc (x, y: int): int = x+y, count(10, 40, 10)).toSeq ==
      @[11,22,33]

# (1;2;3;4;5, p, f which uses p) -> f(1);f(2);f(3);f(4);f(5)
template mapP*[T,S,U](iter: iterator(): T, params, f: expr,
                      iter2: iterator(): U): iterator(): S =
  ## .. code-block:: Nim
  ##   map(1;2;3;4;5, (P,Q), P+Q, 10;20;30) -> 11,22,33
  var index = 0
  type T = type((var copied = iter; copied()))
  type U = type((var copied = iter2;copied()))
  type S = type((
    block:
      var empty: T
      var empty2: U
      injectParam(params, (empty, empty2))
      var idx{.inject.} = 0;
      f))
  map(iter, proc(x: T, y: U): S =
    injectParam(params, (x,y)); var idx{.inject.}=index; index+=1; f, iter2)

when isMainModule:
  assert count(1).mapP((P,Q), P+Q, count(10, 40, 10)).toSeq ==
      @[11,22,33]

# (1;2;3;4;5, f) -> f(1);f(2);f(3);f(4);f(5)
template mapIt*[T,S,U](iter: iterator(): T, f: expr,
                       iter2: iterator(): U): iterator(): S =
  ## .. code-block:: Nim
  ##   map(1;2;3;4;5, it+it2, 10;20;30) -> 11,22,33
  mapP(iter, (it, it2), f, iter2)

template mapKV*[A,B,C,D,T](iter: iterator(): (A,B), f: expr,
                       iter2: iterator(): (C,D)): iterator(): T =
  ## .. code-block:: Nim
  ##   map((1,a);(2,b), (k,v2), (10,A);(20,B)) -> (1,A);(2,B)
  mapP(iter, ((k,v), (k2,v2)), f, iter2)

when isMainModule:
  var toStringForTwo = count(0).map(proc(x, y: int): string = $x & $y, count(5))
  assert toStringForTwo() == "05"
  assert toStringForTwo() == "16"
  assert toStringForTwo() == "27"

  var toStringForTwo2 = count(0).mapIt($it & $it2, count(5))
  assert toStringForTwo2() == "05"
  assert toStringForTwo2() == "16"
  assert toStringForTwo2() == "27"

  var toStringForTwo3 = count(0).mapIt($it & $it2, count(5))
  assert toStringForTwo3() == "05"
  assert toStringForTwo3() == "16"
  assert toStringForTwo3() == "27"

  var mixLetters = @[("a","b"), ("c","d"), ("e","f")]
  var mixNumbers = @[(1,2), (3,4), (5,6)]
  assert mixLetters.toIter.mapKV((k&v, 10*k2+v2),
      mixNumbers.toIter).toTable()["cd"] == 34


# map for 3

proc map*[T,S,U,V](iter: iterator(): T, f: (proc(anyT: T, anyU: U, anyV: V):S),
                 iter2: iterator(): U, iter3: iterator(): V): iterator(): S =
  ## Map for 3 parameters
  result = iterator(): S {.closure.}=
    var x = iter()
    var y = iter2()
    var z = iter3()
    while not finished(iter) and not finished(iter2) and not finished(iter3):
      yield f(x,y,z)
      x = iter()
      y = iter2()
      z = iter3()

template mapP*[T,S,U,V](iter: iterator(): T, params, f: expr,
                 iter2: iterator(): U, iter3: iterator(): V): iterator(): S =
  ## Map for 3 parameters
  var index = 0
  type T = type((var copied = iter; copied()))
  type U = type((var copied = iter2;copied()))
  type V = type((var copied = iter3;copied()))
  type S = type((
    block:
      var empty: T
      var empty2: U
      var empty3: V
      injectParam(params, (empty, empty2, emtpy3))
      var idx{.inject.} = 0;
      f))
  map(iter, proc(x: T, y: U, z: V): S =
    injectParam(params, (x,y,z)); var idx{.inject.}=index; index+=1; f, iter2)

# (1;2;3;4;5, f) -> f(1);f(2);f(3);f(4);f(5)
template mapIt*[T,S,U,V](iter: iterator(): T, f: expr,
                iter2: iterator(): U, iter3: iterator(): V): iterator(): S =
  ## Map for 3 parameters
  mapP(iter, (it,it2,it3), f, iter2, iter3)

template mapKV*[A,B,C,D,E,F,T](iter: iterator(): (A,B), f: expr,
          iter2: iterator(): (C,D), iter3: iterator(): (E,F)): iterator(): T =
  ## Map for 3 parameters
  mapP(iter, ((k,v), (k2,v2), (k3,v3)), iter2, iter3)


# replace

proc replace*[T](iter: iterator(): T, n: int, value: T): iterator(): T =
  ## .. code-block:: Nim
  ##   replace(1;2;3;4;5, 3, 100) -> 1;2;3;100;5
  result = iterator(): T {.closure.}=
    var x = iter()
    var i = 0;
    while not finished(iter):
      if i == n:
        yield value
      else:
        yield x
      x = iter()
      i += 1

proc replace*[T](iter: iterator(): T, f: proc(x: T): bool, value: T):
                                            iterator(): T =
  ## .. code-block:: Nim
  ##   replace(1;2;3;4;5, f, 100) -> 1;2;3;100;5  (if f(4) is the only true)
  result = iterator(): T {.closure.}=
    var x = iter()
    while not finished(iter):
      if f(x):
        yield value
      else:
        yield x
      x = iter()

proc replace*[T](iter: iterator(): T, f: proc(x: T): bool,
                              valueF: proc(x: T): T):
                                            iterator(): T =
  ## .. code-block:: Nim
  ##   replace(1;2;3;4;5, f, g) -> 1;2;3;g(4);5  (if f(4) is the only true)
  result = iterator(): T {.closure.}=
    var x = iter()
    var i = 0;
    while not finished(iter):
      if f(x):
        yield valueF(x)
      else:
        yield x
      x = iter()
      i += 1


template replaceP*[T](iter: iterator(): T, params, f: expr, value: T):
                                            iterator(): T =
  ## .. code-block:: Nim
  ##   replace(1;2;3;4;5, Q, Q==4, 100) -> 1;2;3;100;5
  var index = 0
  type T = type((var copied = iter; copied()))
  replace(iter, proc(x: T): bool =
    injectParam(params, x); var idx{.inject.}=index; index+=1; f, value)

template replacePV*[T](iter: iterator(): T, params, f: expr, valueF: expr):
                                            iterator(): T =
  ## .. code-block:: Nim
  ##   replace(1;2;3;4;5, Q, Q==4, Q+100) -> 1;2;3;104;5
  var index = 0
  type T = type((var copied = iter; copied()))
  replace(iter, proc(x: T): bool =
    injectParam(params, x); var idx{.inject.}=index; index+=1; f,
    proc(x: T): T =
      injectParam(params, x); var idx{.inject.}=index; index+=1; valueF)

template replaceIt*[T](iter: iterator(): T, f: expr, value: expr):
                                                        iterator(): T =
  ## .. code-block:: Nim
  ##   replaceIt(1;2;3;4;5, it>2, 200) -> 1;2;200;200;200
  replaceP(iter, it, f, value)


template replaceKV*[A,B](iter: iterator(): (A,B), f: expr, valueF: expr):
                                                      iterator(): (A,B) =
  ## .. code-block:: Nim
  ##   replaceKV(("one", 1);("two", 2);("three", 3), k=="one", (k, 100)) ->
  ##                               ("one", 100);("two", 2);("three", 3)
  replacePV(iter, (k,v), f, valueF)

when isMainModule:
  assert count(0).replace(3, 100).toSeq(5) == @[0,1,2,100,4]
  assert count(0).replaceIt(it>2, 200).toSeq(5) == @[0,1,2,200,200]

# flatten

proc flatten*[T](iter: iterator(): iterator(): T): iterator(): T =
  ## .. code-block:: Nim
  ##   flatten((1;2;3);(10;11;12)) -> 1;2;3;10;11;12
  result = iterator(): T {.closure.}=
    var it = iter()
    while not finished(iter):
      var x = it()
      while not finished(it):
        yield x
        x = it()
      it = iter()

when isMainModule:
  var counting = count(0).mapIt(count(0,it)).flatten().take(10)
    .toSeq() == @[0,0,1,0,1,2,0,1,2,3]


# concat

proc concat*[T](iter: iterator(): T, iter2: iterator(): T): iterator(): T =
  ## .. code-block:: Nim
  ##   concat(1;2;3), (10;11;12) -> 1;2;3;10;11;12
  result = iterator(): T {.closure.}=
    iter.yieldAll
    iter2.yieldAll

#proc concat*[T](iters: varargs[iterator(): T]): iterator(): T =
#  ## .. code-block:: Nim
#  ##   concat(1;2;3), (10;11;12) -> 1;2;3;10;11;12
#  result = iterator(): T {.closure.}=
#    for i in 0..<iters.len:
#      var x = iters[i]()
#      while not finished(iters[i]):
#        yield x
#        x = iters[i]()

when isMainModule:
  assert count(1,4).concat(count(0,3)).toSeq() == @[1,2,3,0,1,2]


# unique

proc unique*[T](iter: iterator(): T): iterator(): T =
  ## .. code-block:: Nim
  ##   unique(1;2;4;3;2;6;5) -> 1;2;4;3;6;5
  result = iterator(): T {.closure.}=
    var x = iter()
    var table = initTable[T,int]()
    while not finished(iter):
      if not table.hasKey(x):
        yield x
        table[x] = 0
      x = iter()

proc unique*[T,S](iter: iterator(): T, f: proc(any: T): S): iterator(): T =
  ## .. code-block:: Nim
  ##   unique(1;2;4;3;2;6;5, proc(x: int):int = x div 5) -> 1;6
  result = iterator(): T {.closure.}=
    var x = iter()
    var table = initTable[S,int]()
    while not finished(iter):
      var y = f(x)
      if not table.hasKey(y):
        yield x
        table[y] = 0
      x = iter()


# (1;2;3;4;5, p, f which uses p) -> f(1);f(2);f(3);f(4);f(5)
template uniqueP*[T](iter: iterator(): T, params, f: expr): iterator(): T =
  ## .. code-block:: Nim
  ##   unique(1;2;4;3;2;6;5, Q, Q div 5) -> 1;6
  var index = 0
  type T = type((var copied = iter; copied()))
  type S  = type((
    block:
      var empty: T
      injectParam(params, empty)
      var idx{.inject.} = 0;
      f))
  unique(iter, proc(x: T): S =
    injectParam(params, x); var idx{.inject.}=index; index+=1; f)

template uniqueIt*[T](iter: iterator(): T, f: expr): iterator(): T =
  ## .. code-block:: Nim
  ##   unique(1;2;4;3;2;6;5, it div 5) -> 1;6
  uniqueP(iter, it, f)

template uniqueKV*[T](iter: iterator(): T, f: expr): iterator(): T =
  ## .. code-block:: Nim
  ##   unique((1,A);(2,B);(3,B), v) -> (1,A);(2;B)
  uniqueP(iter, (k,v), f)

when isMainModule:
  assert count(5,8).concat(count(4,9)).unique().toSeq() == @[5,6,7,4,8]
  assert count(0).uniqueIt(it div 10).toSeq(3) == @[0,10,20]


# copy

proc copy*[T](iter: iterator(): T): iterator(): T =
  ## .. code-block:: Nim
  ##   copy(1;2;3;4;5) -> 1;2;3;4;5     (keeps original as well)
  deepCopy(result, iter)


when isMainModule:
  var months = @["Jan", "Feb", "Mar", "Apr", "May", "June", "July", "Aug",
    "Sept", "Oct", "Nov", "Dec"].toIter()
  discard months()
  discard months()
  discard months()
  var copiedMonths = months.copy()
  assert months() == copiedMonths()


# []

proc `[]`*[T](iter: iterator(): T, n: int): T =
  ## .. code-block:: Nim
  ##   (1;2;3;4;5)[1] -> 2
  if n < 0:
    raise newException(IndexError, "Negative index")
  var copiedIter = iter.copy()
  var i = 0
  var r = copiedIter()
  while i < n:
    if finished(copiedIter):
      break
    i += 1
    r = copiedIter()
  if i == n and not finished(copiedIter):
    result = r
  else:
    raise newException(IndexError, "Out of index:" & $n &
        ", iterator has only " & $i & " elements")

when isMainModule:
  assert count(10)[0] == 10
  assert count(10)[5] == 15
  assert count(10)[10] == 20
  assert count(10,20)[9] == 19


# []=

proc `[]=`*[T](iter: var iterator(): T, n: int, value: T) =
  ## .. code-block:: Nim
  ##   (1;2;3;4;5)[1] = 100 ->    
  ##              (the original is modified to 1;100;3;4;5)
  if n < 0:
    raise newException(IndexError, "Negative index")
  var iterCopied = iter
  if not finished(iterCopied):
    iter = iterator():T =
      var i = 0
      var x = iterCopied()
      while not finished(iterCopied):
        if i == n:
          yield value
        else:
          yield x
        x = iterCopied()
        i += 1

proc `[]=`*[T](iter: var iterator(): T, selector: iterator(): bool, value: T) =
  ## .. code-block:: Nim
  ##   (1;2;3;4;5)[false;false;true;false;false] = 100 ->
  ##                       (the original is modified to 1;2;100;4;5)
  var iterCopied = iter
  var selectorCopied = selector.copy
  if not finished(iterCopied):
    var replacement = iterator():T =
      var i = 0
      var x = iterCopied()
      var s = selectorCopied()
      while not finished(iterCopied):
        if not finished(selectorCopied) and s:
          yield value
        else:
          yield x
        x = iterCopied()
        if not finished(selectorCopied):
          s = selectorCopied()
        i += 1
    iter = replacement

when isMainModule:
  var willBeModified = count(0)
  willBeModified[3] = 100
  assert willBeModified.toSeq(5) == @[0,1,2,100,4]
  # TODO: fix this
  willBeModified[willBeModified.mapIt(it < 10)] = 0

# copyWithCache

# Waiting for
#     https://github.com/Araq/Nim/issues/2766
# to be resolved.

#proc copyWithCache[T](iter: var iterator(): T)= (iterator(): T) =
#  let iterCopied = iter
#  var remember1 = initSinglyLinkedList[T]()
#  var remember2 = initSinglyLinkedList[T]()
#  iter = iterator(): T {.closure.} =
#    while true:
#      while remember1.head != nil:
#        yield remember1.head.value
#        remember1.head = remember1.head.next
#      let x = iterCopied()
#      if finished(iterCopied):
#        break
#      remember2.append(x)
#      yield x
#  iterator second(): T {.closure.} =
#    while true:
#      while remember2.head != nil:
#        yield remember2.head.value
#        remember2.head = remember2.head.next
#      let x = iterCopied()
#      if finished(iterCopied):
#        break
#      remember1.append(x)
#      yield x
#  result = second



# fold

proc fold*[T](iter: iterator(): T, f: proc(a, b: T): T): T =
  ## .. code-block:: Nim
  ##   fold(1;2;3, proc(a,b: int): int=a+b) -> 6
  result = iter()
  if finished(iter):
    raise newException(ValueError, "Can't call fold with zero length")
  var x = iter()
  while not finished(iter):
    result = f(result, x)
    x = iter()

proc fold*[T](iter: iterator(): T, f: proc(a, b: T): T, start: T): T =
  ## .. code-block:: Nim
  ##   fold(1;2;3, proc(a,b: int): int=a+b, 100) -> 106
  result = start
  var x = iter()
  while not finished(iter):
    result = f(result, x)
    x = iter()


template foldP*[T](iter: iterator(): T, params, f: expr): T =
  ## .. code-block:: Nim
  ##   foldP(1;2;3, (P,Q), P+Q) -> 6
  var index = 0
  type T = type((var copied = iter; copied()))
  fold(iter, proc(x, y: T): T =
    injectParam(params, (x,y)); var idx{.inject.}=index; index+=1; f)

template foldP*[T](iter: iterator(): T, params, f: expr, start: T): T =
  ## .. code-block:: Nim
  ##   foldP(1;2;3, (P,Q), P+Q, 100) -> 106
  var index = 0
  type T = type((var copied = iter; copied()))
  fold(iter, proc(x, y: T): T =
    injectParam(params, (x,y)); var idx{.inject.}=index; index+=1; f, start)

template foldAB*[T](iter: iterator(): T, f: expr): T =
  ## .. code-block:: Nim
  ##   foldAB(1;2;3, a+b) -> 6
  foldP(iter, (a,b), f)

template foldAB*[T](iter: iterator(): T, f: expr, start: T): T =
  ## .. code-block:: Nim
  ##   foldAB(1;2;3, a+b, 100) -> 106
  foldP(iter, (a,b), f, start)

when isMainModule:
  assert fold(count(1,6), proc(a, b: int): int = a+b) == 15
  assert fold(count(1,6), proc(a, b: int): int = a+b, 1000) == 1015

  assert foldAB(count(1,6), a+b) == 15
  assert foldAB(count(1,6), a+b) == 15
  assert foldAB(count(1,6), a+b, 1000) == 1015
  assert foldAB(count(1,6), a+b, 1000) == 1015


# foldList

proc foldList*[T](iter: iterator(): T, f: proc(a, b: T): T): iterator(): T =
  ## .. code-block:: Nim
  ##   foldList(1;2;3, proc(a,b: int): int=a+b) -> 1;3;6
  result = iterator(): T {.closure.} =
    var x = iter()
    if not finished(iter):
      yield x
    var y = iter()
    while not finished(iter):
      x = f(x, y)
      yield x
      y = iter()


template foldListP*[T](iter: iterator(): T, params, f: expr): iterator(): T =
  ## .. code-block:: Nim
  ##   foldListP(1;2;3, (P,Q), P+Q) -> 1;3;6
  var index = 0
  type T = type((var copied = iter; copied()))
  foldList(iter, proc(x, y: T): T =
    injectParam(params, (x,y)); var idx{.inject.}=index; index+=1; f)

template foldListAB*[T](iter: iterator(): T, f: expr): T =
  ## .. code-block:: Nim
  ##   foldListAB(1;2;3, a+b) -> 1;3;6
  foldListP(iter, (a,b), f)

when isMainModule:
  # maximums so far
  assert foldList(@[3,6,4,9,1,2,10].toIter(),
      proc(a, b: int): int =
        if b>a: b
        else: a).toSeq() == @[3, 6, 6, 9, 9, 9, 10]

  assert foldListAB(@[3,6,4,9,1,2,10].toIter(),
      (if b>a: b else: a)).toSeq() == @[3, 6, 6, 9, 9, 9, 10]


# partition

proc partitionSeq*[T](iter: iterator(): T, n: int): iterator(): seq[T] =
  ## .. code-block:: Nim
  ##   partitionSeq(1;2;3;4;5;6,7, 2) -> @[1,2];@[3,4];@[5,6]
  result = iterator(): seq[T] {.closure.} =
    var items = newSeq[T](n)
    var i = 0
    var x = iter()
    while not finished(iter):
      items[i] = x
      i += 1
      if i == n:
        yield items
        i = 0
      x = iter()


proc partitionSeq*[T](iter: iterator(): T, n, step: int): iterator(): seq[T] =
  ## .. code-block:: Nim
  ##   partitionSeq(1;2;3;4;5, 2,1) -> @[1,2];@[2,3];@[3,4];@[4,5]
  result = iterator(): seq[T] {.closure.} =
    var items = newSeq[T](n)
    var i = 0
    var x = iter()
    while not finished(iter):
      items[i] = x
      i += 1
      if i == n:
        yield items
        while i < step and not finished(iter):
          x = iter()
          i += 1
        var j = step
        while j < i:
          items[j-step] = items[j]
          j += 1
        i = i-step
      if not finished(iter):
        x = iter()

proc partitionSeq*[T](iter: iterator(): T, n, step: int, pad: T):
                                                    iterator(): seq[T] =
  ## .. code-block:: Nim
  ##   partitionSeq(1;2;3;4;5, 2,2,99) -> @[1,2];@[3,4];@[5,99]
  result = iterator(): seq[T] {.closure.} =
    var items = newSeq[T](n)
    var i = 0
    var x = iter()
    while not finished(iter):
      items[i] = x
      i += 1
      if i == n:
        yield items
        while i < step and not finished(iter):
          x = iter()
          i += 1
        var j = step
        while j < i:
          items[j-step] = items[j]
          j += 1
        i = i-step
      if not finished(iter):
        x = iter()
    if i > 0:
      for j in i..<n:
        items[j] = pad
      yield items


template partition*[T](iter: iterator(): T, n: int):
                        iterator(): expr =
  ## .. code-block:: Nim
  ##   partition(1;2;3;4;5;6,7, 2) -> (1,2);(3,4);(5,6)
  when n > 0:
    discard # TODO: find a good way to throw error when n is not known
  type T = type((var copied = iter; copied()))
  type S = type((
    block:
      var empty = newSeq[T](n)
      toTuple(Ts, empty, n)
      Ts))
  map(partitionSeq(iter, n), proc(x: seq[T]): S =
    toTuple(Ts, x, n); Ts)

template partition*[T](iter: iterator(): T, n, step: int):
                        iterator(): expr =
  ## .. code-block:: Nim
  ##   partition(1;2;3;4;5, 2,1) -> (1,2);(2,3);(3,4);(4,5)
  when n > 0:
    discard
  type T = type((var copied = iter; copied()))
  type S = type((
    block:
      var empty = newSeq[T](n)
      toTuple(Ts, empty, n)
      Ts))
  map(partitionSeq(iter, n, step), proc(x: seq[T]): S =
    toTuple(Ts, x, n); Ts)

template partition*[T](iter: iterator(): T, n, step: int, pad: T):
                        iterator(): expr =
  ## .. code-block:: Nim
  ##   partition(1;2;3;4;5, 2,2,99) -> (1,2);(3,4);(5,99)
  when n > 0:
    discard
  type T = type((var copied = iter; copied()))
  type S = type((
    block:
      var empty = newSeq[T](n)
      toTuple(Ts, empty, n)
      Ts))
  map(partitionSeq(iter, n, step, pad), proc(x: seq[T]): S =
    toTuple(Ts, x, n); Ts)

when isMainModule:
  var pairsOfNumbers = count(0).partitionSeq(2)
  assert pairsOfNumbers.first == @[0,1]
  assert pairsOfNumbers.first == @[2,3]
  assert pairsOfNumbers.first == @[4,5]
  var savedPair = pairsOfNumbers.first()
  assert pairsOfNumbers.first == @[8,9]
  assert savedPair == @[6,7]

  var triplets = count(0).partition(3)
  assert triplets.first == (0,1,2)
  assert triplets.first == (3,4,5)
  var savedTriplet = triplets.first()
  assert triplets.first == (9,10,11)
  assert savedTriplet == (6,7,8)

  assert count(0).partition(2,1).toSeq(5) == @[(0,1),(1,2),(2,3),(3,4),(4,5)]
  assert count(0, 8).partition(5,5,999).toSeq() ==
          @[(0,1,2,3,4),(5,6,7,999,999)]

# partitionBy

proc partitionBy*[T,S](iter: iterator(): T, f: proc(any: T): S):
                                              iterator(): (S,seq[T]) =
  ## .. code-block:: Nim
  ##   partitionBy(1;2;3;4;5, proc(x: int): bool = x mod 3==0) ->
  ##                            @[1,2];@[3];@[4,5]
  result = iterator(): (S,seq[T]) {.closure.} =
    var x = iter()
    var items = newSeq[S]()
    var lastValue = f(x)
    while not finished(iter):
      if lastValue != f(x):
        yield (lastValue, items)
        items = newSeq[S]()
        lastValue = f(x)
      items.add(x)
      x = iter()
    if items.len > 0:
      yield (lastValue, items)

template partitionByP*[T,S](iter: iterator(): T, params, f: expr):
                                              iterator(): (S,seq[T]) =
  ## .. code-block:: Nim
  ##   partitionByP(1;2;3;4;5, P, P mod 3==0) ->
  ##                            @[1,2];@[3];@[4,5]
  var index = 0
  type T = type((var copied = iter; copied()))
  type S = type((
    block:
      var empty: T
      injectParam(params, empty)
      var idx{.inject.} = 0;
      f))
  partitionBy(iter, proc(x: T): S =
    injectParam(params, x); var idx{.inject.}=index; index+=1; f)

template partitionByIt*[T,S](iter: iterator(): T, f: expr): iterator(): (S,seq[T]) =
  ## .. code-block:: Nim
  ##   partitionByIt(1;2;3;4;5, it mod 3==0) ->
  ##                            @[1,2];@[3];@[4,5]
  partitionByP(iter, it, f)

template partitionByKV*[T,S](iter: iterator(): T, f: expr): iterator(): (S,seq[T]) =
  ## .. code-block:: Nim
  ##   partitionByKV((1,a);(2,a);(3,b);(4,b);(5,c), v) ->
  ##                            @[(1,a),(2,a)];@[(3,b),(4,b)];@[(5,c)]
  partitionByP(iter, (k,v), f)

when isMainModule:
  assert count(0, 8).partitionByIt(it div 3).toSeq() == @[
      (0,@[0,1,2]),
      (1,@[3,4,5]),
      (2,@[6,7])]

# wrapIter

template wrapIter*[T](iter: expr): iterator(): T =
  ## .. code-block:: Nim
  ##   wrapIter(walkFiles("*")) -> "a.nim"; "b.nim"; ...
  type T = type(iter)
  iterator result(): T {.closure,gensym.} =
    for x in iter:
      yield x
  result

when isMainModule:
  iterator simpleIter(): int =
    yield 1
    yield 2
  var simpleIterInVariable = wrapIter(simpleIter())
  assert simpleIterInVariable.toSeq() == @[1,2]

# +,-,*,/,mod

template createIterFor2Params*(name: expr): stmt =
  ## Creates public functions from functions with 2 parameters. The resulting
  ## functions can take an interator in its first or second parameter, or both
  ##
  ## .. code-block:: Nim
  ##   createIterFor2Params `+`
  ##   (1;2;3;4) + (10;20;30) -> 11;22;33
  proc name*[T,S,U](iter: iterator(): T, iter2: iterator(): S): iterator(): U =
    result = iterator(): type((var a: T; var b: S; name(a,b))) {.closure.} =
      var x = iter()
      var y = iter2()
      while not finished(iter) and not finished(iter2):
        yield name(x,y)
        x = iter()
        y = iter2()
  proc name*[T,S,U](iter: iterator(): T, param2: S): iterator(): U =
    result = iterator(): type((var a: T; var b: S; name(a,b))) {.closure.} =
      var x = iter()
      while not finished(iter):
        yield name(x,param2)
        x = iter()
  proc name*[T,S,U](param1: T, iter: iterator(): S): iterator(): U =
    result = iterator(): type((var a: T; var b: S; name(a,b))) {.closure.} =
      var y = iter()
      while not finished(iter):
        yield name(param1,y)
        y = iter()

createIterFor2Params `+`
createIterFor2Params `-`
createIterFor2Params `*`
createIterFor2Params `/`
createIterFor2Params `div`
createIterFor2Params `mod`
createIterFor2Params `==`
createIterFor2Params `<`
createIterFor2Params `<=`
createIterFor2Params `<%`
createIterFor2Params `<=%`
createIterFor2Params min
createIterFor2Params max
createIterFor2Params `and`
createIterFor2Params `or`
createIterFor2Params `&`

template createIterFor1Param*(name: expr): stmt =
  ## Creates public functions from functions with 1 parameter. The resulting
  ## functions can take an interator in its first parameter.
  ##
  ## .. code-block:: Nim
  ##   createIterFor1Param `not`
  ##   not (false;false;true) -> true;true;false
  proc name*[T](iter: iterator(): T): iterator(): T =
    result = iterator(): T {.closure.} =
      var x = iter()
      while not finished(iter):
        yield name(x)
        x = iter()

createIterFor1Param `not`

when isMainModule:
  assert toSeq(count(0) + count(10), 5) == @[10,12,14,16,18]
  assert toSeq(count(0) + 100, 5) == @[100,101,102,103,104]
  assert toSeq(100 + count(0), 3) == @[100,101,102]
  assert toSeq(count(100) - count(10), 5) == @[90,90,90,90,90]
  assert toSeq(max(count(0), 2), 5) == @[2,2,2,3,4]
  assert toSeq(not (count(5,8) > 6)) == @[true, true, false]

  proc sqr(x: int): int = x*x
  createIterFor1Param sqr
  assert sqr(count(0)).toSeq(3) == @[0,1,4]

