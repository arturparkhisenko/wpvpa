-- UPVALUES -----------------------------

local ClearInspectPlayer = ClearInspectPlayer
local CreateFrame = CreateFrame
local GetAchievementInfo = GetAchievementInfo
local GetAddOnMetadata = GetAddOnMetadata
local GetInspectHonorData = GetInspectHonorData
local GetInspectPVPRankProgress = GetInspectPVPRankProgress
local GetPersonalRatedInfo = GetPersonalRatedInfo
local GetPVPLastWeekStats = GetPVPLastWeekStats
local GetPVPLifetimeStats = GetPVPLifetimeStats
local GetPVPRankInfo = GetPVPRankInfo
local GetRealmName = GetRealmName
local GetUnitName = GetUnitName
local HONOR_POINTS = HONOR_POINTS
local LFG_LIST_HONOR_LEVEL_INSTR_SHORT = LFG_LIST_HONOR_LEVEL_INSTR_SHORT
local NotifyInspect = NotifyInspect
local PLAYER_FACTION_GROUP = PLAYER_FACTION_GROUP
local RequestInspectHonorData = RequestInspectHonorData
local UIParent = UIParent
local UnitClass = UnitClass
local UnitHonor = UnitHonor
local UnitPVPRank = UnitPVPRank

-- CONSTANTS ----------------------------

local ADDON_NAME, namespace = ...
local DEBUG = nil

-- IMPORTS ------------------------------

local L = namespace.L -- Languages Table
local UTILS = namespace.UTILS

-- VERSION CHECK ------------------------

if UTILS:isClassic() == false then
  return
end

-- MODULE -------------------------------

local API = {}
namespace.API = API

-- VARIABLES ----------------------------

local storage = nil
local uiFrame = nil

-----------------------------------------

-- @see https://git.tukui.org/Tukz/wow-classic/blob/master/Interface/FrameXML/HonorFrame.lua
-- Events sorted by how often they are triggered
local EVENTS = {
  'PLAYER_PVP_KILLS_CHANGED',
  'PLAYER_PVP_RANK_CHANGED',
  'UPDATE_BATTLEFIELD_SCORE',
  'PVP_WORLDSTATE_UPDATE',
  'PLAYER_ENTERING_WORLD',
  'PLAYER_LOGIN',
  'PLAYER_LOGOUT', -- Fired when about to log out
  'ADDON_LOADED' -- Fired when saved variables are loaded
}

-- STORAGE ------------------------------
-- -- Per-character settings for each individual AddOn.
-- -- WTF\Account\ACCOUNTNAME\RealmName\CharacterName\SavedVariables\AddOnName.lua

local function getStorage(loadedStorage)
  local initialStorage = loadedStorage
  if initialStorage == nil then
    if DEBUG then
      UTILS:log('new config will be saved.')
    end
    local className, classFile = UnitClass('player')
    initialStorage = {
      player = {
        name = GetUnitName('player', false) or L['Unknown'],
        realm = GetRealmName() or L['Unknown'],
        class = classFile,
        -- honor = UnitHonor('player') or 0,
        kills = GetPVPLifetimeStats() or 0
      }
    }
  end
  return initialStorage
end

-- STORE ACTIONS ------------------------

-- local function updateHonor(storage)
--   storage['player']['honor'] = UnitHonor('player') or 0

--   if (DEBUG) then
--     UTILS:log('updateHonor, honor: ', UnitHonor('player'))
--   end
-- end

local function updateKills(storage)
  -- TODO: honorableKills, dishonorableKills, highestRank = GetPVPLifetimeStats()
  local kills = GetPVPLifetimeStats()

  if (DEBUG) then
    UTILS:log('updateKills, kills: ', kills)
  end

  storage['player']['kills'] = kills or 0
end

