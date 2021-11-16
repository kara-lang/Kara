# Kara

An experimental functional programming language with dependent types, inspired by [Swift](https://swift.org) and [Idris](https://www.idris-lang.org).

## Motivation

The goal of Kara is to make recent advances in type systems available with syntax inspired by Swift and similar languages.

With dependent types one could prevent out-of-bounds errors at compile time. For example, this code in Kara tries to access array elements
that don't exist, but it won't type check:

```swift
let a1 = [1,2,3]
a1[3] // type error, out of bounds
let a2 = [4,5,6]
(a1 ++ a2)[6] // type error, OOB
```

This is achieved by encoding length of a collection in its type. Here `[1, 2, 3]` has type `Vector<Int, 3>`, which requires 
its subscript arguments to be less than vector's length. These constraints are checked at compile time, but work even for 
vector length computed at run time. Vector length is propagated to new vectors created at run time thanks to the generic vector
concatenation operator `++`. Its type signature looks like this:

```swift
(++): <Element, Length1, Length2>(
  Vector<Element, Length1>, 
  Vector<Element, Length2>
) -> Vector<Element, Length1 + Length2>
```

Here `Element`, `Length1`, and `Length2` are implicit generic arguments that refer to vector's element type and lengths of vectors.

The concept of dependent types allows us to use expressions in generic arguments of other types, like in `Vector<Element, Length1 + Length2>`
above. Here type of a vector depends on a value of its length. This allows us to check not only OOB for simple one-dimensional collections,
but also matrix/tensor operations, pointers etc.

One other interesting application of dependent types are implementations of state machines where [illegal state transitions don't type
check](https://stackoverflow.com/questions/33851598/using-idris-to-model-state-machine-of-open-close-door). 
While this is something that's possible in Swift with phantom types, we want it to feel much more natural in Kara with its type system.

## Current status

Example code from the previous section will not currently compile, or even type-check, although fixing this is the primary goal right now. 
Kara is at a very early stage and is not available for general or limited use at this moment. The project currently contains only a
basic parser, type checker, interpreter, and JavaScript codegen. Documentation is sparse and most of the features are still in flux. Pre-release
versions are currently only tagged for a purpose of some future retrospective.

Star and watch the repository if you're interested in imminent updates.

## Contributing

If you'd like to contribute, please make sure you have a general understanding of Idris and ideally have read at least foundational parts
of [Type-Driven Development with Idris](https://www.manning.com/books/type-driven-development-with-idris) book, which inspire
development of Kara. This is not a hard requirement for working on the Kara compiler, but it would be very helpful for all contributors to
be on the same page with the general approach to designing the language.
