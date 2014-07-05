module test_default_expr

using Base.Test

default_file = "file1.csv"

require("src/args.jl")
import args: @command, @struct
import args

@command(mv,
  (file::String=default_file, short="-f", long="--file"),
  (recursive::Bool=false, short="-r"),
begin
  "mv file=$file recursive=$recursive"
end)

function parse_command()
  o = _mv_args()

  @test "file1.csv" == o.file
  @test !o.recursive
  @test "mv file=file1.csv recursive=false" == mv(o)

  default_file = "ff"
  @test "mv file=ff recursive=false" == mv(o)
end

end # module
