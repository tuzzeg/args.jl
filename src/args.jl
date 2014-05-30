module args

immutable Arg
  short::String
  long::String
end

macro arg1(func::Expr, short::String, long::String, T)
  println("arg, short=$short long=$long T=$T")
  # dump(:($f), 10)
  @eval begin
    pusharg!(Arg($short, $long))
  end
end

macro arg(short::String, long::String, T)
  println("arg, short=$short long=$long T=$T")
  # dump(:($f), 10)
  @eval begin
    pusharg!(Arg($short, $long))
  end
end

macro main(functions...)
  println("main, functions=$functions")
  @eval begin
    _args = Arg[]
    function pusharg!(a::Arg)
      Base.push!(_args, a)
    end
  end
end

end # module
