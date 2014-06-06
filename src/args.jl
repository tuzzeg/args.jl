module args

export
  @args, @main, Arg,
  CommandArgs, StructUpdater,
  update!, parser, call, main

immutable Arg{T}
  sym::Symbol
  short::String
  long::String
  default::Union(T, Nothing)
  function Arg(sym::Symbol, long; short::String="", default::Union(T, Nothing)=nothing)
    new(sym, short, long, default)
  end
end

argtype{T}(::Arg{T}) = T

macro args(func::Symbol, arg_exprs...)
  local args_t = symbol("_$(func)_args")
  local args = [eval(expr) for expr in arg_exprs]

  local t_members = {:($(a.sym)::$(argtype(a))) for a in args}
  local t_defaults = {a.default for a in args}
  local f_args = {:(o.$(a.sym)) for a in args}
  local p_ifs = gen_switch(
    [(match_expr(a), :(StructUpdater{$(argtype(a))}($(Expr(:quote, a.sym))))) for a in args],
    quote nothing end)

  gen = quote
    type $args_t
      $(t_members...)
      $args_t() = new($(t_defaults...))
    end

    $func(o::$args_t) = $func($(f_args...))

    function parser(p::$args_t, arg::String)
      $p_ifs
    end
  end
  esc(gen)
end

macro main(functions::Symbol...)
  function _check(func)
    f_name = string(func)
    :(cmd == $(f_name))
  end
  function _case(func)
    f_typ = symbol("_$(string(func))_args")
    quote
      o.action = $func
      o.args = $f_typ()
      args.update!(o.args, _args)
    end
  end
  local switch_cases = (Expr, Expr)[(_check(func), _case(func)) for func in functions]
  local switch_default = quote
    throw(ParseError("Unexpected command []"))
  end
  local switch = gen_switch(switch_cases, switch_default)

  gen = quote
    function args.update!(o::CommandArgs, _args::Array{String,1})
      if length(_args) < 1
        throw(ParseException("Expected command, args=$(_args)"))
      end
      cmd, _args = _args[1], _args[2:end]
      $switch
    end
  end
  esc(gen)
end

function match_expr(a::Arg)
  if isempty(a.short)
    :(arg == $(a.long))
  else
    :(arg == $(a.long) || arg == $(a.short))
  end
end

function gen_switch(cases::Array{(Expr,Expr),1}, default::Expr)
  head = quote nothing end
  last = head
  for (cond, res) in cases
    last = push_last!(last, :($cond ? $res : nothing))
  end
  # TODO push default to last statement
  head
end

# update else clause in if expression with 'expr'
# return reference to updated if
function push_last!(if_expr, expr)
  last = if_expr
  while isa(last, Expr)
    last, if_expr = if_expr.args[end], last
  end
  if_expr.args[end] = expr
  if_expr
end

#
# Runtime
#

type CommandArgs
  action::Function
  args
  CommandArgs() = new()
end

abstract Updater{T}

immutable StructUpdater{T} <: Updater{T}
  sym::Symbol
end

parser(o, ::String) = throw(ParseError("Not supported type [$(typeof(o))]"))

function update!{R}(o::R, _args::Array{String,1})
  unparsed = Array{String,1}
  i_arg = 1
  consumed = 0
  while i_arg <= length(_args)
    arg = _args[i_arg]
    if beginswith(arg, "-")
      args_split = split(arg, "=", 2)
      if length(args_split) == 1
        p_arg = parser(o, arg)
        if !isa(p_arg, Nothing)
          v = valency(p_arg)
          consumed = 1+v
          update_args = _args[i_arg:i_arg+v]
        end
      else
        p_arg = parser(o, args_split[1])
        if !isa(p_arg, Nothing)
          v = valency(p_arg)
          if v != 1
            throw(ParseError("--option=value should be used only with valency=1, p=[$p_arg]"))
          end
          consumed = 1
          update_args = args_split
        end
      end
      args.update!(o, p_arg, convert(Array{String,1}, update_args))
    end
    if 0 < consumed
      i_arg += consumed
    else
      # push!(unparsed, _args[i_arg])
      i_arg += 1
    end
  end
  return unparsed
end

valency(::StructUpdater{String}) = 1
valency(::StructUpdater{Int}) = 1
valency(::StructUpdater{Bool}) = 0

function update!{R}(o::R, p::StructUpdater{String}, args::Array{String,1})
  @assert 2 == length(args)
  setfield!(o, p.sym, args[2])
end

function update!{R}(o::R, p::StructUpdater{Int}, args::Array{String,1})
  @assert 2 == length(args)
  setfield!(o, p.sym, int(args[2]))
end

function update!{R}(o::R, p::StructUpdater{Bool}, args::Array{String,1})
  @assert 1 == length(args)
  setfield!(o, p.sym, true)
end

function call(o::CommandArgs)
  @eval $(o.action(o.args))
end

function main()
  main(convert(Array{String,1}, ARGS))
end

function main(_args::Array{String,1})
  o = CommandArgs()
  args.update!(o, _args)
  call(o)
end

end # module
