macro args(func::Symbol, arg_exprs::Arg...)
  local args_t = symbol("_$(func)_args")
  local args = [eval(expr) for expr in arg_exprs]

  local t_members = {:($(a.sym)::$(argtype(a))) for a in args}
  local t_defaults = {a.default for a in args}
  local f_args = {:(o.$(a.sym)) for a in args}
  local p_ifs = gen_switch(
    [(match_expr(a), :(args.StructUpdater{$(argtype(a))}($(Expr(:quote, a.sym))))) for a in args],
    quote nothing end)

  gen = quote
    type $args_t
      $(t_members...)
      $args_t() = new($(t_defaults...))
    end

    $func(o::$args_t) = $func($(f_args...))

    function args.parser(p::$args_t, arg::String)
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
    function args.update!(o::args.CommandArgs, _args::Array{String,1})
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
