module parser_macros

using Base.Test

require("src/args.jl")
import args: @command
import args

@command(mv,
  (from::String, long="--from", required=true), # required
  (to::String, long="--to"), # optional
  (file::String="file.csv", short="-f", long="--file"), # optional
  (recursive::Bool, short="-r", required=true), # required
begin
  "mv from=$from to=$to file=$file recursive=$recursive"
end)

# @struct(Range,
#   (from::String, long="--from"),
#   (to::String, long="--to"),

# {
type Range
  from::String
  to::String
  Range() = new()
end

args.empty(::Type{Range}) = Range()

function args.valency(::Type{Range}, arg::String)
  if arg in ["--from", "--to"]
    1
  else
    -1
  end
end

function args.update!(o::Range, _args::Array{String, 1})
  arg, tail = _args[1], _args[2:end]
  updated = true
  if arg == "--from"
    o.from = args.parse_string(tail)
  elseif arg == "--to"
    o.to = args.parse_string(tail)
  else
    updated = false
  end
  updated
end

function args.validate(o::Range)
  String[]
end

# }

@command(mv1,
  (range::Range, ),
  (op::String, long="--op"),
begin
  "mv1 range=$range op=$op"
end)

type Conf
  contents::String # read config file here
end

#
# Test methods

function parse_command()
  o = _mv_args()
  args.update!(o, String["--from", "/path/from"])
  args.update!(o, String["--to", "/path/to"])
  args.update!(o, String["-r"])

  @test "/path/from" == o.from
  @test "/path/to" == o.to
  @test o.recursive

  @test 1 == args.valency(o, "--from")
  @test 1 == args.valency(o, "--to")
  @test 1 == args.valency(o, "-f")
  @test 0 == args.valency(o, "-r")
  @test -1 == args.valency(o, "--not-exists")
end

function parse_command_no_r()
  o = _mv_args()
  args.update!(o, String["--from", "/path/from"])
  args.update!(o, String["--to", "/path/to"])

  @test "/path/from" == o.from
  @test "/path/to" == o.to
  @test nothing == o.recursive

  errors = args.validate(o)
  @assert "required: -r" == errors[1]
end

function parse_inner()
  o = _mv1_args()
  args.update!(o, String["--from", "/path/from"])
  args.update!(o, String["--to", "/path/to"])
  args.update!(o, String["--op", "op"])

  @test "/path/from" == o.range.from
  @test "/path/to" == o.range.to
  @test "op" == o.op

  @test 1 == args.valency(o, "--from")
  @test 1 == args.valency(o, "--to")
  @test 1 == args.valency(o, "--op")
  @test -1 == args.valency(o, "-r")
  @test -1 == args.valency(o, "-f")
end

# TODO invalid valency: --from --to
# TODO override: -c conf --conf.inner.str=aaa

parse_command()
parse_command_no_r()

parse_inner()

end # module
