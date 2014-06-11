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

## Reusable arg objects

@struct(Range,
  (from::Int, long="--from"),
  (to::Int, long="--to"))

@command(cmd,
  (range::Range), # consume (--from=0 --to=100)
  ...

## Parse config
@command(cmd,
  (config::File{Proto, Config}, short="-c")
begin
  db = open(config.db)
end)

Read file specified in -c=config.pb and parse as protobuf, inject as :config

### Override config values in command line

in cmd.jl
@command(cmd,
  (config::File{Proto, Config}, short="-c")
begin
  println("from=$(config.from) to=$(config.to)")
  println("inner.obj.value=$(config.inner.obj.value)")
end)

in config.pb
range: {
  from: 0
  to: 100
  inner: {
    obj: {
      value: "v1"
    }
  }
}

$ julia cmd.jl -c config.pb
from=0 to=100
inner.obj.value=v1

$ julia cmd.jl -c config.pb --from=10 --inner.obj.value=v2
from=10 to=100
inner.obj.value=v2
