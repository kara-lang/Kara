# Kara

An experimental functional programming language with dependent types, inspired by [Swift](https://swift.org) and [Idris](https://www.idris-lang.org).

## Motivation

Development of Kara is motivated by:

1. **Strong type safety**. Kara relies on dependent types to eliminate bugs at compile time that can't be caught by mainstream languages.
2. **Familiar syntax**. Kara's syntax should be familiar to everyone experienced with C language family, including Rust, Swift, TypeScript etc.
3. **Portability**. Kara is developed with support for all major platforms in mind. We want Kara apps to be usable in the browser, as a system programming language, and potentially even in embedded settings, like Arduino, kernel extensions, audio DSP plugins etc.
4. **Performance**. Where it's possible to compile Kara to native binary code, we want it to be as performant as Swift, but ideally it should as fast as Rust, Zig, or C/C++.
5. **Language Minimalism**. Kara shouldn't ever become a huge language. Whatever can be implemented as a library should be implemented as a library instead of adding a new feature to the language, as long as it doesn't conflict with the rest of the goals.
6. **Distribution Minimalism and Economic Accessibility**. A barebone distribution of Kara ready for basic development shouldn't take more than a hundred megabytes when installed as a native binary. Our users shouldn't need a ton of available storage, expensive hardware, and gigabit fiber broadband to get started. Additionally, Kara's toolchain should be available directly in the browser on any hardware released in the latest decade, with required components downloaded on demand.

## What's a dependent type?

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

### Code of Conduct

This project adheres to the [Contributor Covenant Code of
Conduct](https://github.com/kara-lang/Kara/blob/main/CODE_OF_CONDUCT.md).
By participating, you are expected to uphold this code. Please report
unacceptable behavior to conduct@kara-lang.org.

## License

Kara is available under the Apache 2.0 license.
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the [LICENSE](https://github.com/kara-lang/Kara/blob/main/LICENSE) file for
more info.


