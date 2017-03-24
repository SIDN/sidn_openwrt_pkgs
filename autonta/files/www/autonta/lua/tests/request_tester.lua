#!/usr/bin/lua

local mio = require 'mio'
--require 'argparse'
local an = require 'autonta'
local au = require 'autonta_util'

-- Reads a request data file (test case)
-- see test_request1.txt for the format
-- returns:
-- env: the variable containing the request data that is passed
--      to handle_request in autonta.lua
-- response_headers: a list of expected headers
-- response_content: a list of lines with the expected content
local function read_request_data(file_name)
  local fr = mio.file_reader(file_name)
  local env = {}
  -- for more advanced tests we may need to change these to
  -- lists of lines later
  local response_headers = {}
  local response_content = {}
  local cur_subtable = nil

  -- mode is either (request, response_headers, response_content)
  local mode = "request"

  for line in fr:read_line_iterator(true) do
    if line == "[EXPECTED HEADERS]" then
      mode = "response_headers"
    elseif line == "[EXPECTED CONTENT]" then
      mode = "response_content"
    else
      if mode == "request" then
        local name, value = line:match("^(%S+):%s*(.*)")
        if name then
          if value == "<table>" then
            cur_subtable = name
            env[cur_subtable] = {}
          else
            cur_subtable = nil
            env[name] = value
          end
        else
          if cur_subtable ~= nil then
            table.insert(env[cur_subtable], line)
          end
        end
      elseif mode == "response_headers" then
        table.insert(response_headers, line)
      elseif mode == "response_content" then
        table.insert(response_content, line)
      else
        assert(false, "Unknown test case read mode: " .. mode)
      end
    end
  end
  return env, response_headers, response_content
end

local autonta = an.create("tests/valibox_config_file.txt", "tests/langkeys.txt")

local function multiline_to_list(str)
  local list = {}
  local index = 0

  local function magiclines(s)
        if s:sub(-1)~="\n" then s=s.."\n" end
        return s:gmatch("(.-)\n")
  end

  for l in magiclines(str) do
    table.insert(list, l)
  end
  return list
end

local function headers_to_list(headers)
  local result = {}
  for n,v in pairs(headers) do
    table.insert(result, n .. ": " .. v)
  end
  return result
end

local function compare_strings(str1,str2)
    local minimum = #str1
    if minimum > #str2 then minimum = #str2 end
    for i = 1,minimum do --Loop over strings
        if str1:sub(i,i) ~= str2:sub(i,i) then --If that character is not equal to it's counterpart
            return false, i --Return that index
        end
    end
    if minimum < #str1 or minimum < #str2 then
      return false, minimum
    else
      return true
    end
end

local function compare_lists(a, e)
  local a_len = table.getn(a)
  local e_len = table.getn(e)
  if a_len > e_len then
    print("Size of actual (" .. a_len .. ") larger than size of expected (" .. e_len .. ")")
    return false
  end
  for i=1,#a do
    local result, index = compare_strings(a[i], e[i])
    if not result then
      print("Difference at element " .. i .. " position " .. index .. " showing expected, actual:")
      print(e[i])
      print(a[i])
      for j=1,index-1 do io.stdout:write(" ") end
      print("^")
      return false
    end
  end
  return true
end

local function test_request(testcase_file)
  --print("[Test case: " .. testcase_file .. "]")
  local env, expected_headers, expected_content = read_request_data(testcase_file)
  --print(au.obj2str(env))
  local headers, content = autonta:handle_request(env)
  local headers_list = headers_to_list(headers)
  local content_list = multiline_to_list(content)
  --local content_list = multiline_to_list(content)
  if not compare_lists(headers_list, expected_headers) then
    print("[Test case: " .. testcase_file .. " FAILED]")
    return false
  end
  --print("[XX] EXPECT: " .. au.obj2str(expected_content))
  --print("[XX] GOT: " .. au.obj2str(content_list))
  if not compare_lists(content_list, expected_content) then
    print("[Test case: " .. testcase_file .. " FAILED]")
    return false
  end
  print("[Test case: " .. testcase_file .. " SUCCESS]")
  return true
end


--
-- overwrite some functions as they depend on the environment of the device
--
function autonta.is_first_run() return false end

io.flush()
test_request("tests/test_request_index.txt")

function autonta.get_nta_list() return {} end
test_request("tests/test_request_nta_list_empty.txt")

function autonta.get_nta_list()
  return { "servfail.nl.", "sigexpired.ok.bad-dnssec.wb.sidnlabs.nl." }
end
test_request("tests/test_request_nta_list_nonempty.txt")