local function updateRatings(storage)
  local playerUnitId = 'player'
  local rankPoints = 0

  if (DEBUG) then
    UTILS:log('updateRatings')
  end

  NotifyInspect(playerUnitId)
  RequestInspectHonorData()

  local rankName, rankNumber = GetPVPRankInfo(UnitPVPRank(playerUnitId))
  local hk, dk, contribution, rankStanding = GetPVPLastWeekStats()
  local _, _, _, _, thisweekHK, thisWeekHonor, _, lastWeekHonor, standing = GetInspectHonorData()
  local rankProgress = GetInspectPVPRankProgress()

  ClearInspectPlayer()

  if (thisweekHK >= 15) then
    if (rankNumber >= 3) then
      rankPoints = math.ceil((rankNumber - 2) * 5000 + rankProgress * 5000)
    elseif (rankNumber == 2) then
      rankPoints = math.ceil(rankProgress * 3000 + 2000)
    end
  end

  if (DEBUG) then
    UTILS:log(
      'rankName: ' .. UTILS:dump(rankName),
      ', rankNumber: '.. UTILS:dump(rankNumber),
      ', lastWeekHonor: '.. UTILS:dump(lastWeekHonor),
      ', thisWeekHonor: '.. UTILS:dump(thisWeekHonor),
      ', standing: '.. UTILS:dump(standing),
      ', rankProgress: '.. UTILS:dump(rankProgress),
      ', thisweekHK: '.. UTILS:dump(thisweekHK),
      ', rankPoints: '.. UTILS:dump(rankPoints),
      ', hk: '.. UTILS:dump(hk),
      ', dk: '.. UTILS:dump(dk),
      ', contribution: '.. UTILS:dump(contribution),
      ', rankStanding: '.. UTILS:dump(rankStanding)
    )
  end

  -- TODO: write to the storage
  -- storage['player']['ratings'][bracket] = rating or 0
end

-- FUNCTIONS ----------------------------

local function render(frame)
  frame.killsAmount:SetText(storage['player']['kills'])
  frame.honorAmount:SetText(storage['player']['honor'])
end

local function updatePVPStats(eventName)
  if (DEBUG) then
    UTILS:log('updatePVPStats triggered by: ', eventName)
  end
  -- updateHonor(storage)
  updateKills(storage)
  updateRatings(storage)
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
    render(uiFrame)
  end
  if event == 'PLAYER_LOGOUT' then
    -- Save it
    wpvpa_character_config = storage
  end
end

-- UI and FRAME -------------------------

-- ofsx (negative values will move obj left, positive values will move obj right), defaults to 0 if not specified.
-- ofsy (negative values will move obj down, positive values will move obj up), defaults to 0 if not specified.
local function initContent(frame)
  -- Addon Title
  frame.Title = frame:CreateFontString(ADDON_NAME .. 'Title', 'OVERLAY', 'GameFontNormal')
  frame.Title:SetPoint('TOPLEFT', 2, 12)
  frame.Title:SetText(ADDON_NAME .. ' ' .. L['stats'] .. ':')

  -- Kills
  -- -- Kills Amount Title
  frame.killsAmountTitle = frame:CreateFontString('killsAmountTitle', 'OVERLAY', 'GameTooltipText')
  -- frame.killsAmountTitle:SetFont('Fonts\\FRIZQT__.TTF', 20)
  frame.killsAmountTitle:SetPoint('TOPLEFT', 6, -6)
  frame.killsAmountTitle:SetText(L['Kills'])
  -- -- Kills Amount
  frame.killsAmount = frame:CreateFontString('killsAmount', 'OVERLAY', 'GameFontNormal')
  -- frame.killsAmount:SetTextColor(0, 0, 0, 1) -- SetTextColor(r, g, b[, a]) - Sets the default text color.
  frame.killsAmount:SetPoint('TOPLEFT', 36, -6)

  -- Honor
  -- -- Honor Amount Title
  frame.honorAmountTitle = frame:CreateFontString('honorAmountTitle', 'OVERLAY', 'GameTooltipText')
  frame.honorAmountTitle:SetPoint('TOPLEFT', 90, -6)
  frame.honorAmountTitle:SetText(HONOR_POINTS)
  -- -- Honor Amount
  frame.honorAmount = frame:CreateFontString('honorAmount', 'OVERLAY', 'GameFontNormal')
  frame.honorAmount:SetPoint('TOPLEFT', 110, -6)
end

local function initFrame(frame)
  -- if frame and frame:GetHeight() ~= 0 then -- ~ - not
  -- Get whether the object is visible on screen (logically (IsShown() and GetParent():IsVisible()));
  if frame and frame:IsVisible() then
    return
  end

  frame = CreateFrame('Frame', ADDON_NAME .. 'EventFrame', UIParent)

  -- Frame Config

  frame:SetWidth(200)
  frame:SetHeight(24)
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
