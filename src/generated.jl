type IntTag{N} end

# I'm not sure when `Base.@generated` was implemented :p
if VERSION >= v"0.4.0-dev+4464"

  @generated function gen_fn(x)
    println(x)
    :(x*x)
  end

  # recursive version for calculating Fibonacci number
  #
  # It's a just demonstration of @generated, NEVER use!
  function fib_impl(N::Integer)
    N < 2 && return 1
    return fib_impl(N-1) + fib_impl(N-2)
  end
  @generated function fib{N}(::IntTag{N})
    ret = fib_impl(N)
    :($ret)
  end
  fib(N::Integer) = fib(IntTag{N}())
end

