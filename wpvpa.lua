-- CONSTANTS ----------------------------

-- local iconHeal = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:15:15:0:0:64:64:20:39:1:20|t"
-- local iconDmg = "|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:15:15:0:0:64:64:20:39:22:41|t"
-- local iconHonor = "Interface\\PVPFrame\\PVP-Currency-"..UnitFactionGroup('player')
-- local iconConquest = "Interface\\PVPFrame\\PVPCurrency-Conquest-"..UnitFactionGroup('player')

local ADDON_NAME = 'wpvpa'
local ADDON_VERSION = GetAddOnMetadata('wpvpa', 'Version')
local COMMAND = '/' .. ADDON_NAME
local ACHIEVEMENTS = {[2090] = 'Challenger', [2093] = 'Rival', [2092] = 'Duelist', [2091] = 'Gladiator'}
local BRACKETS = {[1] = 'ARENA_2V2', [2] = 'ARENA_3V3', [4] = 'BATTLEGROUND_10V10'}
-- Events sorted by how often they are triggered
local EVENTS = {
  'HONOR_XP_UPDATE',
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
  DEFAULT_CHAT_FRAME:AddMessage((ADDON_NAME .. ': %s'):format(msg))
end

-- @name logError
-- @param err string
-- @usage logError('Oh no!')
local function logError(err)
  log('|cffff0000' .. err)
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
    log('new config will be saved.')
    local className, classFile, classID = UnitClass('player')
    initialStorage = {
      player = {
        name = GetUnitName('player', false) or 'Unknown',
        realm = GetRealmName() or 'Unknown',
        class = classFile,
        achievements = {},
        honor = UnitHonor('player') or 0, -- TODO: (it's part of the honor lvl like lvl 15 and 4k from 8k)
        honorMax = UnitHonorMax('player') or 1, -- TODO: (it's part of the honor lvl like lvl 15 and 8k total)
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
    local rating,
      seasonBest,
      weeklyBest,
      seasonPlayed,
      seasonWon,
      weeklyPlayed,
      weeklyWon,
      lastWeeksBest,
      hasWon,
      pvpTier,
      ranking = GetPersonalRatedInfo(bracketIndex)
    storage['player']['ratings'][bracket] = rating or 0

    log('bracket: ' .. bracket, ', rating: ', rating, ', seasonBest: ', seasonBest)
    log('weeklyBest: ', weeklyBest, 'seasonPlayed: ', seasonPlayed, ', seasonWon: ', seasonWon)
    log('weeklyPlayed: ', weeklyPlayed, 'weeklyWon: ', weeklyWon)
    log('lastWeeksBest: ', lastWeeksBest, ', hasWon: ', hasWon 'pvpTier: ', pvpTier, ', ranking: ', ranking)
  end
end

local function updateAchievements()
  for id, name in pairs(ACHIEVEMENTS) do
    local completed = GetAchievementComparisonInfo(id)
    -- log('id: ',id,'name: ', name, 'completed: ', completed or 'false')
    if completed then
      storage['player']['achievements'][name] = true
    end
  end
end

-- FUNCTIONS ----------------------------

local function updatePVPStats(eventName)
  log('updatePVPStats triggered by: ', eventName)
  updateHonor()
  updateKills()
  updateRatings()
end

-- EVENTS -------------------------------

local function onEvent(self, event, unit, ...)
  log('onEvent:', event, 'unit:', unit)

  -- IsActiveBattlefieldArena()
  if event == 'HONOR_XP_UPDATE' then
    updatePVPStats(event)
  elseif event == 'HONOR_LEVEL_UPDATE' then
    updatePVPStats(event)
  elseif event == 'UPDATE_BATTLEFIELD_SCORE' then
    updatePVPStats(event)
  elseif event == 'ACHIEVEMENT_EARNED' then
    updateAchievements()
  elseif event == 'ZONE_CHANGED_NEW_AREA' then
    updatePVPStats(event)
  elseif event == 'PLAYER_ENTERING_WORLD' then
    updatePVPStats(event)
  -- elseif event == 'PLAYER_LOGIN' then
  end

  -- Our saved variables are ready at this point. If there are none, both variables will set to nil.
  -- This is the first time this addon is loaded.
  -- arg1 is a file name
  if event == 'ADDON_LOADED' and unit == ADDON_NAME then
    storage = getStorage(wpvpa_character_config)
    -- update achievements once
    updateAchievements()
  end
  if event == 'PLAYER_LOGOUT' then
    -- Save it
    wpvpa_character_config = storage
  end
end

-- UI and FRAME -------------------------

-- TODO: Update of the values in the table will be reflected in UI? or SetText is required?
-- local function render() end

local function registerEvents(frame)
  for _, eventName in pairs(EVENTS) do
    frame:RegisterEvent(eventName)
  end
end

local function setEventListeners(frame)
  frame:SetScript('OnEvent', onEvent)
end

local function initContent(frame)
  -- Addon Title
  frame.Title = frame:CreateFontString(ADDON_NAME .. 'Title', 'OVERLAY', 'GameFontNormal')
  frame.Title:SetPoint('TOP', 0, -2)
  frame.Title:SetText(ADDON_NAME .. ' {skull} Stats for ' .. storage['player']['name'])

  -- Kills
  -- -- Kills Amount Title
  frame.killsAmountTitle = frame:CreateFontString('killsAmountTitle', 'OVERLAY', 'GameFontNormal')
  frame.killsAmountTitle:SetFont('Fonts\\FRIZQT__.TTF', 20)
  frame.killsAmountTitle:SetPoint('TOP', 0, -2)
  frame.killsAmountTitle:SetText(HONORABLE_KILLS) -- HONORABLE_KILLS = "Honorable Kills";
  -- -- Kills Amount
  frame.killsAmount = frame:CreateFontString('killsAmount', 'ARTWORK', 'QuestFont_Shadow_Huge')
  frame.killsAmount:SetAllPoints(true)
  frame.killsAmount:SetFont('Fonts\\ARIALN.ttf', 13, 'OUTLINE')
  frame.killsAmount:SetPoint('CENTER', 0, 0)
  frame.killsAmount:SetJustifyH('LEFT')
  frame.killsAmount:SetJustifyV('TOP')
  frame.killsAmount:SetTextColor(0, 0, 0, 1) -- SetTextColor(r, g, b[, a]) - Sets the default text color.
  frame.killsAmount:SetText(storage['player']['kills'])

  -- Honor
  -- -- Honor Title
  frame.honorTitle = frame:CreateFontString('honorTitle', 'HIGHLIGHT', 'GameFontNormal')
  frame.honorTitle:SetPoint('LEFT', 1, 2)
  frame.honorTitle:SetText(PVP_LABEL_HONOR) -- PVP_LABEL_HONOR = "HONOR:";, -- HONOR_POINTS = "Honor";, -- HONOR = "Honor";

  -- -- Honor Amount Title
  frame.honorAmountTitle = frame:CreateFontString('honorAmountTitle', 'HIGHLIGHT', 'GameFontNormal')
  frame.honorAmountTitle:SetPoint('LEFT', 2, 3)
  frame.honorAmountTitle:SetText(HONOR_POINTS)
  -- -- Honor Amount
  frame.honorAmount = frame:CreateFontString('honorAmount', 'OVERLAY', 'GameFontNormal')
  frame.honorAmount:SetPoint('LEFT', 3, 4)
  frame.honorAmount:SetText(storage['player']['honor'])

  -- -- Honor Level Title
  frame.honorLevelTitle = frame:CreateFontString('honorLevelTitle', 'HIGHLIGHT', 'GameFontNormal')
  frame.honorLevelTitle:SetPoint('LEFT', 4, 5)
  frame.honorLevelTitle:SetText(HONOR_LEVEL_LABEL) -- HONOR_LEVEL_LABEL = "Honor Level %d";, LFG_LIST_HONOR_LEVEL_INSTR_SHORT = "Honor Level";
  -- -- Honor Level
  frame.honorLevel = frame:CreateFontString('honorLevel', 'OVERLAY', 'GameFontNormal')
  frame.honorLevel:SetPoint('LEFT', 5, 6)
  frame.honorLevel:SetText(storage['player']['honorLvl'])

  -- Ratings
  -- -- Ratings Arena Title
  frame.ratingsArenaTitle = frame:CreateFontString('ratingsArenaTitle', 'OVERLAY', 'GameFontNormal')
  frame.ratingsArenaTitle:SetPoint('LEFT', 4, 14)
  frame.ratingsArenaTitle:SetText(PVP_LABEL_ARENA) -- PVP_LABEL_ARENA = "ARENA:";, -- ARENA = "Arena";

  -- -- Ratings Arena 2v2 Title
  frame.ratingsArena2v2Title = frame:CreateFontString('ratingsArena2v2Title', 'OVERLAY', 'GameFontNormal')
  frame.ratingsArena2v2Title:SetPoint('LEFT', 5, 15)
  frame.ratingsArena2v2Title:SetText(ARENA_2V2)
  -- -- Ratings Arena 2v2 Amount
  frame.ratingsArena2v2Amount = frame:CreateFontString('ratingsArena2v2Amount', 'OVERLAY', 'GameFontNormal')
  frame.ratingsArena2v2Amount:SetPoint('LEFT', 6, 16)
  frame.ratingsArena2v2Amount:SetText(storage['player']['ratings'][BRACKETS[1]])

  -- -- Ratings Arena 3v3 Title
  frame.ratingsArena3v3Title = frame:CreateFontString('ratingsArena3v3Title', 'OVERLAY', 'GameFontNormal')
  frame.ratingsArena3v3Title:SetPoint('LEFT', 7, 17)
  frame.ratingsArena3v3Title:SetText(ARENA_3V3)
  -- -- Ratings Arena 3v3 Amount
  frame.ratingsArena3v3Amount = frame:CreateFontString('ratingsArena3v3Amount', 'OVERLAY', 'GameFontNormal')
  frame.ratingsArena3v3Amount:SetPoint('LEFT', 8, 18)
  frame.ratingsArena3v3Amount:SetText(storage['player']['ratings'][BRACKETS[2]])

  -- -- TODO: ARENA_BATTLES_2V2 = "2v2 Arena Battles";
  -- -- TODO: ARENA_BATTLES_3V3 = "3v3 Arena Battles";

  -- -- TODO: Ratings RBG Title
  -- -- TODO: Ratings RBG Amount
  -- BATTLEGROUND_RATING = "Battleground Rating";, PVP_RATED_BATTLEGROUND = "Rated Battleground";
  -- storage['player']['ratings'][BRACKETS[3]]
end

local function initFrame(frame)
  -- TODO: IsVisible() - Get whether the object is visible on screen (logically (IsShown() and GetParent():IsVisible()));
  -- ~ - not
  if frame and frame:GetHeight() ~= 0 then
    return
  end

  -- frame = CreateFrame('Frame', ADDON_NAME .. 'EventFrame', UIParent)
  frame = CreateFrame('Frame', ADDON_NAME .. 'EventFrame', UIParent, 'BasicFrameTemplateWithInset')

  -- assign it to the global
  uiFrame = frame

  -- Frame Config

  frame:SetWidth(200)
  frame:SetHeight(150)
  frame:SetAlpha(0.5)

  -- frame:SetPoint('CENTER', 650, -100)
  -- frame:SetPoint('CENTER', UIParent, 'CENTER')
  frame:SetPoint('CENTER')

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
end

-- COMMANDS -----------------------------

SlashCmdList['WPVPA_SLASHCMD'] = function(msg)
  log(msg)
  local command, rest = msg:match('^(%S*)%s*(.-)$')
  if string.lower(command) == 'show' then
    uiFrame:Show()
  elseif string.lower(command) == 'hide' then
    uiFrame:Hide()
  elseif string.lower(command) == 'help' or command == '?' then
    printHelp()
  elseif string.lower(command) == 'dump' then
    -- TODO: check GetInspectSpecialization
    -- TODO: check GetInspectRatedBGData
    -- log(dump(getStorage(nil)))
    updateAchievements()
    log(dump(storage))
  end
end
SLASH_WPVPA_SLASHCMD1 = COMMAND

-- MAIN ---------------------------------

local function onLoad()
  log('loaded')
  printHelp()

  initFrame(uiFrame)
  -- TODO: do it!
  -- initContent(uiFrame)
  registerEvents(uiFrame)
  setEventListeners(uiFrame)

  -- TODO: DEBUG HERE
  -- local debugInfo = getStorage()
  -- log(debugInfo.player.name)
  -- logError(debugInfo.player.class)
end

-- LAST CALL ----------------------------
onLoad()
