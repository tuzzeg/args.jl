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

parse_string(args::Array{String, 1}) = args[1]
parse_int(args::Array{String, 1}) = int(args[1])
parse_bool(args::Array{String, 1}) = true
parse_f16(args::Array{String, 1}) = parsefloat(Float16, args[1])
parse_f32(args::Array{String, 1}) = parsefloat(Float32, args[1])
parse_f64(args::Array{String, 1}) = parsefloat(Float64, args[1])

valency(::Type{String}, arg::String) = 1
valency(::Type{Int}, arg::String) = 1
valency(::Type{Bool}, arg::String) = 0
valency{T<:FloatingPoint}(::Type{T}, arg::String) = 1

function valency(u::Type{UnionType}, arg::String)
  if length(u.types) == 2 && is(u.types[2], Nothing)
    valency(u.types[1], arg)
  else
    -1
  end
end

validate(o) = String[]
update!(o, args::Array{String, 1}) = false

metadata(t) = throw(ArgumentError("Metadata not defined for type [$t]"))

empty(x) = nothing
