require("src/args.jl")

import args: @arg, @arg1, @main

@main(:move, :copy, :ls)

# Common arguments for all commands
# Can be omitted in commands
# -f --from
# -t --to
# -d --dir
@arg("-f", "--from", String)
@arg("-t", "--to", String)
@arg("-d", "--dir", String)

# Command move
#    --files
#    --max
@arg1(:move, "", "--files", String)
@arg1(:move, "", "--max", Int)
function move(from::String="", to::String="", files::String="", max::Int=0)
  println("move, from=$from to=$to files=$files max=$max")
end

# Command copy
# -r --recursive
#    --depth
@arg1(:copy, "", "--recursive", Bool)
@arg1(:copy, "", "--depth", Int)
function copy(from::String="", to::String="", recursive::Bool=false, depth::Int=1)
  println("copy, from=$from to=$to recursive=$recursive depth=$depth")
end

# Command ls
function ls(dir::String="")
  println("ls, dir=$dir")
end
