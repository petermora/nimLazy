# nimLazy
Iterator library for Nim.

# Tutorial
Ok, Bud. We're gonna take this nice and slow.
```nim
import lazy
echo count(5,10)
#@[5, 6, 7, 8, 9].toIter()
```

The function count() returns an iterator:
```nim
for x in count(5,10):
  echo x
#5
#6
#7
#8
#9
```

We can take the iterator's first 3 elements, length, reverse, last item 
and convert it to seq. We can also drop the last element:
```nim
echo count(5,10).take(3)
#@[5, 6, 7].toIter()
echo count(5,10).len
#5
echo count(5,10).reverse
#@[9, 8, 7, 6, 5].toIter()
echo count(5,10).last
#9
echo count(5,10).toSeq
#@[5, 6, 7, 8, 9]
echo count(5,10).drop(1)
#@[6, 7, 8, 9].toIter()
```

We can start counting from 5 without stopping. Don't call len, reverse or last 
on this, they will run forever (but dropping the first or the last element works fine).
The echo is limited to 10 values.
```nim
echo count(5)
#@[5, 6, 7, 8, 9, 10, 11, 12, 13, 14, ...].toIter()
```

+1 function is boring, let's do *2. Iterate gives us x; f(x); f(f(x)); ...
```nim
echo iterate(proc(x: int): int = 2*x, 1)
#@[1, 2, 4, 8, 16, 32, 64, 128, 256, 512, ...].toIter()
```

It takes so much time to write types, so I'll ignore them if it's possible. 
In functions like iterateIt, mapIt, filterIt, ... the variable is always **it**:
Types are checked at compile-time.
```nim
echo iterateIt(10*it, 1)
#@[1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000, ...].toIter()
echo iterateIt("a" & it, "")
#@[, a, aa, aaa, aaaa, aaaaa, aaaaaa, aaaaaaa, aaaaaaaa, aaaaaaaaa, ...].toIter()
```

The Collatz conjecture states that if we take a positive integer (like 10
in the example below) 
as a starting point, then the following series (half when even, 3*n+1 when odd) always reaches 1.
```nim
echo iterateIt(if it mod 2 == 1: 3*it+1 else: it div 2, 10)
#@[10, 5, 16, 8, 4, 2, 1, 4, 2, 1, ...].toIter()
```

In addition to **it**, we can use **idx** as well, it contains the index. Since 
x^2 = (x-1)^2 + 2*x - 1, the square numbers are:
```nim
echo iterateIt(it + 2*idx - 1, 0)
#@[0, 1, 4, 9, 16, 25, 36, 49, 64, 81, ...].toIter()
```

There is an iterator version for +,-,*,/,div,mod,==,<,<=,<%,<=%,min,max, so
the square numbers are really just:
```nim
echo count(0) * count(0)
#@[0, 1, 4, 9, 16, 25, 36, 49, 64, 81, ...].toIter()
```

For these operators the first or the second parameter can be an interator,
or both. You can use the library's template to prepare your functions for
iterators. There are several ways to start counting from 5:
```nim
echo count(5)
#@[5, 6, 7, 8, 9, 10, 11, 12, 13, 14, ...].toIter()
echo count(0) + 5
#@[5, 6, 7, 8, 9, 10, 11, 12, 13, 14, ...].toIter()
echo count(0) + repeat(5)
#@[5, 6, 7, 8, 9, 10, 11, 12, 13, 14, ...].toIter()
```

The & symbol is used for concatenation of strings, and not the iterators
themselves. If one of the iterators has fewer values, then the output
truncated:
```nim
echo toIter(@["a", "b", "c"]) & count(1).mapIt($it)
#@[a1, b2, c3].toIter()
```

We can cycle the shorter to have an infinite list:
```nim
echo toIter(@["a", "b", "c"]).cycle() & count(1).mapIt($it)
#@[a1, b2, c3, a4, b5, c6, a7, b8, c9, a10, ...].toIter()
```

We have iterateKV, mapKV, filterKV, ... functions which takes iterators of 
key-value (k,v) pairs. Let's swap keys and values in my ranking of foods:
```nim
import tables
var fruitsOrder = initTable[string, int]()
fruitsOrder["banana"] = 2
fruitsOrder["apple"] = 3
fruitsOrder["kiwi"] = 1
fruitsOrder["mango"] = 1
echo fruitsOrder.toIter.mapKV((v,k)).toTable()
#{1: mango, 2: banana, 3: apple}
```

It is my mistake that kiwi and mango got the same ranking and "mango" overrides
"kiwi". Let's fix this. The toTableAB calls the given function where
**a** is the accumulation variable and **b** is the new item:
```nim
echo fruitsOrder.toIter.mapKV((v,k)).toTableAB(a & ", " & b)
#{1: kiwi, mango, 2: banana, 3: apple}
```

There are two other functions with this AB syntax: foldAB, foldListAB. The
usual example for foldAB is the sum:
```nim
echo count(1,10, includeLast=true).foldAB(a+b)
#55
```

The maximum values in a sequence we have seen so far:
```nim
echo toIter(@[4,7,6,5,9,2]).foldListAB(if a>b: a else: b)
#@[4, 7, 7, 7, 9, 9].toIter()
```

IterateKV supposed to create key-value pairs, but it will just do fine for 
generating the Fibonacci sequence:
```nim
echo iterateKV((v, k+v), (1,1)).mapKV(k)
#@[1, 1, 2, 3, 5, 8, 13, 21, 34, 55, ...].toIter()
```

