-- UPVALUES -----------------------------
local ARENA_2V2 = ARENA_2V2
local ARENA_3V3 = ARENA_3V3
local ClearInspectPlayer = ClearInspectPlayer
local CreateFrame = CreateFrame
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local FocusFrameSpellBar = FocusFrameSpellBar
local GetAchievementInfo = GetAchievementInfo
local GetAddOnMetadata = GetAddOnMetadata
local GetInspectHonorData = GetInspectHonorData
local GetInspectPVPRankProgress = GetInspectPVPRankProgress
local GetPersonalRatedInfo = GetPersonalRatedInfo
local GetPVPLifetimeStats = GetPVPLifetimeStats
local GetRealmName = GetRealmName
local GetUnitName = GetUnitName
local HONOR_POINTS = HONOR_POINTS
local LFG_LIST_HONOR_LEVEL_INSTR_SHORT = LFG_LIST_HONOR_LEVEL_INSTR_SHORT
local MainMenuBarArtFrame = MainMenuBarArtFrame
local NotifyInspect = NotifyInspect
local PLAYER_FACTION_GROUP = PLAYER_FACTION_GROUP
local RequestInspectHonorData = RequestInspectHonorData
local UIParent = UIParent
local UnitClass = UnitClass
-- local UnitFactionGroup = UnitFactionGroup
local UnitHonor = UnitHonor
local UnitHonorLevel = UnitHonorLevel
local UnitHonorMax = UnitHonorMax

-- CONSTANTS ----------------------------

local ADDON_NAME, namespace = ...
local DEBUG = nil

-- IMPORTS ------------------------------

local L = namespace.L -- Languages Table
local UTILS = namespace.UTILS

-- VERSION CHECK ------------------------

if UTILS:isClassic() == true then
  return
end

-- MODULE -------------------------------

local API = {}
namespace.API = API

-- VARIABLES ----------------------------

local storage = nil
local uiFrame = nil

-----------------------------------------

local ADDON_NAME, namespace = ...
local ADDON_VERSION = GetAddOnMetadata(ADDON_NAME, 'Version')
local COMMAND = '/' .. ADDON_NAME
local DEBUG = nil
local L = namespace.L -- Languages Table
local LOG_PREFIX = ADDON_NAME .. ': %s'

-- Events sorted by how often they are triggered
local EVENTS = {
  'HONOR_XP_UPDATE',
  'PVP_RATED_STATS_UPDATE',
  'HONOR_LEVEL_UPDATE',
  'UPDATE_BATTLEFIELD_SCORE',
  'ACHIEVEMENT_EARNED',
  'PVP_WORLDSTATE_UPDATE',
  'ZONE_CHANGED_NEW_AREA',
  'PLAYER_ENTERING_WORLD',
  'PLAYER_LOGIN',
  'PLAYER_LOGOUT', -- Fired when about to log out
  'ADDON_LOADED' -- Fired when saved variables are loaded
}

local ICON_PVP_CHALLENGER = 236537
local ICON_PVP_RIVAL = 236538
local ICON_PVP_DUELIST = 236539
local ICON_PVP_GLADIATOR = 236540

-- local ICON_HONOR = 'Interface\\PVPFrame\\PVP-Currency-' .. UnitFactionGroup('player')
-- local ICON_CONQUEST = 'Interface\\PVPFrame\\PVPCurrency-Conquest-' .. UnitFactionGroup('player')
local ICON_BG_TEXTURE = 'Interface\\PVPFrame\\RandomPVPIcon'
local ICON_FACTION_CIRCLE = 'Interface\\TargetingFrame\\UI-PVP-' .. PLAYER_FACTION_GROUP[0]

local ACHIEVEMENTS = {[2090] = 'Challenger', [2093] = 'Rival', [2092] = 'Duelist', [2091] = 'Gladiator'}
local BRACKETS = {[1] = 'ARENA_2V2', [2] = 'ARENA_3V3', [4] = 'BATTLEGROUND_10V10'}

-- STORAGE ------------------------------
-- -- Per-character settings for each individual AddOn.
-- -- WTF\Account\ACCOUNTNAME\RealmName\CharacterName\SavedVariables\AddOnName.lua

