require("src/args.jl")
import args: @args, @main, Arg, CommandArgs, main

include("m1.jl")
import m1: update!

@args(mv,
  Arg{String}(:from, "--from"; short="-f", default=""),
  Arg{String}(:to, "--to"; short="-t", default=""),
  Arg{String}(:files, "--files"; default=""),
  Arg{Int}(:max, "--max"; default=0)
)
function mv(from::String="", to::String="", files::String="", max::Int=0)
  "mv from=$from to=$to files=$files max=$max"
end

@main(mv, copy, ls)

function test_parse()
  r = args.main(String["mv", "--from=/path/from"])
  @assert "mv from=/path/from to= files= max=0" == r
end

test_parse()
