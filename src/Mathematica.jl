include("MathLink.jl")

module Mathematica

using MathLink

const exprs = quote

  # Mathematica functions to import, in alphabetical order.

  BinomialDistribution
  Factorial(Integer)::BigInt
  Fibonacci(Integer)::BigInt
  PDF
  Prime(Integer)::Int
  RandomChoice
  RandomReal(Number)::Float64
  RandomReal
  ToString::String

end

getsym(expr) = typeof(expr) == Symbol ? expr : getsym(expr.args[1])

for expr in exprs.args
  if typeof(expr) == Symbol || (typeof(expr) == Expr && expr.head != :line)
    @eval @mmimport $(expr)
    eval(Expr(:export, getsym(expr)))
  end
end

end
