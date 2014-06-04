module args

export
  CommandArgs, StructUpdater,
  upadte!, parser

type CommandArgs
  sym::Symbol
  args
  CommandArgs() = new()
end

abstract Updater{T}

immutable StructUpdater{T} <: Updater{T}
  sym::Symbol
end

parser(o, ::String) = throw(ParseError("Not supported type [$(typeof(o))]"))

function update!{R}(o::R, args::Array{String,1})
  unparsed = Array{String,1}
  i_arg = 1
  consumed = 0
  while i_arg <= length(args)
    arg = args[i_arg]
    if beginswith(arg, "-")
      args_split = split(arg, "=", 2)
      if length(args_split) == 1
        p_arg = parser(o, arg)
        if !isa(p_arg, Nothing)
          v = valency(p_arg)
          consumed = 1+v
          update_args = args[i_arg:i_arg+v]
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
      update!(o, p_arg, convert(Array{String,1}, update_args))
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

end # module
