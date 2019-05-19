-- UPVALUES -----------------------------
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local CreateFrame = CreateFrame
local GetAchievementComparisonInfo = GetAchievementComparisonInfo
local GetAddOnMetadata = GetAddOnMetadata
local GetPersonalRatedInfo = GetPersonalRatedInfo
local GetPVPLifetimeStats = GetPVPLifetimeStats
local GetRealmName = GetRealmName
local GetUnitName = GetUnitName
local UnitClass = UnitClass
local UnitHonor = UnitHonor
local UnitHonorLevel = UnitHonorLevel
local UnitHonorMax = UnitHonorMax
local HONOR_POINTS = HONOR_POINTS
local LFG_LIST_HONOR_LEVEL_INSTR_SHORT = LFG_LIST_HONOR_LEVEL_INSTR_SHORT
local ARENA_2V2 = ARENA_2V2
local ARENA_3V3 = ARENA_3V3

-- CONSTANTS ----------------------------

-- local iconHeal = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:15:15:0:0:64:64:20:39:1:20|t"
-- local iconDmg = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:15:15:0:0:64:64:20:39:22:41|t"
-- local iconHonor = "Interface\\PVPFrame\\PVP-Currency-"..UnitFactionGroup('player')
-- local iconConquest = "Interface\\PVPFrame\\PVPCurrency-Conquest-"..UnitFactionGroup('player')

local ADDON_NAME = 'wpvpa'
local ADDON_VERSION = GetAddOnMetadata('wpvpa', 'Version')
local COMMAND = '/' .. ADDON_NAME
local DEBUG = nil
local LOG_PREFIX = ADDON_NAME .. ': %s'

local ACHIEVEMENTS = {[2090] = 'Challenger', [2093] = 'Rival', [2092] = 'Duelist', [2091] = 'Gladiator'}
local BRACKETS = {[1] = 'ARENA_2V2', [2] = 'ARENA_3V3', [4] = 'BATTLEGROUND_10V10'}
-- Events sorted by how often they are triggered
local EVENTS = {
  'HONOR_XP_UPDATE',
  'PVP_RATED_STATS_UPDATE',
  'HONOR_LEVEL_UPDATE',
  'UPDATE_BATTLEFIELD_SCORE',
  'ACHIEVEMENT_EARNED',
  'ZONE_CHANGED_NEW_AREA',
  'PLAYER_ENTERING_WORLD',
  'PLAYER_LOGIN',
  'PLAYER_LOGOUT', -- Fired when about to log out
  'ADDON_LOADED' -- Fired when saved variables are loaded
}

-- VARIABLES ----------------------------

local uiFrame = nil
local storage = nil

-- UTILITIES ----------------------------

-- @name log
-- @param arg
-- @usage log('Roses are red...')
local function log(...)
  local msg = ''
  for _, part in ipairs {...} do
    msg = msg .. tostring(part) .. ' '
  end
  DEFAULT_CHAT_FRAME:AddMessage(string.format(LOG_PREFIX, msg))
end

-- @name dump
-- @param var any
-- @usage dump(storage)
local function dump(var)
  if type(var) == 'table' then
    local s = '{ '
    for k, v in pairs(var) do
      if type(k) ~= 'number' then
        k = '"' .. k .. '"'
      end
      s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(var)
  end
end

-- STORAGE ------------------------------
-- -- Per-character settings for each individual AddOn.
-- -- WTF\Account\ACCOUNTNAME\RealmName\CharacterName\SavedVariables\AddOnName.lua

local function getStorage(loadedStorage)
  local initialStorage = loadedStorage
  if initialStorage == nil then
    if DEBUG then
      log('new config will be saved.')
    end
    local className, classFile = UnitClass('player')
    initialStorage = {
      player = {
        name = GetUnitName('player', false) or 'Unknown',
        realm = GetRealmName() or 'Unknown',
        class = classFile,
        achievements = {},
        honor = UnitHonor('player') or 0,
        honorMax = UnitHonorMax('player') or 1,
        honorLevel = UnitHonorLevel('player') or 1,
        kills = GetPVPLifetimeStats() or 0,
        ratings = {[BRACKETS[1]] = 0, [BRACKETS[2]] = 0, [BRACKETS[4]] = 0}
      }
    }
  end
  return initialStorage
