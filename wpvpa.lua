-- CONSTANTS ----------------------------

local ADDON_NAME, namespace = ...
local COMMAND = '/' .. ADDON_NAME
local DEBUG = true -- true || nil

-- IMPORTS ------------------------------

local L = namespace.L -- Languages Table
local UTILS = namespace.UTILS
local API = namespace.API

-- COMMANDS -----------------------------

SlashCmdList['WPVPA_SLASHCMD'] = function(msg)
  UTILS:log(msg)
  local command = string.lower(msg:match('^(%S*)%s*(.-)$'))
  if (command == 'show') then
    API:show()
  elseif (command == 'hide') then
    API:hide()
  elseif (command == 'help' or command == '?') then
    UTILS:printHelp()
  elseif (command == 'dump') then
    UTILS:log('storage:')
    UTILS:log(UTILS:dump(API:getStorage()))
  elseif (command == 'test') then
    API:test('test')
  end
end
SLASH_WPVPA_SLASHCMD1 = COMMAND

-- MAIN ---------------------------------

local function onLoad()
  API:init(DEBUG)
  UTILS:log('|cffc01300' .. L['loaded'])
  UTILS:printHelp()
end

onLoad()
