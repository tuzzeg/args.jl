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
    $(_gen_update(sym, args))
  end)
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
      push!(cases, (:(0 < (v=valency($(_arg_type(a.typ)), arg))), quote v end))
    end
  end

  quote
    function valency(::$t_sym, arg)
      $(_gen_switch(cases, quote -1 end))
    end
  end
end

# Generate update!(o::_mv_args, args::Array{String, 1})
function _gen_update(sym, args)
  local t_sym = symbol("_$(sym)_args")

  cases = (Expr, Expr)[]
  fallovers = Expr[]
  for a in args
    parser = _parser(a.typ)
    if parser != nothing
      push!(cases, (_match_expr(a), quote o.$(a.sym) = $(parser)(tail) end))
    else
      push!(fallovers, quote updated |= update!(o.$(a.sym), args) end)
    end
  end

  last_else = quote
    updated = false
    $(fallovers...)
  end

  quote
    function update!(o::$(t_sym), args::Array{String, 1})
      arg, tail = args[1], args[2:end]
      updated = true
      $(_gen_switch(cases, last_else))
      updated
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

function _valency(typ)
  t = _arg_type(typ)
  if t == :Bool
    0
  elseif t == :String || t == :Int
    1
  else
    -1
  end
end

function _parser(typ)
  t = _arg_type(typ)
  if t == :Bool
    :parse_bool
  elseif t == :String
    :parse_string
  elseif t == :Int
    :parse_int
  else
    nothing
  end
end

# Return argument type
# x::Int -> Int
# y::Union(String, Nothing) -> String
# z::Range -> Range
function _arg_type(a::Symbol)
  a
end

function _arg_type(a::Expr)
  if a.head == :call && length(a.args) == 3 && a.args[1] == :Union && a.args[3] == :Nothing
    _arg_type(a.args[2])
  else
    a
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

function _gen_switch(cases::Array{(Expr,Expr),1}, default)
  head = quote nothing end
  last = head
  for (cond, res) in cases
    last = _push_last!(last, :($cond ? $res : nothing))
  end
  # TODO push default to last statement
  _push_last!(last, default)
  head
end

# update else clause in if expression with 'expr'
# return reference to updated if
function _push_last!(if_expr, expr)
  last = if_expr
  while isa(last, Expr)
    last, if_expr = if_expr.args[end], last
  end
  if_expr.args[end] = expr
  if_expr
end

end # module