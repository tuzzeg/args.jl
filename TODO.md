# Features
- Support commands
julia storage.jl *get* --db db.kch -k 1
julia storage.jl *keys* --db db.kch

- Required/optional args, default values
@command(get,
  (db::String, short="-d", long="--db") # required
  (k::Int=0, short="-k") # optional

- Short/long option name, with default long
@command(get,
  (db::String) # required, long="--db"
