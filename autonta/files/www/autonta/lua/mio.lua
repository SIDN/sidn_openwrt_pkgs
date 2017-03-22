#!/usr/bin/lua

local posix = require 'posix'
local bit = require 'bit'

local mio = {}

--
-- This modules contains wrappers around the posix library
-- for easier reading of files and running of subprocesses
--
-- The io library has some issues on openwrt with lua 5.1
--

--
-- baseline utility functions
--

-- split a command into an executable and a table of arguments
-- assumes no spaces are used in the arguments (no quoting supported)
-- for safety, also do not compound arguments (write -ade as -a -d -e)
function mio.split_cmd(command)
  local cmd = nil
  local args = {}
  for el in string.gmatch(command, "%S+") do
    if cmd == nil then cmd = el else table.insert(args, el) end
  end
  return cmd, args
end

-- read a line from the given file descriptor
function mio.read_fd_line(fd, strip_newline, timeout)
  if fd == nil then
    return nil, "Read on closed file"
  end
  if timeout == nil then timeout = 500 end
  local pr, err = posix.rpoll(fd, timeout)
  if pr == nil then return nil, err end
  if pr == 0 then
    return nil, "read timed out"
  end
  local result = ""
  while true do
    local c = posix.read(fd, 1)
    if c == posix.EOF or c == '' then
      if result == "" then
        return nil
      else
        if strip_newline then return result else return result .. "\n" end
      end
    elseif c == "\n" then
      if strip_newline then return result else return result .. "\n" end
    else
      result = result .. c
    end
  end
end

function mio.write_fd_line(fd, line, add_newline)
  if fd == nil then
    return nil, "Write on closed file"
  end
  if add_newline then line = line .. "\n" end
  return posix.write(fd, line)
end

--
-- Simple popen3() implementation
--
function mio.popen3(path, args, delay)
    if args == nil then args = {} end
    local r1, w1 = posix.pipe()
    local r2, w2 = posix.pipe()
    local r3, w3 = posix.pipe()

    assert((w1 ~= nil or r2 ~= nil or r3 ~= nil), "pipe() failed")

    local pid, err = posix.fork()
    assert(pid ~= nil, "fork() failed")
    if pid == 0 then
        if delay then posix.sleep(delay) end
        posix.close(w1)
        posix.close(r2)
        posix.dup2(r1, posix.fileno(io.stdin))
        posix.dup2(w2, posix.fileno(io.stdout))
        posix.dup2(w3, posix.fileno(io.stderr))
        posix.close(r1)
        posix.close(w2)
        posix.close(w3)

        local ret, err = posix.execp(path, args)
        sys.stderr.write("execp() failed: " .. err)
        assert(ret ~= nil, "execp() failed")

        posix._exit(1)
        return
    end

    posix.close(r1)
    posix.close(w2)
    posix.close(w3)

    return pid, w1, r2, r3
end

function strjoin(delimiter, list)
   local len = 0
   if list then len = table.getn(list) end
   if len == 0 then
      return ""
   elseif len == 1 then
      return list[1]
   else
     local string = list[1]
     for i = 2, len do
        string = string .. delimiter .. list[i]
     end
     return string
   end
end


function mio.subprocess(path, args, delay)
  io.stderr:write("[XX] MIO cmd: " .. path .. " " .. strjoin(" ", args) .. "\n")
  if delay then io.stderr:write("[XX] with delay " .. delay .. "\n") end

  local subp = {}
  subp.pid, subp.stdin, subp.stdout, subp.stderr = mio.popen3(path, args, delay)
  io.stderr:write("[XX] subp got PID " .. subp.pid .. "\n")

  subp.readline = function(self, strip_newline, timeout)
    io.stderr:write("[XX] READ LINE FROM PROCESS " .. self.pid)
    if timeout ~= nil then
      io.stderr:write(" WITH TIMEOUT " .. timeout)
    end
    io.stderr:write("\n")
    local result = mio.read_fd_line(self.stdout, strip_newline, timeout)
    if result ~= nil then
      io.stderr:write("[XX] LINE: '" .. result .. "'\n")
    else
      io.stderr:write("[XX] LINE empty\n")
    end
    return result
  end

  subp.readlines = function(self, strip_newlines, timeout)
    local function next_line()
      return self:readline(strip_newlines, timeout)
    end
    return next_line
  end

  subp.readline_stderr = function(self, strip_newline)
    return mio.read_fd_line(self.stderr, strip_newline)
  end

  subp.writeline = function(self, line, add_newline)
    return mio.write_fd_line(self.stdin, line, add_newline)
  end

  subp.close = function(self)
    posix.close(self.stdin)
    posix.close(self.stdout)
    posix.close(self.stderr)
    local spid, state, rcode = posix.wait(self.pid)
    if spid == self.pid then
      self.rcode = rcode
      self.pid = nil
      self.stdin = nil
      self.stdout = nil
      self.stderr = nil
    end
    return rcode
  end

  return subp
end

-- text file reading
function mio.file_reader(filename)
  local f = {}
  f.fd, err = posix.open(filename, posix.O_RDONLY)
  if f.fd == nil then return nil, err end

  -- read one line from the file
  f.readline = function(self, strip_newline)
    local result = mio.read_fd_line(f.fd, strip_newline)
    if result == nil then f:close() end
    return result
  end

  -- return the lines of the file as an iterator
  f.readlines = function(self, strip_newlines)
    local function next_line()
      return f.readline(strip_newlines)
    end
    return next_line
  end

  f.close = function(self)
    if f.fd then
      posix.close(f.fd)
      f.fd = nil
    end
  end

  return f
end

function mio.file_writer(filename)
  local f = {}
  f.fd, err = posix.open(filename, bit.bor(posix.O_CREAT, posix.O_WRONLY), 600)
  if f.fd == nil then return nil, "wut: " .. err end

  f.writeline = function(self, line, add_newline)
    return mio.write_fd_line(f.fd, line, add_newline)
  end

  f.writelines = function(self, iterator)
    if f.fd == nil then
      return nil, "Write on closed file"
    end
    for line in iterator() do
      posix.write(f.fd, line)
    end
    return true
  end

  f.close = function()
    if f.fd then
      posix.close(f.fd)
      f.fd = nil
    end
  end

  return f
end

return mio
