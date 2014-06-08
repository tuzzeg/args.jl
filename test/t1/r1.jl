require("src/args.jl")

# Common arguments for all commands
# Can be omitted in commands
# -f --from
# -t --to
# -d --dir

# Command move
#    --files
#    --max
@command(move,
  (from::String, long="--from"),
  (to::String, long="--to"),
  (files::String="", long="--files"),
  (max::Int=0, long="--max"),
begin
  println("move, from=$from to=$to files=$files max=$max")
end)

# Command copy
# -r --recursive
#    --depth
@command(copy,
  (from::String, long="--from"),
  (to::String, long="--to"),
  (recursive::Bool=false, long="--files", short="-r"),
  (depth::Int=1, long="--depth"),
begin
  println("copy, from=$from to=$to recursive=$recursive depth=$depth")
end)

# Command ls
@command(ls,
  (dir::String, short="-r", long="--dir"),
begin
  println("ls, dir=$dir")
end)

function main(args::Array{String,1})
  if length(args) <= 0
    usage()
    return
  end
  cmd = args[1]

  println("cmd=$cmd")
end

main(convert(Array{String,1}, ARGS))
