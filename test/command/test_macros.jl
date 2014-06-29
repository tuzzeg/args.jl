import Base.Test

include("macros.jl")
import macros: Arg, parse_arg, valencies, _valency

function test_parse_command_args()
  arg = parse_arg(:((from::String="<def>", short="-f", long="--from")))
  @assert :from == arg.sym
  @assert :String == arg.typ
  @assert String["-f", "--from"] == arg.matches
  @assert :("<def>") == arg.default
end

function test_generate_valency_dict()
  args = Arg[
    Arg(:from, :String, String["-f", "--from"], nothing),
    Arg(:to, :String, String["-t", "--to"], nothing),
    Arg(:recursive, :Bool, String["-r", "--recursive"], nothing),
  ]
  d = valencies(args)

  @assert [0, 1] == collect(keys(d))
  @assert Set(String["-r", "--recursive"]) == d[0]
  @assert Set(String["-f", "--from", "-t", "--to"]) == d[1]
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
test_generate_valency_dict()
test_valency()
