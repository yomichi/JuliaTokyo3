type IntTag{N} end

# I'm not sure when `Base.@generated` was implemented :p
if VERSION >= v"0.4.0-dev+4464"

  @generated function gen_fn(x)
    println(x)
    :(x*x)
  end

  @generated function fib{N}(::IntTag{N})
    N < 3 && return 1
    ret = fib(N-1) + fib(N-2)
    @show N, ret
    :($ret)
  end
  fib(N::Integer) = fib(IntTag{N}())
end

