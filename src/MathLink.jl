module MathLink

# TODO:
#   Read and store arrays
#   Conversions e.g. from `Times` to `*` and back.
#   Block expressions
#   MRefs (https://github.com/one-more-minute/clj-mma?source=c#mathematica-vars)
#   Better error recovery
#   Connect to running session

export @math, @mmimport, connect, meval

include("low_level.jl")

function connect(f)
  local link = ML.Open()
  try
    r = f(link)
    return r
  finally
    ML.Close(link)
  end
end

macro math(expr)
  :(meval($(esc(Expr(:quote, expr)))))
end

function proc_argtypes(types)
  args = map(x->gensym(), types)
  typed_args = map((a, t) -> :($a::$(esc(t))), args, types)
  args, typed_args
end

macro mmimport(expr)
  if typeof(expr) == Symbol
    f = esc(expr)
    :($f(xs...) = meval(Expr(:call, $(Expr(:quote, expr)), xs...)))

  elseif expr.head == :tuple
    Expr(:block, [:(@mmimport $(esc(x))) for x in expr.args]...)

  elseif expr.head == :(::)

    if typeof(expr.args[1]) == Symbol
      fsym = expr.args[1]
      f = esc(fsym)
      T = esc(expr.args[2])
      :($f(xs...) = meval(Expr(:call, $(Expr(:quote, fsym)), xs...), $T))

    elseif expr.args[1].head == :call
      fsym = expr.args[1].args[1]
      f = esc(fsym)
      args, typed_args = proc_argtypes(expr.args[1].args[2:])
      rettype = esc(expr.args[2])
      :($f($(typed_args...)) =
          meval(Expr(:call, $(Expr(:quote, fsym)), $(args...)), $rettype))
    end
  else
    error("Unsupported mmimport expression $expr")
  end
end

@windows_only const wintestpaths =
  ["C:\\Program Files\\Wolfram Research\\Mathematica\\9.0\\math.exe"
   "C:\\Program Files\\Wolfram Research\\Mathematica\\8.0\\math.exe"]

function math_path()
  @windows_only for path in wintestpaths
    isfile(path) && return path
  end
  "math"
end

const link = ML.Open(math_path())
meval(expr) = meval(expr, Any)
meval(expr, T::DataType) = meval(link, expr, T)

function meval(link::ML.Link, expr, T::DataType)
  put!(link, :(EvaluatePacket($expr)))
  handle_packets(link, T)
end

function handle_packets(link::ML.Link, T::DataType)
  packet = :start
  while packet != :ReturnPacket
    if packet == :start
    elseif packet == :TextPacket
      print(get!(link, String))
    elseif packet == :MessagePacket
      ML.NewPacket(link)
      (T == Any ? warn : error)(get!(link).args[2])
    else
      error("Unsupported packet type $packet")
    end
    packet, n = ML.GetFunction(link)
  end
  return get!(link, T)
end

# Reading

# Perhaps add a type check here.
for (T, f) in [(Int64,   :GetInteger64)
               (Int32,   :GetInteger32)
               (Float64, :GetReal64)
               (String,  :GetString)
               (Symbol,  :GetSymbol)]
  @eval get!(link::ML.Link, ::Type{$T}) = (ML.$f)(link)
end

get!(link::ML.Link, ::Type{BigInt}) = BigInt(get!(link, String))

get!(link::ML.Link, ::Type{Any}) = get!(link)

function get!(link::ML.Link)
  t = ML.GetType(link)

  if t == ML.TK.INT
    # TODO: Support abitrary precision
    ML.GetInteger64(link)

  elseif t == ML.TK.FUNC
    f, nargs = ML.GetFunction(link)
    args = cell(nargs)
    for i = 1:nargs
      args[i] = get!(link)
    end
    :($f($(args...)))

  elseif t == ML.TK.STR
    get!(link, String)
  elseif t == ML.TK.REAL
    get!(link, Float64)
  elseif t == ML.TK.SYM
    get!(link, Symbol)

  elseif t == ML.TK.ERROR
    error("Link has suffered error $(ML.Error(link)): $(ML.ErrorMessage(link))")

  else
    error("Unsupported data type $t ($(int(t)))")
  end
end

# Writing

put!(link::ML.Link, head::Symbol, nargs::Integer) = ML.PutFunction(link, string(head), nargs)

for (T, f) in [(Int64,   :PutInteger64)
               (Int32,   :PutInteger32)
               (Float64, :PutReal64)
               (String,  :PutString)
               (Symbol,  :PutSymbol)]
  @eval put!(link::ML.Link, x::$T) = (ML.$f)(link, x)
end

function put!(link::ML.Link, expr::Expr)
  if expr.head == :call
    f, xs = expr.args[1], expr.args[2:end]
    put!(link, f, length(xs))
    for x in xs
      put!(link, x)
    end
  else
    error("Unsupported $(expr.head) expression in put!()")
  end
end

end