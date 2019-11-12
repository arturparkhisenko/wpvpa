-- CONSTANTS ----------------------------

local ADDON_NAME, namespace = ...
local COMMAND = '/' .. ADDON_NAME
local DEBUG = true -- true || nil

-- IMPORTS ------------------------------

local L = namespace.L -- Languages Table
local UTILS = namespace.UTILS
local API = namespace.API

-- VARIABLES ----------------------------

local classic = nil
local storage = nil
local uiFrame = nil

-- COMMANDS -----------------------------

SlashCmdList['WPVPA_SLASHCMD'] = function(msg)
  UTILS:log(msg)
  local command = string.lower(msg:match('^(%S*)%s*(.-)$'))
  if (command == 'show') then
    uiFrame:Show()
  elseif (command == 'hide') then
    uiFrame:Hide()
  elseif (command == 'help' or command == '?') then
    UTILS:printHelp()
  elseif (command == 'dump') then
    UTILS:log('storage:')
    UTILS:log(UTILS:dump(storage))
  end
end
SLASH_WPVPA_SLASHCMD1 = COMMAND

-- MAIN ---------------------------------

local function onLoad()
  classic = UTILS:isClassic()
  UTILS:loadAPI(classic)
  API:init(storage, uiFrame, DEBUG)
  UTILS:log('|cffc01300' .. L['loaded'])
  UTILS:printHelp()
end

onLoad()
