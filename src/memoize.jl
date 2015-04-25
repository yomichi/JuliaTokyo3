import Base.Meta.isexpr

# see base/docs.jl
function unblock(ex)
  isexpr(ex, :block) || return ex
  exs = filter(x->!isexpr(x, :line), ex.args)
  length(exs) == 1 || return ex
  return exs[1]
end
fexpr(ex) = isexpr(ex, :function) || (isexpr(ex, :(=)) && isexpr(ex.args[1], :call))
fname(ex) = unblock(ex).args[1].args[1]
fargs(ex) = unblock(ex).args[1].args[2:end]
fbody(ex) = unblock(ex).args[2]

function aname(arg)
  isexpr(arg, :(::)) && return aname(arg.args[1])
  isexpr(arg, :kw) && return aname(arg.args[1])
  return arg
end
function atype(arg)
  isexpr(arg, :(::)) && return eval(arg.args[2])
  isexpr(arg, :kw) && return atype(arg.args[1])
  return Any
end

for op in (:name, :type)
  typ = op==:name ? Symbol : DataType
  fn = symbol("farg", op, "s")
  arg_fn = symbol("a", op)
  param_fn = symbol("p", op)
  @eval function $param_fn(arg)
    isexpr(arg, :parameters) && return $typ[$arg_fn(a) for a in arg.args]
    return $typ[]
  end
  @eval function $fn(def)
    args = fargs(def)
    normals = $typ[]
    params = $typ[]
    for arg in args
      if isexpr(arg, :parameters)
        params = $param_fn(arg)
      else
        push!(normals, $arg_fn(arg))
      end
    end
    return tuple(normals...), tuple(params...)
  end
end

macro memoize(ex)
  def = unblock(ex)
  fexpr(def) || error("@memoize can be applied only to function definition")
  fn = fname(def)
  fn_impl = symbol(fn, "_impl")
  def.args[1].args[1] = fn_impl
  @eval $def
  def.args[1].args[1] = fn

  names = fargnames(def)
  types = fargtypes(def)
  dict = gensym(fn)
  if length(names[2]) > 0
    JT3.@eval $dict = Dict{Tuple{Tuple{$types[1]...}, Tuple{$types[2]...}}, Any}()
    body = quote
      dict = (JT3.$dict)
      key = (($(names[1]...),), ($(names[2]...),))
      if haskey(dict, key)
        return dict[key]
      else
        d = (Symbol=>Any)[t[1]=>t[2] for t in zip( $(names[2]), ($(names[2]...),) ) ]
        val = (JT3.$fn_impl)(($(names[1]...)); d...)
        dict[key] = val
        return val
      end
    end
  else
    JT3.@eval global $dict = Dict{Tuple{$types[1]...}, Any}()
    body = quote
      dict = (JT3.$dict)
      key = ($(names[1]...),)
      if haskey(dict, key)
        return dict[key]
      else
        val = dict(key...)
        dict[key] = val
        return val
      end
    end
  end
  def.args[2] = body
  return esc(def)
end

