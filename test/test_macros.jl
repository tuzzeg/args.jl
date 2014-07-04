import Base.Test

module test_macros

include("../src/macros.jl")

function test_parse_command_args()
  arg = parse_arg(:((from::String="<def>", short="-f", long="--from")))
  @assert :from == arg.sym
  @assert :String == arg.typ
  @assert String["-f", "--from"] == arg.matches
  @assert :("<def>") == arg.default
  @assert arg.optional
end

function test_parse_optional()
  arg = parse_arg(:((x::Int, short="-x")))
  @assert :x == arg.sym
  @assert :Int == arg.typ
  @assert String["-x"] == arg.matches
  @assert !arg.optional
end

function test_valency()
  @assert 0 == _valency(:Bool)
  @assert 1 == _valency(:String)
  @assert 1 == _valency(:Int)

  @assert -1 == _valency(:(Union(Bool, Nothing)))
  @assert -1 == _valency(:(Union(String, Nothing)))
  @assert -1 == _valency(:(Union(Int, Nothing)))
end

test_parse_command_args()
test_parse_optional()
test_valency()

end # module
