-- UPVALUES -----------------------------

local GetBuildInfo = GetBuildInfo
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local GetAddOnMetadata = GetAddOnMetadata

-- CONSTANTS ----------------------------

local ADDON_NAME, namespace = ...
local ADDON_VERSION = GetAddOnMetadata(ADDON_NAME, 'Version')
local COMMAND = '/' .. ADDON_NAME
local LOG_PREFIX = ADDON_NAME .. ': %s'

-- MODULE -------------------------------

local UTILS = {}
namespace.UTILS = UTILS

-- UTILITIES ----------------------------

-- @name checkIfClassic
-- @return classic boolean
-- @usage UTILS.checkIfClassic()
function UTILS:checkIfClassic()
  local result = false
  -- MACRO
  -- /script v, b, d, t = GetBuildInfo()
  -- /script print(string.format("version = %s, build = %s, date = '%s', tocversion = %s.", v, b, d, t))
  -- https://wowwiki.fandom.com/wiki/API_GetBuildInfo
  local version, build, date, tocversion = GetBuildInfo()
  -- v = 1.13.2, b = 32089, d = 'Oct 4 2019', t = 11302

  if (version == '1.13.2') then
    result = true
  end

  -- TODO: check it
  -- if (tocversion >= 11300 and tocversion < 12000) then
  --   result = true
  -- end

  return result
end

-- @name log
-- @param arg
-- @usage UTILS.log('Roses are red...')
function UTILS:log(...)
  local msg = ''
  for _, part in ipairs {...} do
    msg = msg .. tostring(part) .. ' '
  end
  DEFAULT_CHAT_FRAME:AddMessage(string.format(LOG_PREFIX, msg))
end

-- @name dump
-- @param var any
-- @usage UTILS.dump(storage)
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
-- @usage UTILS.printHelp()
function UTILS:printHelp()
  UTILS:log('v' .. ADDON_VERSION .. ', commands:')
  UTILS:log(COMMAND .. ' show - show addon frame')
  UTILS:log(COMMAND .. ' hide - hide addon frame')
  UTILS:log('Examples: "/wpvpa ?" or "/wpvpa help" - Print this list')
end

-- @name getWinRatePercent
-- @param played integer
-- @param won integer
-- @return winrate integer
-- @usage UTILS.getWinRatePercent(187, 102) -- 54
function UTILS:getWinRatePercent(played, won)
  if played == 0 or won == 0 then
    return 0
  end
  return math.floor(won / (played / 100))
end
