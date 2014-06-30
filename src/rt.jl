#
# Runtime
#

parse_string(args::Array{String, 1}) = args[1]
parse_int(args::Array{String, 1}) = int(args[1])
parse_bool(args::Array{String, 1}) = true

valency(::Type, arg::String) = -1
validate(o) = String[]
update!(o, args::Array{String, 1}) = nothing

empty(x) = nothing