end

-- HELP ---------------------------------

local function printHelp()
  log('v' .. ADDON_VERSION .. ', commands:')
  log(COMMAND .. ' show - show addon frame')
  log(COMMAND .. ' hide - hide addon frame')
  log('Examples: "/wpvpa ?" or "/wpvpa help" - Print this list')
end

-- STORE ACTIONS ------------------------

local function updateHonor()
  storage['player']['honor'] = UnitHonor('player') or 0
  storage['player']['honorMax'] = UnitHonorMax('player') or 1
  storage['player']['honorLevel'] = UnitHonorLevel('player') or 1
end

local function updateKills()
  local honorableKills = GetPVPLifetimeStats()
  storage['player']['kills'] = honorableKills or 0
end

local function updateRatings()
  for bracketIndex, bracket in pairs(BRACKETS) do
    -- https://www.townlong-yak.com/framexml/ptr/Blizzard_PVPUI/Blizzard_PVPUI.lua
    local rating = GetPersonalRatedInfo(bracketIndex)
    -- local rating,
    --   seasonBest,
    --   weeklyBest,
    --   seasonPlayed,
    --   seasonWon,
    --   weeklyPlayed,
    --   weeklyWon,
    --   lastWeeksBest,
    --   hasWon,
    --   pvpTier,
    --   ranking = GetPersonalRatedInfo(bracketIndex)
    storage['player']['ratings'][bracket] = rating or 0
  end
end

local function updateAchievements()
  for id, name in pairs(ACHIEVEMENTS) do
    local completed = GetAchievementComparisonInfo(id)
    if DEBUG then
      log('id: ', id, 'name: ', name, 'completed: ', completed or 'false')
    end
    if completed then
      storage['player']['achievements'][name] = true
    end
  end
end

-- FUNCTIONS ----------------------------

local function render(frame)
  frame.killsAmount:SetText(storage['player']['kills'])
  frame.honorAmount:SetText(storage['player']['honor'])
  frame.honorAmountMax:SetText(storage['player']['honorMax'])
  frame.honorLevel:SetText(storage['player']['honorLevel'])
  frame.ratingsArena2v2Amount:SetText(storage['player']['ratings'][BRACKETS[1]])
  frame.ratingsArena3v3Amount:SetText(storage['player']['ratings'][BRACKETS[2]])
  frame.ratingsRBGAmount:SetText(storage['player']['ratings'][BRACKETS[4]])
end

local function updatePVPStats(eventName)
  if DEBUG then
    log('updatePVPStats triggered by: ', eventName)
  end
  updateHonor()
  updateKills()
  updateRatings()
end

-- EVENTS -------------------------------

local function onEvent(self, event, unit, ...)
  if DEBUG then
    log('onEvent:', event, 'unit:', unit)
  end

  if
    event == 'HONOR_XP_UPDATE' or event == 'PVP_RATED_STATS_UPDATE' or event == 'HONOR_LEVEL_UPDATE' or
      event == 'UPDATE_BATTLEFIELD_SCORE' or
      event == 'ZONE_CHANGED_NEW_AREA' or
      event == 'PLAYER_ENTERING_WORLD'
   then
    updatePVPStats(event)
    render(uiFrame)
  elseif event == 'ACHIEVEMENT_EARNED' then
    updateAchievements()
    render(uiFrame)
  -- elseif event == 'PLAYER_LOGIN' then
  end

  -- Our saved variables are ready at this point. If there are none, both variables will set to nil.
  -- This is the first time this addon is loaded.
  -- arg1 is a file name
  if event == 'ADDON_LOADED' and unit == ADDON_NAME then
    storage = getStorage(wpvpa_character_config)
    -- check if saved data is from the current player character
    local currentPlayerName = GetUnitName('player', false) or 'Unknown'
    if currentPlayerName ~= storage['player']['name'] then
      storage = getStorage(nil)
    end
    -- onInit update achievements once
    updateAchievements()
    render(uiFrame)
  end
  if event == 'PLAYER_LOGOUT' then
    -- Save it
    wpvpa_character_config = storage
  end
