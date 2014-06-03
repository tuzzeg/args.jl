using Base.Test

abstract Parser{T}

immutable StructParser{T} <: Parser{T}
  sym::Symbol
end

function update!{R, T<:String}(o::R, p::Parser{R}, args::Array{T,1})
  unparsed = Array{T,1}
  i_arg = 1
  consumed = 0
  while i_arg <= length(args)
    arg = args[i_arg]
    if beginswith(arg, "-")
      p_arg = parser(p, arg)
      if !isa(p_arg, Nothing)
        v = valency(p_arg)
        update!(o, p_arg, args[i_arg:i_arg+v])
        consumed = 1+v
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

valency(::StructParser{String}) = 1
valency(::StructParser{Int}) = 1
valency(::StructParser{Bool}) = 0

function update!{R, T<:String}(o::R, p::StructParser{String}, args::Array{T,1})
  @assert 2 == length(args)
  setfield!(o, p.sym, args[2])
end

function update!{R, T<:String}(o::R, p::StructParser{Int}, args::Array{T,1})
  @assert 2 == length(args)
  setfield!(o, p.sym, int(args[2]))
end

function update!{R, T<:String}(o::R, p::StructParser{Bool}, args::Array{T,1})
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

immutable MoveParser <: Parser{MoveArgs}
end

function parser(p::MoveParser, arg::String)
  if arg == "--from"
    StructParser{String}(:from)
  elseif arg == "--to"
    StructParser{String}(:to)
  elseif arg == "-r" || arg == "--recursive"
    StructParser{Bool}(:recursive)
  else
    nothing
  end
end
# }

function parse_args()
  args = String["--from", "/path/from", "--to", "/path/to", "-r"]
  o = MoveArgs()
  p = MoveParser()
  args1 = update!(o, p, args)

  @test "/path/from" == o.from
  @test "/path/to" == o.to
  @test o.recursive
end

parse_args()
