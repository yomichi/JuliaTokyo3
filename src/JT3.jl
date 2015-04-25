module JT3

function setx(val)
  :( x = $val)
end

macro setx_A()
   :( x = sin(1.0) )
end

macro setx_B()
  esc( :( x = sin(1.0)) )
end

macro setx_C()
  :( $(esc(:x)) = sin(1.0) )
end

macro setx_D()
  :( $:x = sin(1.0) )
end

macro setf_A(ex, val)
  :( $ex = $val )
end

macro setf_B(ex, val)
  esc( :($ex = $val) )
end

macro setf_C(ex, val)
  esc_ex = esc(ex)
  esc_val = esc(val)
  :( $esc_ex = $esc_val)
end

macro setzero(x)
  :( $(esc(x)) = isdefined($((x,))[1]) ? zero($(esc(x))) : 0)
end

macro time(ex)
  quote
    t0 = time_ns()
    val = $(esc(ex))
    t1 = time_ns()
    println(1.e-9(t1-t0), " sec")
    val
  end
end

function isnotcomment(line::AbstractString)
  !ismatch(r"^\s*(#|$)", line)
end
function isnotcomment_nomacro(line::AbstractString)
  !ismatch(Regex("^\\s*(#|\$)"), line)
end
function filter_comment(lines::Vector)
  filter(isnotcomment, lines)
end

type MyFloat
  val :: Float64
end
for fn in (:sin, :cos, :tan)
  eval(Expr(:import, :Base, fn))
  @eval ($fn)(mf::MyFloat) = ($fn)(mf.val)
end

include("generated.jl")
include("memoize.jl")

end
