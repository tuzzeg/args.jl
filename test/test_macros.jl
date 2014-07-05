module test_macros

using Base.Test

include("../src/macros.jl")

function test_parse_command_args()
  arg = parse_arg(:((from::String="<def>", short="-f", long="--from")))
  @test :from == arg.sym
  @test :String == arg.typ
  @test String["-f", "--from"] == arg.matches
  @test :("<def>") == arg.default
  @test arg.optional
end

function test_parse_optional()
  arg = parse_arg(:((x::Int, short="-x")))
  @test :x == arg.sym
  @test :Int == arg.typ
  @test String["-x"] == arg.matches
  @test !arg.optional
end

function test_valency()
  @test 0 == _valency(:Bool)
  @test 1 == _valency(:String)
  @test 1 == _valency(:Int)

  @test -1 == _valency(:(Union(Bool, Nothing)))
  @test -1 == _valency(:(Union(String, Nothing)))
  @test -1 == _valency(:(Union(Int, Nothing)))
end

test_parse_command_args()
test_parse_optional()
test_valency()

end # module
