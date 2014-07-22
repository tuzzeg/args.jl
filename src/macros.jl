immutable Arg
  sym::Symbol
  typ
  matches::Array{String,1}
  default
  optional::Bool
end

macro command(sym, exprs...)
  local arg_exprs = exprs[1:end-1]
  local body_expr = exprs[end]
  local args = map(parse_arg, arg_exprs)

  local t_sym = symbol("_$(sym)_args")

  gen = esc(quote
    $(_gen_argtype(t_sym, args))
    $(_gen_valency(t_sym, args))
    $(_gen_update(t_sym, args))
    $(_gen_validate(t_sym, args))
    $(_gen_metadata(sym, t_sym))
    $(_gen_func_typed(sym, t_sym, args))
    $(_gen_func(sym, args, body_expr))
  end)
  gen
end

macro struct(sym, exprs...)
  local args = map(parse_arg, exprs)
  gen = esc(quote
    $(_gen_argtype(sym, args))
    $(_gen_valency(sym, args))
    $(_gen_update(sym, args))
    $(_gen_validate(sym, args))
    args.empty(::Type{$sym}) = $sym()
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
function _gen_argtype(t_sym, args)
  local t_members = {:($(a.sym)::$(_typ(a))) for a in args}
  local t_defaults = {a.default for a in args}

  quote
    type $t_sym
      $(t_members...)
      $t_sym() = new($(t_defaults...))
    end
  end
end

# Generate valency function.
# valency(::ArgType, arg::String)
# which returns number of additional arguments for the given [arg]ument
function _gen_valency(t_sym, args)
  cases = (Expr, Expr)[]
  for a in args
    if _is_whitelisted_type(a.typ)
      push!(cases, (_match_expr(a), quote args.valency($(a.typ)) end))
    else
      push!(cases, (:(0 < (v=args.valency($(a.typ), arg))), quote v end))
    end
  end

  quote
    function args.valency(::Type{$t_sym}, arg)
      $(_gen_switch(cases, quote -1 end))
    end
  end
end

# Generate update!(o::ArgType, args::Array{String, 1})
function _gen_update(t_sym, _args)
  cases = (Expr, Expr)[]
  fallovers = Expr[]
  for a in _args
    if _is_whitelisted_type(a.typ)
      push!(cases, (_match_expr(a), quote o.$(a.sym) = args.parse($(a.typ), tail) end))
    else
      push!(fallovers, quote updated |= args.update!(o.$(a.sym), _args) end)
    end
  end

  last_else = quote
    updated = false
    $(fallovers...)
  end

  quote
    function args.update!(o::$(t_sym), _args::Array{String, 1})
      arg, tail = _args[1], _args[2:end]
      updated = true
      $(_gen_switch(cases, last_else))
      updated
    end
  end
end

# Generate validate(o::ArgType)
function _gen_validate(t_sym, args)
  cases = (Expr, Expr)[]
  validate_exprs = Expr[]
  for a in args
    if !a.optional
      push!(cases, (:(o.$(a.sym) == nothing),
        quote
          push!(errors, "required: " * $(join(a.matches, "|")))
        end))
    end
    push!(validate_exprs,
      quote
        push!(errors, args.validate(o.$(a.sym))...)
      end)
  end
  last_else = quote end

  quote
    function args.validate(o::$(t_sym))
      errors = String[]
      $(_gen_switch(cases, last_else))
      $(validate_exprs...)
      errors
    end
  end
end

# Generate function mv(::ArgType) that calls function with arguments.
function _gen_func_typed(sym, t_sym, _args)
  local f_args = {:(o.$(a.sym)) for a in _args}
  quote
    function $sym(o::$t_sym)
      $sym($(f_args...))
    end
  end
end

# Generate function mv(args...).
function _gen_func(sym, _args, body)
  local f_args = {:($(a.sym)::$(_typ(a))) for a in _args}
  quote
    function $sym($(f_args...))
      $body
    end
  end
end

# Generate metadata(::Type{ArgType}) method,
# which returns a Command object with info about command.
function _gen_metadata(sym, t_sym)
  local cmd = "$sym"
  quote
    args.metadata(o::Type{$t_sym}) = args.Command($cmd, $t_sym, $sym)
  end
end

function parse_arg(expr::Expr)
  sym, typ, default, optional = _parse_sym(expr)
  matches = String[]
  _push_nonempty!(matches, _get_by_key(expr, :short))
  _push_nonempty!(matches, _get_by_key(expr, :long))
  Arg(sym, typ, matches, default, optional)
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
      typ = child_expr.args[2]
      return (sym, typ, :(args.empty($(child_expr.args[2]))), false)
    # case sym::Typ=default
    elseif child_expr.head == :(=) && child_expr.args[1].head == :(::)
      sym = child_expr.args[1].args[1]
      typ = child_expr.args[1].args[2]
      default = child_expr.args[2]
      return (sym, typ, default, true)
    end
  end
  throw(ParseError("Not found \$sym::\$typ expression in [$expr]"))
end

_typ(a) = a.optional ? a.typ : :(Union($(a.typ), Nothing))

_whitelisted_type = Set{Symbol}([
  :String, :ASCIIString, :UTF8String,
  :Bool,
  :Int, :Int8, :Int16, :Int32, :Int64,
  :Float16, :Float32, :Float64
])
_is_whitelisted_type(t::Symbol) = in(t, _whitelisted_type)

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


function _gen_switch(cases::Array{(Expr,Expr),1}, default)
  head = quote nothing end
  last = head
  for (cond, res) in cases
    last = _push_last!(last, :($cond ? $res : nothing))
  end
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
