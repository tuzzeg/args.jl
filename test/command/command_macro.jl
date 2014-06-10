import Base.Test

immutable Arg
  sym::Symbol
  typ::Symbol
  matches::Array{String,1}
  default
end

function parse_arg(expr::Expr)
  sym, typ, default = _parse_sym(expr)
  matches = String[]
  _push_nonempty!(matches, _get_by_key(expr, :short))
  _push_nonempty!(matches, _get_by_key(expr, :long))
  Arg(sym, typ, matches, default)
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
      typ = child_expr.args[2]
      return (sym, typ, nothing)
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
    throw(ParseError("Expected tuple, got [$expr]"))
  end
  r = nothing
  for child_expr in expr.args
    if child_expr.head == :(=) && child_expr.args[1] == sym
      r = child_expr.args[2]
    end
  end
  r
end

function test_parse_command_args()
  arg = parse_arg(:((from::String, short="-f", long="--from")))
  @assert :from == arg.sym
  @assert :String == arg.typ
  @assert String["-f", "--from"] == arg.matches
  @assert nothing == arg.default
end

test_parse_command_args()
