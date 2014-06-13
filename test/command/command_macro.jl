using Base.Test

include("macros.jl")
import macros: @command, empty

# Runtime {
parse_string(args::Array{String, 1}) = args[1]
parse_int(args::Array{String, 1}) = int(args[1])
parse_bool(args::Array{String, 1}) = true
# }

@command(mv,
  (from::String, long="--from", required=true), # required
  (to::String, long="--to"), # optional
  (file::String="file.csv", short="-f", long="--file"), # optional
  (recursive::Bool, short="-r", required=true), # required
begin
  "mv from=$from to=$to file=$file recursive=$recursive"
end)

# { generated: mv

#type _mv_args
#  from::Union(String, Nothing)
#  to::Union(String, Nothing)
#  file::String
#  recursive::Union(Bool, Nothing)
#  _mv_args() = new(nothing, nothing, "file.csv", nothing)
#end

function valency(::Type{_mv_args}, arg::String)
  if arg in ["--from", "--to", "-f", "--file"]
    1
  elseif arg in ["-r", "--recursive"]
    0
  else
    -1
  end
end

function update!(o::_mv_args, args::Array{String, 1})
  arg, tail = args[1], args[2:end]
  if arg == "--from"
    o.from = parse_string(tail)
  elseif arg == "--to"
    o.to = parse_string(tail)
  elseif arg == "-f" || arg == "--file"
    o.file = parse_string(tail)
  elseif arg == "-r" || arg == "--recursive"
    o.recursive = parse_bool(tail)
  end
end

function validate(o::_mv_args)
  errors = String[]
  if o.from == nothing
    push!(errors, "required: --from")
  elseif o.recursive == nothing
    push!(errors, "required: --recursive")
  end
  errors
end

# }

# @struct(Range,
#   (from::String, long="--from"),
#   (to::String, long="--to"),

# {
type Range
  from::String
  to::String
  Range() = new()
end

empty(::Type{Range}) = Range()

function valency(::Type{Range}, arg::String)
  if arg in ["--from", "--to"]
    1
  else
    -1
  end
end

function update!(o::Range, args::Array{String, 1})
  arg, tail = args[1], args[2:end]
  updated = true
  if arg == "--from"
    o.from = parse_string(tail)
  elseif arg == "--to"
    o.to = parse_string(tail)
  else
    updated = false
  end
  updated
end

function validate(o::Range)
  String[]
end

# }

@command(mv1,
  (range::Range, ),
  (op::String, long="--op"),
begin
  "mv1 range=$range op=$op"
end)

# {
#type _mv1_args
#  range::Range
#  op::String
#end

function valency(::Type{_mv1_args}, arg::String)
  v = -1
  if arg in ["--op"]
    1
  elseif 0 < (v = valency(Range, arg))
    v
  else
    -1
  end
end

function update!(o::_mv1_args, args::Array{String, 1})
  arg, tail = args[1], args[2:end]
  updated = true
  if arg == "--op"
    o.op = parse_string(tail)
  elseif arg == "--to"
    o.range.to = parse_string(tail)
  elseif arg == "--from"
    o.range.from = parse_string(tail)
  else
    updated = false
    updated |= update!(o.range, args)
  end
  updated
end

function validate(o::_mv1_args)
  errors = String[]
  push!(errors, validate(o.range))
  errors
end

# }

type Conf
  contents::String # read config file here
end

# @command(cmd1,
#   (conf::Conf, short="-c"),

# {
# }

function parse_command()
  o = _mv_args()
  update!(o, String["--from", "/path/from"])
  update!(o, String["--to", "/path/to"])
  update!(o, String["-r"])

  @test "/path/from" == o.from
  @test "/path/to" == o.to
  @test o.recursive
end

function parse_command_no_r()
  o = _mv_args()
  update!(o, String["--from", "/path/from"])
  update!(o, String["--to", "/path/to"])

  @test "/path/from" == o.from
  @test "/path/to" == o.to
  @test nothing == o.recursive

  errors = validate(o)
  @assert "required: --recursive" == errors[1]
end

function parse_inner()
  o = _mv1_args()
  update!(o, String["--from", "/path/from"])
  update!(o, String["--to", "/path/to"])
  update!(o, String["--op", "op"])

  @test "/path/from" == o.range.from
  @test "/path/to" == o.range.to
  @test "op" == o.op
end

parse_command()
parse_command_no_r()

parse_inner()

# invalid valency: --from --to
# override: -c conf --conf.inner.str=aaa

