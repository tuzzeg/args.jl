module macros

export
  @command, parse_arg, empty

immutable Arg
  sym::Symbol
  typ
  matches::Array{String,1}
  default
end

macro command(sym, exprs...)
  local arg_exprs = exprs[1:end-1]
  local body_expr = exprs[end]
  local args = map(parse_arg, arg_exprs)

  gen = esc(quote
    $(_gen_argtype(sym, args))
    $(_gen_valency(sym, args))
  end)
  println(gen)
  gen
end

# Generate arguments holder type.
# type _mv_args
#   from::Union(String, Nothing)
#   file::String
#   recursive::Union(Bool, Nothing)
#  _mv_args() = new(nothing, nothing, "file.csv", nothing)
# end
function _gen_argtype(sym, args)
  local t_sym = symbol("_$(sym)_args")
  local t_members = {:($(a.sym)::$(a.typ)) for a in args}
  local t_defaults = {a.default for a in args}

  quote
    type $t_sym
      $(t_members...)
      $t_sym() = new($(t_defaults...))
    end
  end
end

# Generate valency function.
# valency(::Type, arg::String)
# which returns number of additional arguments for the given [arg]ument
function _gen_valency(sym, args)
  local t_sym = symbol("_$(sym)_args")

  cases = (Expr, Expr)[]
  for a in args
    v = _valency(a.typ)
    if 0 <= v
      push!(cases, (_match_expr(a), quote $v end))
    else
      push!(cases, (:(0 < (v=valency($(a.typ), arg))), quote v end))
    end
  end
  quote
    function valency(::$t_sym, arg)
      $(gen_switch(cases, quote -1 end))
    end
  end
end

function parse_arg(expr::Expr)
  sym, typ, default = _parse_sym(expr)
  matches = String[]
  _push_nonempty!(matches, _get_by_key(expr, :short))
  _push_nonempty!(matches, _get_by_key(expr, :long))
  Arg(sym, typ, matches, default)
end

function _valency(a::Symbol)
  if a == :Bool
    0
  elseif a == :String || a == :Int
    1
  else
    -1
  end
end

function _valency(a::Expr)
  if a.head == :call
    if length(a.args) == 3 && a.args[1] == :Union && a.args[3] == :Nothing
      _valency(a.args[2])
    else
      -1
    end
  else
    -1
  end
end

function _match_expr(a::Arg)
  if length(a.matches) == 1
    :(arg == $(a.matches[1]))
  elseif length(a.matches) == 2
    :(arg == $(a.matches[1]) || arg == $(a.matches[2]))
  else
    throw(ArgumentError("Unsupported matches length [$(a.matches)]"))
  end
end

# in tuple expr finds '$sym::$typ[=$default]' and returns (sym, typ, default)
function _parse_sym(expr)
  if expr.head != :tuple
    throw(ParseError("Expected tuple, got [$expr]"))
  end
  for child_expr in expr.args
    # case sym::Typ
    if child_expr.head == :(::)
      sym = child_expr.args[1]
      typ = :(Union($(child_expr.args[2]), Nothing))
      return (sym, typ, :(macros.empty($(child_expr.args[2]))))
    # case sym::Typ=default
    elseif child_expr.head == :(=) && child_expr.args[1].head == :(::)
      sym = child_expr.args[1].args[1]
      typ = child_expr.args[1].args[2]
      default = child_expr.args[2]
      return (sym, typ, default)
   end
  end
  throw(ParseError("Not found \$sym::\$typ expression in [$expr]"))
 end

# push [v]alue to [c]ollection if value != nothing
function _push_nonempty!(c, v)
  if v != nothing
    push!(c, v)
  end
end

# get '$sym=value' from expr like '(xx=aa, yy=bb, ...)
function _get_by_key(expr, sym)
  if expr.head != :tuple
  end
  r = nothing
  for child_expr in expr.args
    if child_expr.head == :(=) && child_expr.args[1] == sym
      r = child_expr.args[2]
    end
  end
  r
end

empty(x) = nothing

function gen_switch(cases::Array{(Expr,Expr),1}, default)
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

end # module
