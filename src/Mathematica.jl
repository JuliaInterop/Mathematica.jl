include("MathLink.jl")

module Mathematica

using MathLink

const exprs = quote

  # Typed Mathematica functions to import, in alphabetical order.
  Prime(Integer)::Int
  RandomReal(Number)::Float64
  RandomReal(Number, Integer)::Vector{Float64}
  ToString::String

end

const macros = quote

  # Macros to import, in alphabetical order.
  Integrate::Expr
  Plot

end

# -----------
# Import Code
# -----------

getsym(expr) = typeof(expr) == Symbol ? expr : getsym(expr.args[1])

# Functions

for expr in exprs.args
  if typeof(expr) == Symbol || (typeof(expr) == Expr && expr.head != :line)
    @eval @mmimport $(expr)
    eval(Expr(:export, getsym(expr)))
  end
end

for name in @math Names("System`*")
  f = symbol(name)
  if !isdefined(f)
    @eval @mmimport $f
    eval(Expr(:export, f))
  end
end

# Macros

for expr in macros.args
  if typeof(expr) == Symbol || (typeof(expr) == Expr && expr.head != :line)
    @eval @mmacro $(expr)
    eval(Expr(:export, symbol(string("@", getsym(expr)))))
  end
end

# Need to be able to test if a macro is defined.

end
