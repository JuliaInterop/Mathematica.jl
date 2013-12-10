# Mathematica

lets you call Mathematica functions from Julia.

```julia
Pkg.clone("Mathematica")
````

Provided Mathematica is installed, its usage is as simple as:

```julia
using Mathematica
Fibonacci(1000)
#=> 4346655768693745643568852767...
```
This should work so long as either `math` is on the path (normally true on linux). `Mathematica.jl` will also look for `math.exe` on Windows, which should work for Mathematica versions 8 or 9 installed in default locations. If it doesn't work for you, open an issue.

As well the Julia wrappers defined in the `Mathematica` module, you can use the `@math` macro:

```julia
using MathLink
n = 2
@math NIntegrate(Power(x,2), List(x, 0, $n))
#=> 2.6666666666666705
```
This is useful when you want to optimise by avoiding the movement of values in and out of Mathematica's memory.

You can also define your own wrappers easily enough, via one of the following:


```julia
@mmimport Function
@mmimport Function::ReturnType
@mmimport Function(Arg1Type, Arg2Type, ...)::ReturnType
```
For example, `Prime` and `Fibonacci` are defined by

```julia
@mmimport Prime(Integer)::Int, Fibonacci(Integer)::BigInt
```
Annotating the return type is potentially a good optimisation since it prevents type checking, but beware that it can cause errors if, for example, the function can return unevaluated. Annotating argument types allows you to give multiple definitions.

At the moment, very few functions are wrapped by default; if you're using this library and want to contribute, an easy way to do so is to add the signatures of functions you want to use to `Mathematica.jl`.

Please also open issues for any improvements you want to see.

## Current Limitations / Planned Features
* Error handling: Error checking is currently reasonable, but the only way to reset the current link once an error is encountered is to restart Julia.
* Function aliasing: Expressions should be translated e.g. `*(x,y) => Times(x,y)` and back.
* Similarly, custom data types can be supported by extending `put!()` but not from MMA -> Julia.
* Passing arrays directly is not yet supported; `[1,2,3]` must be passed and returned as `:(List(1,2,3))`
* MRefs: see the MVars section of [clj-mma](https://github.com/one-more-minute/clj-mma?source=c#mathematica-vars)
* Connect to a running session and injecting callbacks to Julia functions would be really cool, but isn't something I've looked into.
