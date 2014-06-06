using Base.Test

require("src/args.jl")
import args: @args, Arg, CommandArgs, StructUpdater, update!, parser, call

# ls --dir=/path/ls
@args(ls,
  Arg{String}(:dir, "--dir"; short="-d", default="")
)
ls(dir="/path/ls") = "ls dir=$dir"

# move --from=/path/from --to /path/to -r
@args(move,
  Arg{String}(:from, "--from"; default=""),
  Arg{String}(:to, "--to"; default=""),
  Arg{Bool}(:recursive, "--recursive"; short="-r", default=false)
)
function move(from::String, to::String, recursive::Bool=false)
  "move from=$from to=$to r=$recursive"
end

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

  # @test :move == o.sym
  @test "/path/from" == o.args.from
  @test "/path/to" == o.args.to
  @test !o.args.recursive
end

function parse_commands_ls()
  args = String["ls", "--dir=/path/a"]
  o = CommandArgs()
  args1 = update!(o, args)

  # @test :ls == o.sym
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
