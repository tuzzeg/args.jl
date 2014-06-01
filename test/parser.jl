using Base.Test

immutable Arg
  name::String
  typ::Type
  short::String
  long::String
  path::String
end

function Arg(name::String, typ::Type; short="", long="", path="")
  Arg(name, typ, short, long, path)
end

immutable Cmd
  name::String
  args::Array{Arg,1}
end

immutable Parser
  commands::Array{Cmd,1}
end

function parse{T<:String}(p::Parser, args::Array{T,1})
  if length(args) <= 0
    throw(BoundsError("Expected command as 1st arguemnt"))
  end
  cmd, args = args[1], args[2:end]
  for pcmd in p.commands
    if issupported(pcmd, cmd)
      parsed, args = parse(pcmd, args)
      return parsed, args
    end
  end
  throw(ParseError("Unknown command [$cmd]"))
end

issupported(p::Cmd, cmd::String) = p.name == cmd

function parse{T<:String}(p::Cmd, args::Array{T,1})
  (p, args)
end

function parse_commands()
  p = Parser(
    Cmd[
      Cmd("open", Arg[Arg("from", String; long="--from"), Arg("to", String; long="--from")]),
      Cmd("move", Arg[Arg("from", String; long="--from", path="dirs.from"), Arg("to", String; long="--to", path="dirs.to")]),
      Cmd("ls", Arg[Arg("dir", String; short="-d", long="--dir")])
    ]
  )
  parsed, args = parse(p, String["open"])

  println("parsed=$parsed args=$args")
end

# move --from=/path/from --to /path/to -r
# move(from="/path/from", to="/path/to")

# ls --dir=/path/ls
# ls(dir="/path/ls")

# conf{from="/path/from", to="/path/to"}
# move -c conf
# move(from="/path/from", to="/path/to")

parse_commands()
