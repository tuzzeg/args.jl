import Base.Test

include("macros.jl")
import macros: parse_arg

function test_parse_command_args()
  arg = parse_arg(:((from::String, short="-f", long="--from")))
  @assert :from == arg.sym
  @assert :String == arg.typ
  @assert String["-f", "--from"] == arg.matches
  @assert nothing == arg.default
end

test_parse_command_args()