local function getStorage(loadedStorage)
  local initialStorage = loadedStorage
  if initialStorage == nil then
    if (DEBUG) then
      UTILS:log('new config will be saved.')
    end
    local className, classFile = UnitClass('player')
    initialStorage = {
      player = {
        name = GetUnitName('player', false) or L['Unknown'],
        realm = GetRealmName() or L['Unknown'],
        class = classFile,
        achievements = {},
        honor = UnitHonor('player') or 0,
        honorMax = UnitHonorMax('player') or 1,
        honorLevel = UnitHonorLevel('player') or 1,
        kills = GetPVPLifetimeStats() or 0,
        ratings = {[BRACKETS[1]] = 0, [BRACKETS[2]] = 0, [BRACKETS[4]] = 0},
        winRates = {[BRACKETS[1]] = 0, [BRACKETS[2]] = 0, [BRACKETS[4]] = 0}
      }
    }
  end
  return initialStorage
end

-- STORE ACTIONS ------------------------

local function updateHonor()
  if (DEBUG) then
    UTILS:log('updateHonor')
  end

  storage['player']['honor'] = UnitHonor('player') or 0
  storage['player']['honorMax'] = UnitHonorMax('player') or 1
  storage['player']['honorLevel'] = UnitHonorLevel('player') or 1
end

local function updateKills()
  if (DEBUG) then
    UTILS:log('updateKills')
  end

  local honorableKills = GetPVPLifetimeStats()
  storage['player']['kills'] = honorableKills or 0
end

local function updateRatings()
  if (DEBUG) then
    UTILS:log('updateRatings')
  end

  for bracketIndex, bracket in pairs(BRACKETS) do
    -- https://www.townlong-yak.com/framexml/ptr/Blizzard_PVPUI/Blizzard_PVPUI.lua
    local rating, seasonBest, weeklyBest, seasonPlayed, seasonWon, weeklyPlayed, weeklyWon, cap =
      GetPersonalRatedInfo(bracketIndex)
    if (DEBUG) then
      UTILS:log(
        'rating: ',
        rating,
        'seasonBest: ',
        seasonBest,
        'weeklyBest: ',
        weeklyBest,
        'seasonPlayed: ',
        seasonPlayed,
        'seasonWon: ',
        seasonWon,
        'weeklyPlayed: ',
        weeklyPlayed,
        'weeklyWon: ',
        weeklyWon,
        'cap: ',
        cap
      )
    end
    storage['player']['ratings'][bracket] = rating or 0
    storage['player']['winRates'][bracket] = UTILS:getWinRatePercent(seasonPlayed, seasonWon)
  end

  -- TODO: Classic part
  local playerUnitId = 'player'
  local rankPoints = 0

  NotifyInspect(playerUnitId)
  RequestInspectHonorData()

  local _, rank = GetPVPRankInfo(UnitPVPRank(playerUnitId))
  local _, _, _, _, thisweekHK, thisWeekHonor, _, lastWeekHonor, standing = GetInspectHonorData()
  local rankProgress = GetInspectPVPRankProgress()

  ClearInspectPlayer()

  if (thisweekHK >= 15) then
    if (rank >= 3) then
      rankPoints = math.ceil((rank - 2) * 5000 + rankProgress * 5000)
    elseif (rank == 2) then
      rankPoints = math.ceil(rankProgress * 3000 + 2000)
    end
  end

  if (DEBUG) then
    UTILS:log('rating: ', thisWeekHonor, 'cap: ', lastWeekHonor, standing, rankProgress, rankPoints)
  end

  -- TODO: write to the storage
  -- storage['player']['ratings'][bracket] = rating or 0
end

local function updateAchievements()
  if (DEBUG) then
    UTILS:log('updateAchievements')
  end

  for id, name in pairs(ACHIEVEMENTS) do
    -- local IDNumber, Name, Points, Completed, Month, Day, Year, Description, Flags, Icon, RewardText, isGuildAch = GetAchievementInfo(id)
    local id, name, points, completed = GetAchievementInfo(id)
    if (DEBUG) then
      UTILS:log('id: ', id, 'name: ', name, 'completed: ', completed or 'false')
    end
    if completed then
      storage['player']['achievements'][name] = true
    end
  end
end

-- FUNCTIONS ----------------------------

