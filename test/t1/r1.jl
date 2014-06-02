require("src/args.jl")

# Common arguments for all commands
# Can be omitted in commands
# -f --from
# -t --to
# -d --dir

# Command move
#    --files
#    --max
function move(from::String="", to::String="", files::String="", max::Int=0)
  println("move, from=$from to=$to files=$files max=$max")
end

# Command copy
# -r --recursive
#    --depth
function copy(from::String="", to::String="", recursive::Bool=false, depth::Int=1)
  println("copy, from=$from to=$to recursive=$recursive depth=$depth")
end

# Command ls
function ls(dir::String="")
  println("ls, dir=$dir")
end

function main(args::Array{String,1})
  if length(args) <= 0
    usage()
    return
  end
  cmd = args[1]

  println("cmd=$cmd")
end

function usage()
  println("Usage:")
  println("copy")
  println("  --from")
  println("  --to")
  println("  --recursive")
  println("  --depth")
  println()
  println("move")
  println("  --from")
  println("  --to")
  println("  --files")
  println("  --max")
  println()
  println("ls")
  println("  --dir")
end

main(convert(Array{String,1}, ARGS))
