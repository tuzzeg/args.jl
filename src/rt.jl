#
# Runtime
#

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
validate(o) = String[]

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
  v_res = validate(o)
  if !isempty(v_res)
    throw(ParseError(join(v_res, "; ")))
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
