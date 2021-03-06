module commands1

using Base.Test

require("src/args.jl")
using args

@command(mv,
  (from::String, long="--from"),
  (to::String, long="--to"),
  (file::String="file.csv", short="-f", long="--file"),
  (recursive::Bool, short="-r"),
begin
  "mv from=$from to=$to file=$file recursive=$recursive"
end)

@command(mv1,
  (from::String, long="--from"),
  (recursive::Bool, short="-r"),
begin
  "mv from=$from recursive=$recursive"
end)

end # module