This might be a little tricky inside, so let me print the inner values:
```nim
echo iterateKV((v, k+v), (1,1)).print("just after iterateKV").mapKV(k)
#DEBUG: "just after iterateKV" @github.nim(88): (Field0: 1, Field1: 1)
#DEBUG: "just after iterateKV" @github.nim(88): (Field0: 1, Field1: 2)
#DEBUG: "just after iterateKV" @github.nim(88): (Field0: 2, Field1: 3)
#DEBUG: "just after iterateKV" @github.nim(88): (Field0: 3, Field1: 5)
#DEBUG: "just after iterateKV" @github.nim(88): (Field0: 5, Field1: 8)
#DEBUG: "just after iterateKV" @github.nim(88): (Field0: 8, Field1: 13)
#DEBUG: "just after iterateKV" @github.nim(88): (Field0: 13, Field1: 21)
#DEBUG: "just after iterateKV" @github.nim(88): (Field0: 21, Field1: 34)
#DEBUG: "just after iterateKV" @github.nim(88): (Field0: 34, Field1: 55)
#DEBUG: "just after iterateKV" @github.nim(88): (Field0: 55, Field1: 89)
#DEBUG: "just after iterateKV" @github.nim(88): (Field0: 89, Field1: 144)
#@[1, 1, 2, 3, 5, 8, 13, 21, 34, 55, ...].toIter()
```

The list of primes can be given by filtering out all the multiples of the primes from count(2)
which we have already found:
```nim
proc sieve(iter: iterator(): int): iterator(): int=
  result = iterator(): int {.closure.}=
    var first = iter()
    yield first
    sieve(iter.filterIt(it mod first != 0)).yieldAll
echo sieve(count(2))
#@[2, 3, 5, 7, 11, 13, 17, 19, 23, 29, ...].toIter()
```

Partition(2) creates pairs (its cheating, it uses a macro, this parameter 
2 has to be known
at compile time). It will skip the last item if the list is finite 
and has odd number of elements.
With step=1 we can force to step only one instead of two:
```nim
echo toIter(@["A","B","C","D","E"]).partition(2)
#@[(Field0: A, Field1: B), (Field0: C, Field1: D)].toIter()
echo toIter(@["A","B","C","D","E"]).partition(2,step=1)
#@[(Field0: A, Field1: B), (Field0: B, Field1: C), (Field0: C, Field1: D), (Field0: D, Field1: E)].toIter()
```

We have all the bricks to print the first 10 twin primes:
```nim
echo sieve(count(2)).partition(2,1).filterKV(k+2==v).take(10).
  mapKV("twin primes #" & $(idx+1) & ": " & $k & ", " & $v).foldAB(a&"\n"&b)
#twin primes #1: 3, 5
#twin primes #2: 5, 7
#twin primes #3: 11, 13
#twin primes #4: 17, 19
#twin primes #5: 29, 31
#twin primes #6: 41, 43
#twin primes #7: 59, 61
#twin primes #8: 71, 73
#twin primes #9: 101, 103
#twin primes #10: 107, 109
```

We can define partitions using a function. Each time the function returns
a new value, a new partition starts. Let's count how many numbers exitst with
1, 2 and 3 digits:
```nim
echo count(0).partitionByIt(($it).len).
  mapKV("there are "& $v.len & " numbers with " & $k & " digit(s)").take(3).
  foldAB(a&"\n"&b)
#there are 10 numbers with 1 digit(s)
#there are 90 numbers with 2 digit(s)
#there are 900 numbers with 3 digit(s)
```

Let's do some more advanced stuff. And iterator can be saved to a variable.
Once we call it, the first value is gone forever. 
```nim
var fromZero = count(0)
var onlyLargerThan10 = fromZero.filterIt(it>10)
echo onlyLargerThan10()
#11
```

At this point fromZero() will return 12:
```nim
echo fromZero()
#12
```

And onlyLargerThan10() will return 13:
```nim
echo onlyLargerThan10()
#13
```

We could have made them independent by calling *copy()*:
```nim
var indFromZero = count(0)
var indOnlyLargerThan10 = indFromZero.copy.filterIt(it>10)
echo indOnlyLargerThan10()
#11
echo indFromZero()
#0
```

The copy() function uses deepCopy().
Printing an iterator with echo calls
$, which creates a deepCopy of the object without modifying it.
 We have peek(), peekList(), $, [] and
hasNext() functions, which doesn't modify their iterator parameter, but copies instead.
We can use [] get values:
```nim
var countFromZero = count(0)
echo countFromZero[100]
#100
echo countFromZero[200]
#200
```

And []= to override them:
```nim
countFromZero[3] = 99
echo countFromZero
@[0, 1, 2, 99, 4, 5, 6, 7, 8, 9, ...].toIter()
```

The []= syntax also accepts iterator of bool. The selector iterator is copied
with deepCopy in order to have independence:
```nim
countFromZero[countFromZero < 5] = -5
echo countFromZero
#@[-5, -5, -5, 99, -5, 5, 6, 7, 8, 9, ...].toIter()
```

The os module has an iterator for listing files called walkFiles(). We can't
copy the iterator itself to a value, so let's wrap it, then filter for only ".nim" files:
```nim
import os, strutils
var ourWalkFiles = wrapIter(walkFiles("*"))
echo ourWalkFiles.filterIt(".nim" in it)
#@[github.nim, lazy.nimble, misc.nim].toIter()
```

# Documentation
[https://rawgit.com/petermora/nimLazy/master/doc/lazy.html](Generated document)

