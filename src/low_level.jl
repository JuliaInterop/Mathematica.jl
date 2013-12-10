module ML
  
# -------
# C Utils
# -------

type CRef{T}
  ptr::Ptr{T}
end

function CRef(T::DataType)
  @assert isbits(T)
  ptr = convert(Ptr{T}, c_malloc(sizeof(T)))
  CRef(ptr)
end

set!{T}(r::CRef{T}, x) = (unsafe_store!(r.ptr, convert(T, x)); r)
fetch(r::CRef) = unsafe_load(r.ptr)
free(r::CRef) = c_free(r.ptr)
free(rs::CRef...) = for r in rs free(r) end

CRef(T, v) = set!(CRef(T), v)
CRef(v) = CRef(typeof(v), v)

Base.convert{T}(::Type{Ptr{T}}, r::CRef{T}) = r.ptr
Base.convert{T}(::Type{T}, r::CRef{T}) = fetch(r)

typealias Cstr Ptr{Cchar}

# -----
# Begin
# -----

include("consts.jl")

typealias Env Ptr{Void}
typealias Link Ptr{Void}

mlib = "ml64i3"
macro mlib(); mlib; end

function Open(path = "math")
  # MLInitialize
  mlenv = ccall((:MLInitialize, @mlib), Env, (Cstr,), 0)
  mlenv == C_NULL && error("Could not MLInitialize")

  # MLOpenString
  local link
  let err = CRef(Cint)
    args = "-linkname '\"$path\" -mathlink' -linkmode launch"
    link = ccall((:MLOpenString, @mlib), Link,
                  (Env, Cstr, Ptr{Cint}),
                  mlenv, args, err)
    fetch(err)==0 || mlerror(link, "MLOpenString")
    free(err)
  end

  # Ignore first input packet
  @assert NextPacket(link) == Pkt.INPUTNAME
  NewPacket(link)

  return link
end

Close(link::Link) = ccall((:MLClose, @mlib), Void, (Link,), link)

ErrorMessage(link::Link) =
  ccall((:MLErrorMessage, @mlib), Cstr, (Link,), link) |> bytestring

for f in [:Error :ClearError :EndPacket :NextPacket :NewPacket]
  fstr = string("ML", f)
  @eval $f(link::Link) = ccall(($fstr, @mlib), Cint, (Link,), link)
end

mlerror(link, name) = error("MathLink Error $(Error(link)) in $name: " * ErrorMessage(link))

# Put fns

PutFunction(link::Link, name::String, nargs::Int) =
  ccall((:MLPutFunction, @mlib), Cint, (Link, Cstr, Cint),
    link, name, nargs) != 0 || mlerror(link, "MLPutFunction")

for (f, Tj, Tc) in [(:PutInteger64, Int64, Int64)
                    (:PutInteger32, Int32, Int32)
                    (:PutString, String, Cstr)
                    (:PutSymbol, Symbol, Cstr)
                    (:PutReal32, Float32, Float32)
                    (:PutReal64, Float64, Float64)]
  fstr = string("ML", f)
  @eval $f(link::Link, x::$Tj) =
          ccall(($fstr, @mlib), Cint, (Link, $Tc), link, x) != 0 ||
            mlerror(link, $fstr)
end

# Get fns

GetType(link::Link) =
  ccall((:MLGetType, @mlib), Cint, (Link,), link) |> char

for (f, T) in [(:GetInteger64, Int64)
               (:GetInteger32, Int32)
               (:GetReal32, Float32)
               (:GetReal64, Float64)]
  fstr = string("ML", f)
  @eval function $f(link::Link)
    i = CRef($T)
    ccall(($fstr, @mlib), Cint, (Link, Ptr{$T}), link, i) != 0 ||
      mlerror(link, $fstr)
    r = fetch(i)
    free(i)
    return r
  end
end

function GetString(link::Link)
  s = CRef(Cstr)
  ccall((:MLGetString, @mlib), Cint, (Link, Ptr{Cstr}), link, s) != 0 ||
    mlerror(link, "GetString")
  r = s |> fetch |> bytestring |> unescape_string
  ReleaseString(link, s)
  free(s)
  return r
end

function GetSymbol(link::Link)
  s = CRef(Cstr)
  ccall((:MLGetSymbol, @mlib), Cint, (Link, Ptr{Cstr}), link, s) != 0 ||
    mlerror(link, "GetString")
  r = s |> fetch |> bytestring |> unescape_string |> symbol
  ReleaseSymbol(link, s)
  free(s)
  return r
end

function GetFunction(link::Link)
  name = CRef(Cstr)
  nargs = CRef(Cint)
  ccall((:MLGetFunction, @mlib), Cint, (Link, Ptr{Cstr}, Ptr{Cint}),
    link, name, nargs) != 0 || mlerror(link, "MLGetFunction")
  r = name |> fetch |> bytestring |> symbol, nargs |> fetch
  ReleaseString(link, name)
  free(name, nargs)
  return r
end

ReleaseString(link::Link, s::CRef) = ccall((:MLReleaseString, @mlib), Void, (Link, Cstr), link, s)
ReleaseSymbol(link::Link, s::CRef) = ccall((:MLReleaseSymbol, @mlib), Void, (Link, Cstr), link, s)

end
