using Base.Test

require("src/args.jl")
import args: StructUpdater, update!, parser, validate

# @command(mv,
#  (from::String, long="--from", required=true), # required
#  (to::String, long="--to"), # optional
#  (file::String="file.csv", short="-f", long="--file"), # optional
#  (recursive::Bool, short="-r", required=true), # required

# { generated: mv

type _mv_args
  from::Union(String, Nothing)
  to::Union(String, Nothing)
  file::String
  recursive::Union(Bool, Nothing)
  _mv_args() = new(nothing, nothing, "file.csv", nothing)
end

function parser(o::_mv_args, arg::String)
  if arg == "--from"
    StructUpdater{String}(:from)
  elseif arg == "--to"
    StructUpdater{String}(:to)
  elseif arg == "-f" || arg == "--file"
    StructUpdater{String}(:to)
  elseif arg == "-r" || arg == "--recursive"
    StructUpdater{Bool}(:recursive)
  else
    nothing
  end
end

function validate(o::_mv_args)
  errors = String[]
  if o.from == nothing
    push!(errors, "--from required")
  elseif o.recursive == nothing
    push!(errors, "--recursive required")
  end
  errors
end

# }

function parse_command()
  args = String["--from", "/path/from", "--to", "/path/to"]
  o = _mv_args()
  args1 = update!(o, args)

  @test "/path/from" == o.from
  @test "/path/to" == o.to
  @test nothing == o.recursive
end

parse_command()