local function renderHighestTitleIcon(frame)
  if (DEBUG) then
    UTILS:log('renderHighestTitleIcon')
  end

  if (storage['player']['achievements']['Challenger'] == true) then
    frame.iconHighestTitle.texture:SetTexture(ICON_PVP_CHALLENGER)
  elseif (storage['player']['achievements']['Rival'] == true) then
    frame.iconHighestTitle.texture:SetTexture(ICON_PVP_RIVAL)
  elseif (storage['player']['achievements']['Duelist'] == true) then
    frame.iconHighestTitle.texture:SetTexture(ICON_PVP_DUELIST)
  elseif (storage['player']['achievements']['Gladiator'] == true) then
    frame.iconHighestTitle.texture:SetTexture(ICON_PVP_GLADIATOR)
  end
end

local function render(frame)
  if (DEBUG) then
    UTILS:log('render')
  end

  frame.killsAmount:SetText(storage['player']['kills'])

  frame.honorAmount:SetText(storage['player']['honor'])
  frame.honorAmountMax:SetText(storage['player']['honorMax'])
  frame.honorLevel:SetText(storage['player']['honorLevel'])

  frame.ratingsArena2v2Amount:SetText(storage['player']['ratings'][BRACKETS[1]])
  frame.ratingsArena3v3Amount:SetText(storage['player']['ratings'][BRACKETS[2]])
  frame.ratingsRBGAmount:SetText(storage['player']['ratings'][BRACKETS[4]])

  frame.winrateArena2v2:SetText('w/r ' .. storage['player']['winRates'][BRACKETS[1]] .. '%')
  frame.winrateArena3v3:SetText('w/r ' .. storage['player']['winRates'][BRACKETS[2]] .. '%')
  frame.winrateRBG:SetText('w/r ' .. storage['player']['winRates'][BRACKETS[4]] .. '%')

  renderHighestTitleIcon(frame)
end

local function updatePVPStats(eventName)
  if (DEBUG) then
    UTILS:log('updatePVPStats triggered by: ', eventName)
  end

  updateHonor()
  updateKills()
  updateRatings()
end

-- EVENTS -------------------------------

local function onEvent(self, event, unit, ...)
  if (DEBUG) then
    UTILS:log('onEvent:', event, 'unit:', unit)
  end

  if
    (event == 'HONOR_XP_UPDATE' or event == 'PVP_RATED_STATS_UPDATE' or event == 'HONOR_LEVEL_UPDATE' or
      event == 'UPDATE_BATTLEFIELD_SCORE' or
      event == 'ZONE_CHANGED_NEW_AREA' or
      event == 'PLAYER_ENTERING_WORLD')
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
    local currentPlayerName = GetUnitName('player', false) or L['Unknown']
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

-- UI and FRAME -------------------------

-- TODO: implement settings feature
-- local function initSettings(frame)
--   -- https://wow.gamepedia.com/Using_the_Interface_Options_Addons_panel
--   -- https://wowwiki.fandom.com/wiki/Using_the_Interface_Options_Addons_panel
--   -- https://wowwiki.fandom.com/wiki/Creating_GUI_configuration_options
-- end

