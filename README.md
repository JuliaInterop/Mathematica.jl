# Mathematica.jl

[![Gitter chat](https://badges.gitter.im/one-more-minute/Mathematica.jl.png)](https://gitter.im/one-more-minute/Mathematica.jl)

The `Mathematica.jl` package provides an interface for using [Wolfram Mathematica™](http://www.wolfram.com/mathematica/) from the [Julia language](http://julialang.org). You cannot use `Mathematica.jl` without having purchased and installed a copy of Mathematica™ from [Wolfram Research](http://www.wolfram.com/). This package is available free of charge and in no way replaces or alters any functionality of Wolfram's Mathematica product.

The package provides is a no-hassle Julia interface to Mathematica. It aims to follow Julia's philosophy of combining high-level expressiveness without sacrificing low-level optimisation.

```julia
Pkg.add("Mathematica")
````
Provided Mathematica is installed, its usage is as simple as:

```julia
using Mathematica
Fibonacci(1000)
#=> 43466557686937456435688527675040625802564660517371780402481729089536555417949051890403879840079255169295922593080322634775209689623239873322471161642996440906533187938298969649928516003704476137795166849228875
```
All of Mathematica's functions are available as both functions and macros, and splicing (`$`) works as you would expect:
```julia
Integrate(:(x^2), :x) # or
@Integrate(x^2, x)
#=> :(*(1//3,^(x,3)))

@Integrate(log(x), {x,0,2})
#=> :(+(-2,log(4)))

eval(ans) # or
@N($ans) # or
N(ans) # or
@N(Integrate(log(x), {x,0,2}))
#=> -0.6137056388801094
```
Including those that return Mathematica data:
```julia
@Plot(x^2, {x,0,2})
#=> Graphics[{{{},{},{Hue[0.67, 0.6, 0.6],Line[{{4.081632653061224e-8,1.6659725114535607e-15},...}]}}}, {:AspectRatio->Power[:GoldenRatio, -1],:Axes->true, ...}]
```
Mathematical data can participate in Julia functions directly, with no wrapping required. For example -
```julia
using MathLink
d = BinomialDistribution(10,0.2) #=> BinomialDistribution[10, 0.2]
probability(b::MExpr{:BinomialDistribution}) = b.args[2]
probability(d) #=> 0.2
```

Julia compatible data (e.g. lists, complex numbers etc.) will all be converted automatically, and you can extend the conversion to other types.

Note that Mathematica expressions are *not* converted to Julia expressions by default. Functions/macros with the `::Expr` hint (see below) will convert their result, but for others you must use `convert` or `MathLink.to_expr`.

```julia
Log(-1) #=> Times[0 + 1im, :Pi]
convert(Expr, ans) #=> :(*(0 + 1im,Pi))
N(Log(-1)) #=> 0.0 + 3.141592653589793im
```
Printing and warnings are also supported:
```julia
Print("hi")
#=> hi
@Print(x^2/3)
#=>  2
#   x
#   --
#   3
Binomial(10)
#=> WARNING: Binomial::argr: Binomial called with 1 argument; 2 arguments are expected.
#=> Binomial[10]
```
Finally, of course:
```julia
WolframAlpha("hi") #=>
2-element Array{Any,1}:
 {{"Input",1},"Plaintext"}->"Hello."
 {{"Result",1},"Plaintext"}->"Hello, human."
```

## Advanced Use
### Typing
In the file `Mathematica.jl`, you'll see a listing of function and macro specifications, each in one of these formats:
```julia
Function::ReturnType # or
Function(Arg1Type, Arg2Type, ...)::ReturnType # (functions only)
```
For example:
```julia
Integrate::Expr
RandomReal(Number)::Float64
RandomReal(Number, Integer)::Vector{Float64}
```
The return type hint here is an optimisation; it allows `MathLink.jl` to grab the value from Mathematica without first doing a type check, and makes the function type stable - for example, `RandomReal(10, 5)` would return an `Any` array if not for this definition. The argument types allow type checking and multiple definitions.

Not many functions have type signatures yet, so providing them for the functions you want to use is an easy way to contribute.

### Extending to custom datatypes

The Mathematica data expression `Head[x,y,z,...]` is represented in Julia as `MExpr{:Head}(args = {x,y,z,...})`. We can extend `Mathematica.jl` to support custom types by overloading `MathLink.to_mma` and `MathLink.from_mma`.

For example, we can pass a Julia Dict straight through Mathematica with just two lines of definitions:
```julia
using MathLink; import MathLink: to_mma, from_mma
d = [:a => 1, :b => 2]

to_mma(d::Dict) = MExpr{:Dict}(map(x->MExpr(:Rule, x[1], x[2]),d))
Identity(d) #=> Dict[:b->2, :a->1]
from_mma(d::MExpr{:Dict}) = Dict(map(x->x.args[1], d.args), map(x->x.args[2], d.args))
Identity(d) #=> {:b=>2,:a=>1}
```

## Usage Issues

```julia
using Mathematica
```
This should work so long as either `math` is on the path (normally true on linux). `Mathematica.jl` will also look for `math.exe` on Windows, which should work for Mathematica versions 8 or 9 installed in default locations. If it doesn't work for you, open an issue (in particular I don't know how this will behave on Macs).

## Current Limitations / Planned Features
* Error handling: Error checking is currently reasonable, but the only way to reset the current link once an error is encountered is to restart Julia.
* Passing native arrays and matrices is not currently supported.
* MRefs: see the MVars section of [clj-mma](https://github.com/one-more-minute/clj-mma?source=c#mathematica-vars)
* Connect to a running session and injecting callbacks to Julia functions would be really cool, but would probably require a C extension for Mathematica.
