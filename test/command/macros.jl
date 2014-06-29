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

  local t_sym = symbol("_$(sym)_args")
  local t_members = {:($(a.sym)::$(a.typ)) for a in args}
  local t_defaults = {a.default for a in args}

  gen = quote
    type $t_sym
      $(t_members...)
      $t_sym() = new($(t_defaults...))
    end
  end
  esc(gen)
end

function parse_arg(expr::Expr)
  sym, typ, default = _parse_sym(expr)
  matches = String[]
  _push_nonempty!(matches, _get_by_key(expr, :short))
  _push_nonempty!(matches, _get_by_key(expr, :long))
  Arg(sym, typ, matches, default)
end

# Generate valency dict: {0=>["-r"], 1=>["-f", "--from", ...], }
function valencies(args::Array{Arg, 1})
  d = Dict{Int, Set{String}}()
  for a in args
    matches = get!(d, _valency(a.typ), Set{String}())
    push!(matches, a.matches...)
  end
  d
end

function _valency(a::Symbol)
  if a == :Bool
    0
  elseif a == :String || a == :Int
    1
  else
    throw(ArgumentError("Valency not defined for type $a"))
  end
end

function _valency(a::Expr)
  if a.head == :call
    if length(a.args) == 3 && a.args[1] == :Union && a.args[3] == :Nothing
      _valency(a.args[2])
    else
      throw(ArgumentError("Support Union(type, Nothing) expressions only, but found [$a]"))
    end
  else
    throw(ArgumentError("Support Union expressions only, but found [$a]"))
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

end # module
