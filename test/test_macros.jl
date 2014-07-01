module test_macros

import Base.Test

require("src/macros.jl")
import args: parse_arg, _valency

function test_parse_command_args()
  arg = parse_arg(:((from::String="<def>", short="-f", long="--from")))
  @assert :from == arg.sym
  @assert :String == arg.typ
  @assert String["-f", "--from"] == arg.matches
  @assert :("<def>") == arg.default
end

function test_valency()
  @assert 0 == _valency(:Bool)
  @assert 1 == _valency(:String)
  @assert 1 == _valency(:Int)

  @assert 0 == _valency(:(Union(Bool, Nothing)))
  @assert 1 == _valency(:(Union(String, Nothing)))
  @assert 1 == _valency(:(Union(Int, Nothing)))
end

test_parse_command_args()
test_valency()

end # module
