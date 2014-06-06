require("src/args.jl")
import args: @args, @main, Arg, CommandArgs, StructUpdater, main, parser

include("m1.jl")
import m1: update!

@args(move,
  Arg{String}(:from, "--from"; short="-f", default=""),
  Arg{String}(:to, "--to"; short="-t", default=""),
  Arg{String}(:files, "--files"; default=""),
  Arg{Int}(:max, "--max"; default=0)
)
function move(from::String="", to::String="", files::String="", max::Int=0)
  "move from=$from to=$to files=$files max=$max"
end

@main(move, copy, ls)

function test_parse()
  r = args.main(String["move", "--from=/path/from"])
  @assert "move from=/path/from to= files= max=0" == r
end

test_parse()