end

local function registerEvents(frame)
  for _, eventName in pairs(EVENTS) do
    frame:RegisterEvent(eventName)
  end
end

local function setEventListeners(frame)
  frame:SetScript('OnEvent', onEvent)
end

-- UI and FRAME -------------------------

-- ofsx (negative values will move obj left, positive values will move obj right), defaults to 0 if not specified.
-- ofsy (negative values will move obj down, positive values will move obj up), defaults to 0 if not specified.
local function initContent(frame)
  -- Addon Title
  frame.Title = frame:CreateFontString(ADDON_NAME .. 'Title', 'OVERLAY', 'GameFontNormal')
  frame.Title:SetPoint('TOP', -10, -5)
  frame.Title:SetText(ADDON_NAME .. ' Stats')

  -- Kills
  -- -- Kills Amount Title
  frame.killsAmountTitle = frame:CreateFontString('killsAmountTitle', 'OVERLAY', 'GameTooltipText')
  -- frame.killsAmountTitle:SetFont('Fonts\\FRIZQT__.TTF', 20)
  frame.killsAmountTitle:SetPoint('TOPLEFT', 12, -30)
  frame.killsAmountTitle:SetText('Kills') -- HONORABLE_KILLS = "Honorable Kills";
  -- -- Kills Amount
  frame.killsAmount = frame:CreateFontString('killsAmount', 'OVERLAY', 'GameFontNormal')
  -- frame.killsAmount:SetTextColor(0, 0, 0, 1) -- SetTextColor(r, g, b[, a]) - Sets the default text color.
  frame.killsAmount:SetPoint('TOPLEFT', 50, -30)

  -- Honor

  -- -- Honor Amount Title
  frame.honorAmountTitle = frame:CreateFontString('honorAmountTitle', 'OVERLAY', 'GameTooltipText')
  frame.honorAmountTitle:SetPoint('TOPLEFT', 12, -50)
  frame.honorAmountTitle:SetText(HONOR_POINTS)
  -- -- Honor Amount
  frame.honorAmount = frame:CreateFontString('honorAmount', 'OVERLAY', 'GameFontNormal')
  frame.honorAmount:SetPoint('TOPLEFT', 60, -50)
  -- -- Honor Amount Max
  frame.honorAmountSplitter = frame:CreateFontString('honorAmountSplitter', 'OVERLAY', 'GameFontNormal')
  frame.honorAmountSplitter:SetPoint('TOPLEFT', 90, -50)
  frame.honorAmountSplitter:SetText('/')
  -- -- Honor Amount Max
  frame.honorAmountMax = frame:CreateFontString('honorAmountMax', 'OVERLAY', 'GameFontNormal')
  frame.honorAmountMax:SetPoint('TOPLEFT', 95, -50)

  -- -- Honor Level Title
  frame.honorLevelTitle = frame:CreateFontString('honorLevelTitle', 'OVERLAY', 'GameTooltipText')
  frame.honorLevelTitle:SetPoint('TOPLEFT', 12, -70)
  frame.honorLevelTitle:SetText(LFG_LIST_HONOR_LEVEL_INSTR_SHORT) -- LFG_LIST_HONOR_LEVEL_INSTR_SHORT = "Honor Level";
  -- -- Honor Level
  frame.honorLevel = frame:CreateFontString('honorLevel', 'OVERLAY', 'GameFontNormal')
  frame.honorLevel:SetPoint('TOPLEFT', 95, -70)

  -- Ratings

  -- -- Ratings Arena 2v2 Title
  frame.ratingsArena2v2Title = frame:CreateFontString('ratingsArena2v2Title', 'OVERLAY', 'GameTooltipText')
  frame.ratingsArena2v2Title:SetPoint('TOPLEFT', 12, -90)
  frame.ratingsArena2v2Title:SetText(ARENA_2V2)
  -- -- Ratings Arena 2v2 Amount
  frame.ratingsArena2v2Amount = frame:CreateFontString('ratingsArena2v2Amount', 'OVERLAY', 'GameFontNormal')
  frame.ratingsArena2v2Amount:SetPoint('TOPLEFT', 45, -90)

  -- -- Ratings Arena 3v3 Title
  frame.ratingsArena3v3Title = frame:CreateFontString('ratingsArena3v3Title', 'OVERLAY', 'GameTooltipText')
  frame.ratingsArena3v3Title:SetPoint('TOPLEFT', 12, -110)
  frame.ratingsArena3v3Title:SetText(ARENA_3V3)
  -- -- Ratings Arena 3v3 Amount
  frame.ratingsArena3v3Amount = frame:CreateFontString('ratingsArena3v3Amount', 'OVERLAY', 'GameFontNormal')
  frame.ratingsArena3v3Amount:SetPoint('TOPLEFT', 45, -110)

  -- -- Ratings RBG Title
  frame.ratingsRBGTitle = frame:CreateFontString('ratingsRBGTitle', 'OVERLAY', 'GameTooltipText')
  frame.ratingsRBGTitle:SetPoint('TOPLEFT', 12, -130)
  frame.ratingsRBGTitle:SetText('RBG') -- BATTLEGROUND_RATING = "Battleground Rating";, PVP_RATED_BATTLEGROUND = "Rated Battleground";
  -- -- Ratings RBG Amount
  frame.ratingsRBGAmount = frame:CreateFontString('ratingsRBGAmount', 'OVERLAY', 'GameFontNormal')
  frame.ratingsRBGAmount:SetPoint('TOPLEFT', 45, -130)
