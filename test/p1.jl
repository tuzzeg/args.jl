using Base.Test

type CommandArgs
  sym::Symbol
  args
  CommandArgs() = new()
end

abstract Updater{T}

immutable StructUpdater{T} <: Updater{T}
  sym::Symbol
end

function update!(o::CommandArgs, args::Array{String,1})
  if length(args) < 1
    throw(ParseException("Expected command, args=$(args)"))
  end
  cmd, args = args[1], args[2:end]
  if cmd == "move"
    o.sym = :move
    o.args = MoveArgs()
    update!(o.args, args)
  elseif cmd == "ls"
    o.sym = :ls
    o.args = LsArgs()
    update!(o.args, args)
  else
    throw(ParseError("Unexpected command [$cmd]"))
  end
end

function update!{R}(o::R, args::Array{String,1})
  unparsed = Array{String,1}
  i_arg = 1
  consumed = 0
  while i_arg <= length(args)
    arg = args[i_arg]
    if beginswith(arg, "-")
      args_split = split(arg, "=", 2)
      if length(args_split) == 1
        p_arg = parser(o, arg)
        if !isa(p_arg, Nothing)
          v = valency(p_arg)
          consumed = 1+v
          update_args = args[i_arg:i_arg+v]
        end
      else
        p_arg = parser(o, args_split[1])
        if !isa(p_arg, Nothing)
          v = valency(p_arg)
          if v != 1
            throw(ParserError("--option=value should be used only with valency=1, p=[$p_arg]"))
          end
          consumed = 1
          update_args = args_split
        end
      end
      update!(o, p_arg, convert(Array{String,1}, update_args))
    end
    if 0 < consumed
      i_arg += consumed
    else
      push!(unparsed, args[i_arg])
      i_arg += 1
    end
  end
  return unparsed
end

valency(::StructUpdater{String}) = 1
valency(::StructUpdater{Int}) = 1
valency(::StructUpdater{Bool}) = 0

function update!{R}(o::R, p::StructUpdater{String}, args::Array{String,1})
  @assert 2 == length(args)
  setfield!(o, p.sym, args[2])
end

function update!{R}(o::R, p::StructUpdater{Int}, args::Array{String,1})
  @assert 2 == length(args)
  setfield!(o, p.sym, int(args[2]))
end

function update!{R}(o::R, p::StructUpdater{Bool}, args::Array{String,1})
  @assert 1 == length(args)
  setfield!(o, p.sym, true)
end

# ls --dir=/path/ls
ls(dir="/path/ls") = "ls dir=$dir"

# { generated: ls specific
type LsArgs
  dir::String
  LsArgs() = new("")
end

ls(o::LsArgs) = ls(o.dir)

function parser(p::LsArgs, arg::String)
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
type MoveArgs
  from::String
  to::String
  recursive::Bool
  MoveArgs() = new("", "", false)
end

move(o::MoveArgs) = move(o.from, o.to, o.recursive)

function parser(p::MoveArgs, arg::String)
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

function parse_args()
  args = String["--from", "/path/from", "--to", "/path/to", "-r"]
  o = MoveArgs()
  args1 = update!(o, args)

  @test "/path/from" == o.from
  @test "/path/to" == o.to
  @test o.recursive
end

function parse_args1()
  args = String["--from=/path/from", "--to", "/path/to", "-r"]
  o = MoveArgs()
  args1 = update!(o, args)

  @test "/path/from" == o.from
  @test "/path/to" == o.to
  @test o.recursive
end

function parse_commands_move()
  args = String["move", "--from=/path/from", "--to", "/path/to"]
  o = CommandArgs()
  args1 = update!(o, args)

  @test :move == o.sym
  @test "/path/from" == o.args.from
  @test "/path/to" == o.args.to
  @test !o.args.recursive
end

function parse_commands_ls()
  args = String["ls", "--dir=/path/a"]
  o = CommandArgs()
  args1 = update!(o, args)

  @test :ls == o.sym
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

function call(o::CommandArgs)
  @eval $(o.sym)($(o.args))
end

parse_args()
parse_args1()

parse_commands_move()
parse_commands_ls()

call_command_ls()
call_command_move()
