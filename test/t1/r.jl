require("src/args.jl")
import args: @args, @main, Arg, CommandArgs, StructUpdater, update!, parser, call

# Common arguments for all commands
# Can be omitted in commands
# -f --from
# -t --to
# -d --dir

# Command move
#    --files
#    --max
@args(move,
  Arg{String}(:from, "--from"; short="-f", default=""),
  Arg{String}(:to, "--to"; short="-t", default=""),
  Arg{String}(:files, "--files"; default=""),
  Arg{Int}(:max, "--max"; default=0)
)
function move(from::String="", to::String="", files::String="", max::Int=0)
  println("move, from=$from to=$to files=$files max=$max")
end

# Command copy
# -r --recursive
#    --depth
@args(copy,
  Arg{String}(:from, "--from"; short="-f", default=""),
  Arg{String}(:to, "--to"; short="-t", default=""),
  Arg{Bool}(:recursive, "--recursive"; short="-r"),
  Arg{Int}(:depth, "--depth"; default=1),
)
function copy(from::String="", to::String="", recursive::Bool=false, depth::Int=0)
  println("copy, from=$from to=$to recursive=$recursive depth=$depth")
end

# Command ls
@args(ls,
  Arg{String}(:dir, "--dir"; short="-d", default="")
)
function ls(dir::String="")
  println("ls, dir=$dir")
end

@main(move, copy, ls)
args.main()