-- ofsx (negative values will move obj left, positive values will move obj right), defaults to 0 if not specified.
-- ofsy (negative values will move obj down, positive values will move obj up), defaults to 0 if not specified.
local function initContent(frame)
  -- Addon Title
  frame.Title = frame:CreateFontString(ADDON_NAME .. 'Title', 'OVERLAY', 'GameFontNormal')
  frame.Title:SetPoint('TOP', -10, -5)
  frame.Title:SetText(ADDON_NAME .. ' ' .. L['stats'])

  -- Icon Addon Title
  frame.iconAddonTitle = CreateFrame('Frame')
  frame.iconAddonTitle.texture = frame.iconAddonTitle:CreateTexture(nil, 'BACKGROUND')
  frame.iconAddonTitle.texture:SetTexture(ICON_FACTION_CIRCLE)
  frame.iconAddonTitle.texture:SetAllPoints(frame.iconAddonTitle)
  frame.iconAddonTitle:SetWidth(30)
  frame.iconAddonTitle:SetHeight(30)
  frame.iconAddonTitle:SetParent(frame)
  frame.iconAddonTitle:SetPoint('TOPLEFT', frame, 10, -3)

  -- Kills
  -- -- Kills Amount Title
  frame.killsAmountTitle = frame:CreateFontString('killsAmountTitle', 'OVERLAY', 'GameTooltipText')
  -- frame.killsAmountTitle:SetFont('Fonts\\FRIZQT__.TTF', 20)
  frame.killsAmountTitle:SetPoint('TOPLEFT', 12, -30)
  frame.killsAmountTitle:SetText(L['Kills']) -- HONORABLE_KILLS = "Honorable Kills";
  -- -- Kills Amount
  frame.killsAmount = frame:CreateFontString('killsAmount', 'OVERLAY', 'GameFontNormal')
  -- frame.killsAmount:SetTextColor(0, 0, 0, 1) -- SetTextColor(r, g, b[, a]) - Sets the default text color.
  frame.killsAmount:SetPoint('TOPLEFT', 80, -30)

  -- Honor

  -- -- Honor Amount Title
  frame.honorAmountTitle = frame:CreateFontString('honorAmountTitle', 'OVERLAY', 'GameTooltipText')
  frame.honorAmountTitle:SetPoint('TOPLEFT', 12, -50)
  frame.honorAmountTitle:SetText(HONOR_POINTS)
  -- -- Honor Amount
  frame.honorAmount = frame:CreateFontString('honorAmount', 'OVERLAY', 'GameFontNormal')
  frame.honorAmount:SetPoint('TOPLEFT', 70, -50)
  -- -- Honor Level Title
  frame.honorLevelTitle = frame:CreateFontString('honorLevelTitle', 'OVERLAY', 'GameTooltipText')
  frame.honorLevelTitle:SetPoint('TOPLEFT', 12, -70)
  frame.honorLevelTitle:SetText(LFG_LIST_HONOR_LEVEL_INSTR_SHORT) -- LFG_LIST_HONOR_LEVEL_INSTR_SHORT = "Honor Level";
  -- -- Honor Level
  frame.honorLevel = frame:CreateFontString('honorLevel', 'OVERLAY', 'GameFontNormal')
  frame.honorLevel:SetPoint('TOPLEFT', 110, -70)

  -- WinRates

  -- -- Kill Death Ratio
  frame.winrateArena2v2 = frame:CreateFontString('ratingsArena2v2Amount', 'OVERLAY', 'GameFontNormal')
  frame.winrateArena2v2:SetPoint('TOPLEFT', 85, -90)
end

local function initFrame(frame)
  -- if frame and frame:GetHeight() ~= 0 then -- ~ - not
  if frame and frame:IsVisible() then -- Get whether the object is visible on screen (logically (IsShown() and GetParent():IsVisible()));
    return
  end

  -- frame = CreateFrame('Frame', ADDON_NAME .. 'EventFrame', UIParent)
  frame = CreateFrame('Frame', ADDON_NAME .. 'EventFrame', UIParent, 'BasicFrameTemplateWithInset')

  -- Frame Config

  frame:SetWidth(160)
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

  -- frame:SetBackdrop(
  --   {
  --     bgFile = 'Interface/Tooltips/UI-Tooltip-Background',
  --     edgeFile = 'Interface/Tooltips/UI-Tooltip-Border',
  --     tile = true,
  --     tileSize = 16,
  --     edgeSize = 16,
  --     insets = {left = 4, right = 4, top = 4, bottom = 4}
  --   }
  -- )
  -- frame:SetBackdropColor(0, 0, 0, .8)
  -- frame:SetBackdropBorderColor(1, 1, 1, 1)

  return frame
end

-- INIT ---------------------------------

-- @name init
-- @usage API:init(DEBUG)
function API:init(globalDebug)
  DEBUG = globalDebug
  uiFrame = initFrame(uiFrame)
  initContent(uiFrame)
  UTILS:registerEvents(uiFrame, EVENTS)
  UTILS:setEventListeners(uiFrame, onEvent)

  if (DEBUG) then
    UTILS:log('API:init')
  end
end

-- @name test
-- @usage API:test(eventName)
function API:test(eventName)
  updatePVPStats(eventName)
end

-- @name show shows ui frame
-- @usage API:show()
function API:show()
  uiFrame:Show()
end

-- @name hide hides ui frame
-- @usage API:hide()
function API:hide()
  uiFrame:Hide()
end

-- @name getStorage
-- @usage API:getStorage()
-- @returns storage table
function API:getStorage()
  return storage
end