end

local function initFrame(frame)
  -- if frame and frame:GetHeight() ~= 0 then -- ~ - not
  if frame and frame:IsVisible() then -- Get whether the object is visible on screen (logically (IsShown() and GetParent():IsVisible()));
    return
  end

  -- frame = CreateFrame('Frame', ADDON_NAME .. 'EventFrame', UIParent)
  frame = CreateFrame('Frame', ADDON_NAME .. 'EventFrame', UIParent, 'BasicFrameTemplateWithInset')

  -- Frame Config

  frame:SetWidth(145)
  frame:SetHeight(150)
  frame:SetAlpha(0.8)

  frame:SetPoint('CENTER', -500, -300)

  frame:RegisterForDrag('LeftButton', 'RightButton')
  frame:SetScript('OnDragStart', frame.StartMoving)
  frame:SetScript('OnDragStop', frame.StopMovingOrSizing)

  frame:EnableMouse(true)
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:SetResizable(false)
  frame:SetUserPlaced(true)

  frame:SetBackdrop(
    {
      bgFile = 'Interface/Tooltips/UI-Tooltip-Background',
      edgeFile = 'Interface/Tooltips/UI-Tooltip-Border',
      tile = true,
      tileSize = 16,
      edgeSize = 16,
      insets = {left = 4, right = 4, top = 4, bottom = 4}
    }
  )
  frame:SetBackdropColor(0, 0, 0, .8)
  frame:SetBackdropBorderColor(1, 1, 1, 1)

  return frame
end

-- COMMANDS -----------------------------

SlashCmdList['WPVPA_SLASHCMD'] = function(msg)
  log(msg)
  local command = string.lower(msg:match('^(%S*)%s*(.-)$'))
  if command == 'show' then
    uiFrame:Show()
  elseif command == 'hide' then
    uiFrame:Hide()
  elseif command == 'help' or command == '?' then
    printHelp()
  elseif command == 'dump' then
    log(dump(storage))
    render(uiFrame)
  end
end
SLASH_WPVPA_SLASHCMD1 = COMMAND

-- MAIN ---------------------------------

local function onLoad()
  log('|cffc01300loaded')
  printHelp()
  uiFrame = initFrame(uiFrame)
  initContent(uiFrame)
  registerEvents(uiFrame)
  setEventListeners(uiFrame)
end

onLoad()
