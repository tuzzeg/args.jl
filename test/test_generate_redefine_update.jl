include("m1.jl")

module parser_redefine_update

# Redefine update! function, make sure it not clash with args.update! in generated code.

using Base.Test

import m1: update!

require("src/args.jl")
import args: @command
import args

@command(mv,
  (from::String, long="--from"),
  (to::String, long="--to"),
  (file::String="file.csv", short="-f", long="--file"),
  (recursive::Bool, short="-r"),
begin
  "mv from=$from to=$to file=$file recursive=$recursive"
end)

function test_parse()
  o = _mv_args()
  args.update!(o, String["--from", "/path/from"])
  args.update!(o, String["--to", "/path/to"])
  args.update!(o, String["-r"])

  @test "/path/from" == o.from
  @test "/path/to" == o.to
  @test o.recursive
end

test_parse()

end # module
