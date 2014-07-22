# Types
immutable Command
  command::String
  typ::DataType
  action::Function
end

main() = main(ARGS)
main(_args) = main(convert(Array{String,1}, _args))

# Scan all used modules for @command definition.
function main(_args::Array{String,1})
  commands = _commands()
  if length(_args) <= 0
    throw(ArgumentError("Expected command, one of [$(join(keys(commands), " "))]"))
  end
  cmd, _args = _args[1], _args[2:end]
  if !haskey(commands, cmd)
    throw(ArgumentError("Unknown command, expected [$(join(keys(commands), " "))]"))
  end
  meta = commands[cmd]
  o = meta.typ()
  _update(o, _args)
  _validate(o)
  meta.action(o)
end

function _commands()
  _type{T}(f::Function, ::Type{Type{T}}) = f(T)
  _type(f::Function, ::Any) = nothing

  commands = Dict{String, Command}()
  for method in methods(args.metadata)
    mdl = method.func.code.module
    _type(method.sig[1]) do typ
      meta = args.metadata(typ)
      commands["$mdl.$(meta.command)"] = meta
    end
  end
  commands
end

function _update{T}(o::T, _args::Array{String,1})
  unparsed = Array{String,1}
  i_arg = 1
  consumed = 0
  while i_arg <= length(_args)
    arg = _args[i_arg]
    if beginswith(arg, "-")
      args_split = split(arg, "=", 2)
      if length(args_split) == 1
        v = args.valency(T, arg)
        if 0<=v
          consumed = 1+v
          args.update!(o, convert(Array{String,1}, _args[i_arg:i_arg+v]))
        end
      else
        v = args.valency(T, args_split[1])
        if 1<v
          throw(ParseError("--option=value should be used only with valency=1, arg=[$arg]"))
        elseif 0<=v
          consumed = 1
          args.update!(o, convert(Array{String,1}, args_split))
        end
      end
    end
    if 0 < consumed
      i_arg += consumed
    else
      push!(unparsed, args[i_arg])
      i_arg += 1
    end
  end
  return unparsed
end

function _validate(o)
  errors = args.validate(o)
  if 0 < length(errors)
    throw(ArgumentError(join(errors, "; ")))
  end
end

#
# Runtime
#

parse{T<:String}(::Type{T}, args::Array{String, 1}) = args[1]
parse{T<:Signed}(::Type{T}, args::Array{String, 1}) = parseint(T, args[1])
parse{T<:Unsigned}(::Type{T}, args::Array{String, 1}) = parseint(T, args[1])
parse(::Type{Bool}, args::Array{String, 1}) = true
parse{T<:FloatingPoint}(::Type{T}, args::Array{String, 1}) = parsefloat(T, args[1])

function parse(u::UnionType, args::Array{String, 1})
  if length(u.types) == 2 && is(u.types[2], Nothing)
    parse(u.types[1], args)
  elseif length(u.types) == 2 && is(u.types[1], Nothing)
    parse(u.types[2], args)
  else
    false
  end
end

valency{T<:String}(::Type{T}) = 1
valency{T<:Signed}(::Type{T}) = 1
valency{T<:Unsigned}(::Type{T}) = 1
valency{T<:FloatingPoint}(::Type{T}) = 1
valency(::Type{Bool}) = 0

function valency(u::UnionType)
  if length(u.types) == 2 && is(u.types[2], Nothing)
    valency(u.types[1])
  elseif length(u.types) == 2 && is(u.types[1], Nothing)
    valency(u.types[2])
  else
    -1
  end
end

function valency(u::UnionType, arg::String)
  if length(u.types) == 2 && is(u.types[2], Nothing)
    valency(u.types[1], arg)
  elseif length(u.types) == 2 && is(u.types[1], Nothing)
    valency(u.types[2], arg)
  else
    -1
  end
end

validate(o) = String[]
update!(o, args::Array{String, 1}) = false

metadata(t) = throw(ArgumentError("Metadata not defined for type [$t]"))

empty(x) = nothing
