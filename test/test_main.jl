require("src/args.jl")
using args

require("test/commands1.jl")
require("test/commands2.jl")

function test_main()
  s = args.main(String["commands1.mv", "--from=/path/from", "--to", "/path/to", "-r"])
  @test "mv from=/path/from to=/path/to file=file.csv recursive=true" == s
end

test_main()
