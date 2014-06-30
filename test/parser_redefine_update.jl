include("m1.jl")

module parser_redefine_update

using Base.Test

import m1: update!

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
