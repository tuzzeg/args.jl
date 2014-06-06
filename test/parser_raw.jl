using Base.Test

require("src/args.jl")
import args: CommandArgs, StructUpdater, update!, parser, call

# ls --dir=/path/ls
ls(dir="/path/ls") = "ls dir=$dir"

# { generated: ls specific
type _ls_args
  dir::String
  _ls_args() = new("")
end

ls(o::_ls_args) = ls(o.dir)

function parser(p::_ls_args, arg::String)
  if arg == "--dir" || arg == "-d"
    StructUpdater{String}(:dir)
  else
    nothing
  end
end
# }

# conf{from="/path/from", to="/path/to"}
# move -c conf
# move(from="/path/from", to="/path/to")


# move --from=/path/from --to /path/to -r
function move(from::String, to::String, recursive::Bool=false)
  "move from=$from to=$to r=$recursive"
end

# { generated: Move specific
type _move_args
  from::String
  to::String
  recursive::Bool
  _move_args() = new("", "", false)
end

move(o::_move_args) = move(o.from, o.to, o.recursive)

function parser(p::_move_args, arg::String)
  if arg == "--from"
    StructUpdater{String}(:from)
  elseif arg == "--to"
    StructUpdater{String}(:to)
  elseif arg == "-r" || arg == "--recursive"
    StructUpdater{Bool}(:recursive)
  else
    nothing
  end
end
# }

# { generated: main

function update!(o::CommandArgs, args::Array{String,1})
  if length(args) < 1
    throw(ParseException("Expected command, args=$(args)"))
  end
  cmd, args = args[1], args[2:end]
  if cmd == "move"
    o.action = move
    o.args = _move_args()
    update!(o.args, args)
  elseif cmd == "ls"
    o.action = ls
    o.args = _ls_args()
    update!(o.args, args)
  else
    throw(ParseError("Unexpected command [$cmd]"))
  end
end


# }

function parse_args()
  args = String["--from", "/path/from", "--to", "/path/to", "-r"]
  o = _move_args()
  args1 = update!(o, args)

  @test "/path/from" == o.from
  @test "/path/to" == o.to
  @test o.recursive
end

function parse_args1()
  args = String["--from=/path/from", "--to", "/path/to", "-r"]
  o = _move_args()
  args1 = update!(o, args)

  @test "/path/from" == o.from
  @test "/path/to" == o.to
  @test o.recursive
end

function parse_commands_move()
  args = String["move", "--from=/path/from", "--to", "/path/to"]
  o = CommandArgs()
  args1 = update!(o, args)

  @test "/path/from" == o.args.from
  @test "/path/to" == o.args.to
  @test !o.args.recursive
end

function parse_commands_ls()
  args = String["ls", "--dir=/path/a"]
  o = CommandArgs()
  args1 = update!(o, args)

  @test "/path/a" == o.args.dir
end

function call_command_ls()
  args = String["ls", "--dir=/path/a"]
  o = CommandArgs()
  args1 = update!(o, args)

  @assert "ls dir=/path/a" == call(o)
end

function call_command_move()
  args = String["move", "--from=/path/from", "--to", "/path/to"]
  o = CommandArgs()
  args1 = update!(o, args)

  @assert "move from=/path/from to=/path/to r=false" == call(o)
end

parse_args()
parse_args1()

parse_commands_move()
parse_commands_ls()

call_command_ls()
call_command_move()
