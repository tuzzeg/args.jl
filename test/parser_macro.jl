module parser_macros

using Base.Test

require("src/args.jl")
import args: @command, @struct
import args

@command(mv,
  (from::String, long="--from", required=true), # required
  (to::String, long="--to"), # optional
  (file::String="file.csv", short="-f", long="--file"), # optional
  (recursive::Bool, short="-r", required=true), # required
begin
  "mv from=$from to=$to file=$file recursive=$recursive"
end)

@struct(Range,
  (from::String, long="--from"),
  (to::String, long="--to")
)

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

  @test 1 == args.valency(typeof(o), "--from")
  @test 1 == args.valency(typeof(o), "--to")
  @test 1 == args.valency(typeof(o), "-f")
  @test 0 == args.valency(typeof(o), "-r")
  @test -1 == args.valency(typeof(o), "--not-exists")
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

  @test 1 == args.valency(typeof(o), "--from")
  @test 1 == args.valency(typeof(o), "--to")
  @test 1 == args.valency(typeof(o), "--op")
  @test -1 == args.valency(typeof(o), "-r")
  @test -1 == args.valency(typeof(o), "-f")
end

# TODO invalid valency: --from --to
# TODO override: -c conf --conf.inner.str=aaa

parse_command()
parse_command_no_r()

parse_inner()

end # module
