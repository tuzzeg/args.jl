module commands2

using Base.Test

require("src/args.jl")
using args

@command(ls,
  (dir::String="file.csv", short="-f", long="--file"),
  (recursive::Bool, short="-r"),
begin
  "ls dir=$dir recursive=$recursive"
end)

@command(ls1,
  (file::String, long="--from"),
begin
  "ls1 file=$file"
end)

end # module
