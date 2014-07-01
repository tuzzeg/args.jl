#
# Runtime
#

parse_string(args::Array{String, 1}) = args[1]
parse_int(args::Array{String, 1}) = int(args[1])
parse_bool(args::Array{String, 1}) = true

valency(::Type{String}, arg::String) = 1
valency(::Type{Int}, arg::String) = 1
valency(::Type{Bool}, arg::String) = 0

function valency(u::Type{UnionType}, arg::String)
  println("val::UnionType")
  dump(u)
  if length(u.types) == 2 && is(u.types[2], Nothing)
    valency(u.types[1], arg)
  else
    -1
  end
end

validate(o) = String[]
update!(o, args::Array{String, 1}) = nothing

empty(x) = nothing
