-- UPVALUES -----------------------------

local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local GetAddOnMetadata = GetAddOnMetadata
local WOW_PROJECT_CLASSIC = WOW_PROJECT_CLASSIC
local WOW_PROJECT_ID = WOW_PROJECT_ID

-- CONSTANTS ----------------------------

local ADDON_NAME, namespace = ...
local ADDON_VERSION = GetAddOnMetadata(ADDON_NAME, 'Version')
local COMMAND = '/' .. ADDON_NAME
local LOG_PREFIX = ADDON_NAME .. ': %s'

-- MODULE -------------------------------

local UTILS = {}
namespace.UTILS = UTILS

local API = {}
namespace.API = API

-- UTILITIES ----------------------------

-- @name isClassic
-- @return classic boolean
-- @usage UTILS:isClassic()
function UTILS:isClassic()
  return WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
end

-- @name log
-- @param arg
-- @usage UTILS:log('Roses are red...')
function UTILS:log(...)
  local msg = ''
  for _, part in ipairs {...} do
    msg = msg .. tostring(part) .. ' '
  end
  DEFAULT_CHAT_FRAME:AddMessage(string.format(LOG_PREFIX, msg))
end

-- @name dump
-- @param var any
-- @return var string
-- @usage UTILS:dump(storage)
function UTILS:dump(var)
  if type(var) == 'table' then
    local s = '{ '
    for k, v in pairs(var) do
      if type(k) ~= 'number' then
        k = '"' .. k .. '"'
      end
      s = s .. '[' .. k .. '] = ' .. UTILS:dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(var)
  end
end

-- @name printHelp
-- @usage UTILS:printHelp()
function UTILS:printHelp()
  UTILS:log('v' .. ADDON_VERSION .. ', commands:')
  UTILS:log(COMMAND .. ' show - show addon frame')
  UTILS:log(COMMAND .. ' hide - hide addon frame')
  UTILS:log('Examples: "/wpvpa ?" or "/wpvpa help" - Print this list')
end

-- @name getWinRatePercent
-- @param played integer
-- @param won integer
-- @return winRatePercent integer
-- @usage UTILS:getWinRatePercent(187, 102) -- 54
function UTILS:getWinRatePercent(played, won)
  if (played == 0 or won == 0) then
    return 0
  end
  return math.floor(won / (played / 100))
end

-- @name registerEvents
-- @param frame Frame
-- @param events table
-- @usage UTILS:registerEvents(frame, events)
function UTILS:registerEvents(frame, events)
  for _, eventName in pairs(events) do
    frame:RegisterEvent(eventName)
  end
end

-- @name setEventListeners
-- @param frame Frame
-- @param events table
-- @usage UTILS:setEventListeners(frame, callback)
function UTILS:setEventListeners(frame, callback)
  frame:SetScript('OnEvent', callback)
end
