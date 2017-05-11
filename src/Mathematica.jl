module Mathematica

using MathLink

const exprs = quote

  # Typed Mathematica functions to import, in alphabetical order.
  D::Expr
  Integrate::Expr
  Prime(Integer)::Int
  RandomReal(Number)::Float64
  RandomReal(Number, Integer)::Vector{Float64}
  ToString::UTF8String

end

const macros = quote

  # Macros to import, in alphabetical order.
  Integrate::Expr
  D::Expr

end

# -----------
# Import Code
# -----------

getsym(expr) = typeof(expr) == Symbol ? expr : getsym(expr.args[1])
macrosym(s) = Symbol(string("@", s))

# Functions

for expr in exprs.args
  if typeof(expr) == Symbol || (typeof(expr) == Expr && expr.head != :line)
    @eval @mmimport $(expr)
    eval(Expr(:export, getsym(expr)))
  end
end

for expr in macros.args
  if typeof(expr) == Symbol || (typeof(expr) == Expr && expr.head != :line)
    @eval @mmacro $(expr)
    eval(Expr(:export, macrosym(getsym(expr))))
  end
end

for name in @math Names("System`*")
  f = Symbol(name)
  mf = macrosym(name)

  if !isdefined(f)
    @eval @mmimport $f
    eval(Expr(:export, f))
  end

  if !isdefined(mf)
    @eval @mmacro $f
    eval(Expr(:export, mf))
  end
end

end
