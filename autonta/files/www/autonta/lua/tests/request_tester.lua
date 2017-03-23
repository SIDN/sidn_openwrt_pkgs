#!/usr/bin/lua

local mio = require 'mio'
--require 'argparse'
local an = require 'autonta'
local au = require 'autonta_util'

function read_request_data(file_name)
  local fr = mio.file_reader(file_name)
  local req = {}
  local cur_subtable = nil
  for line in fr:read_line_iterator(true) do
    local name, value = line:match("^(%S+):%s*(.*)")
    if name then
      if value == "<table>" then
        cur_subtable = name
        req[cur_subtable] = {}
      else
        cur_subtable = nil
        req[name] = value
      end
    else
      if cur_subtable ~= nil then
        table.insert(req[cur_subtable], line)
      end
    end
  end
  return req
end

local env = read_request_data("tests/test_request1.txt")
--print(au.obj2str(env))

local autonta = an.create("tests/valibox_config_file.txt", "tests/langkeys.txt")

local headers, html = autonta:handle_request(env)
print("[    RESPONSE HEADERS   ]")
print(au.obj2str(headers))
print("[     END OF HEADERS    ]")
print("[    RESPONSE CONTENT   ]")
print(au.obj2str(html))
print("[     END OF CONTENT    ]")
