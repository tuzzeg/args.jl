using Base.Test

abstract Updater{T}

immutable StructUpdater{T} <: Updater{T}
  sym::Symbol
end

function update!{R, T<:String}(o::R, p::Updater{R}, args::Array{T,1})
  unparsed = Array{T,1}
  i_arg = 1
  consumed = 0
  while i_arg <= length(args)
    arg = args[i_arg]
    if beginswith(arg, "-")
      args_split = split(arg, "=", 2)
      if length(args_split) == 1
        p_arg = parser(p, arg)
        if !isa(p_arg, Nothing)
          v = valency(p_arg)
          consumed = 1+v
          update_args = args[i_arg:i_arg+v]
        end
      else
        p_arg = parser(p, args_split[1])
        if !isa(p_arg, Nothing)
          v = valency(p_arg)
          if v != 1
            throw(ParserError("--option=value should be used only with valency=1, p=[$p_arg]"))
          end
          consumed = 1
          update_args = args_split
        end
      end
      update!(o, p_arg, update_args)
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

function update!{R, T<:String}(o::R, p::StructUpdater{String}, args::Array{T,1})
  @assert 2 == length(args)
  setfield!(o, p.sym, args[2])
end

function update!{R, T<:String}(o::R, p::StructUpdater{Int}, args::Array{T,1})
  @assert 2 == length(args)
  setfield!(o, p.sym, int(args[2]))
end

function update!{R, T<:String}(o::R, p::StructUpdater{Bool}, args::Array{T,1})
  @assert 1 == length(args)
  setfield!(o, p.sym, true)
end

# ls --dir=/path/ls
# ls(dir="/path/ls")

# conf{from="/path/from", to="/path/to"}
# move -c conf
# move(from="/path/from", to="/path/to")


# move --from=/path/from --to /path/to -r
# move(from="/path/from", to="/path/to")
# { generated: Move specific
type MoveArgs
  from::String
  to::String
  recursive::Bool
  MoveArgs() = new("", "", false)
end

immutable MoveUpdater <: Updater{MoveArgs}
end

function parser(p::MoveUpdater, arg::String)
  if arg == "--from"
    StructUpdater{String}(:from)
  elseif arg == "--to"
    StructUpdater{String}(:to)
  elseif arg == "-r" || arg == "--recursive"
    StructUpdater{Bool}(:recursive)
  else
    nothing
  end
end
# }

function parse_args()
  args = String["--from", "/path/from", "--to", "/path/to", "-r"]
  o = MoveArgs()
  p = MoveUpdater()
  args1 = update!(o, p, args)

  @test "/path/from" == o.from
  @test "/path/to" == o.to
  @test o.recursive
end

function parse_args1()
  args = String["--from=/path/from", "--to", "/path/to", "-r"]
  o = MoveArgs()
  p = MoveUpdater()
  args1 = update!(o, p, args)

  @test "/path/from" == o.from
  @test "/path/to" == o.to
  @test o.recursive
end

parse_args()
parse_args1()
