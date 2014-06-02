using Base.Test

immutable Arg
  name::String
  typ::Type
  short::String
  long::String
end

function Arg(name::String, typ::Type; short="", long="")
  Arg(name, typ, short, long)
end

immutable Cmd
  name::String
  args::Array{Arg,1}
end

immutable Parser
  commands::Array{Cmd,1}
end

immutable P
  sym::Symbol
  typ::Type
  value
end

immutable ParseResult
  func::Symbol
  parameters::Array{P,1}
end

==(a::P, b::P) = a.sym == b.sym && a.typ == b.typ && a.value == b.value

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
  parsed = ParseResult(
    :open,
    P[P(:from, String, "/path/from"), P(:to, String, "/path/to"), P(:recursive, Bool, true)]
  )
  (parsed, args)
end

function parse_commands()
  p = Parser(
    Cmd[
      Cmd("open", Arg[Arg("from", String; long="--from"), Arg("to", String; long="--to"), Arg("recursive", Bool; short="-r")]),
      Cmd("move", Arg[Arg("from", String; long="--from"), Arg("to", String; long="--to")]),
      Cmd("ls", Arg[Arg("dir", String; short="-d", long="--dir")])
    ]
  )

  parsed, args = parse(p, String["open", "--from=/path/from", "--to", "/path/to", "-r"])
  @assert :open == parsed.func
  @assert P(:from, String, "/path/from") == parsed.parameters[1]
  @assert P(:to, String, "/path/to") == parsed.parameters[2]
  @assert P(:recursive, Bool, true) == parsed.parameters[3]
end

# move --from=/path/from --to /path/to -r
# move(from="/path/from", to="/path/to")

# ls --dir=/path/ls
# ls(dir="/path/ls")

# conf{from="/path/from", to="/path/to"}
# move -c conf
# move(from="/path/from", to="/path/to")

parse_commands()
