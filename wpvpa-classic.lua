-- UPVALUES -----------------------------

local CreateFrame = CreateFrame
local GetInspectHonorData = GetInspectHonorData
local GetInspectPVPRankProgress = GetInspectPVPRankProgress
local GetPVPLastWeekStats = GetPVPLastWeekStats
local GetPVPLifetimeStats = GetPVPLifetimeStats
local GetPVPRankInfo = GetPVPRankInfo
local GetPVPThisWeekStats = GetPVPThisWeekStats
local GetRealmName = GetRealmName
local GetUnitName = GetUnitName
local HONOR_POINTS = HONOR_POINTS
local UIParent = UIParent
local UnitClass = UnitClass

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
  'ZONE_CHANGED_NEW_AREA',
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

local function getPlayer(name)
  return tostring(storage['player'][name])
end

-- STORE ACTIONS ------------------------

local function updateAll(storage)
  if (DEBUG) then
    UTILS:log('updateAll')
  end
end

local function updateRatings(storage)
  if (DEBUG) then
    UTILS:log('updateRatings')
  end

  local rankPoints = 0
  local hk, dk, highestRank = GetPVPLifetimeStats()
  local rankName, rankNumber = GetPVPRankInfo(highestRank)

  -- local rankName, rankNumber = GetPVPRankInfo(UnitPVPRank(playerUnitId))
  -- local hk, dk, contribution, standing = GetPVPLastWeekStats()
  local _, _, _, standing = GetPVPLastWeekStats()
  local _, contribution = GetPVPThisWeekStats()
  local _, _, _, _, thisweekHK, thisWeekHonor, _, lastWeekHonor = GetInspectHonorData()
  local rankProgress = GetInspectPVPRankProgress()

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
      ', rankNumber: ' .. UTILS:dump(rankNumber),
      ', lastWeekHonor: ' .. UTILS:dump(lastWeekHonor),
      ', thisWeekHonor: ' .. UTILS:dump(thisWeekHonor),
      ', standing: ' .. UTILS:dump(standing),
      ', rankProgress: ' .. UTILS:dump(rankProgress),
      ', thisweekHK: ' .. UTILS:dump(thisweekHK),
      ', rankPoints: ' .. UTILS:dump(rankPoints),
      ', hk: ' .. UTILS:dump(hk),
      ', dk: ' .. UTILS:dump(dk),
      ', contribution: ' .. UTILS:dump(contribution)
    )
  end

  storage['player']['honor'] = contribution or 0
  storage['player']['kills'] = hk or 0
  storage['player']['rankName'] = rankName or 'None'
  storage['player']['rankNumber'] = rankNumber or 0
  storage['player']['standing'] = standing or 0
end

-- FUNCTIONS ----------------------------

local function render(frame)
  if (DEBUG) then
    UTILS:log('render')
  end

  -- frame.killsAmount:SetText(getPlayer('kills'))
  -- frame.honorAmount:SetText(getPlayer('honor'))
  frame.root:SetText(
    'r' .. getPlayer('rankNumber') .. ' ' .. getPlayer('rankName') ..
    ', Standing ' .. getPlayer('standing') ..
    ', '.. L['Kills'] .. ' ' .. getPlayer('kills') ..
    ', '.. HONOR_POINTS .. ' ' .. getPlayer('honor')
  )
end

local function updatePVPStats(eventName)
  if (DEBUG) then
    UTILS:log('updatePVPStats triggered by: ', eventName)
  end
  updateRatings(storage)
end

-- EVENTS -------------------------------

local function onEvent(self, event, unit, ...)
  if (DEBUG) then
    UTILS:log('onEvent:', event, 'unit:', unit)
  end

  if
    (event == 'PLAYER_PVP_KILLS_CHANGED' or event == 'PLAYER_PVP_RANK_CHANGED' or event == 'UPDATE_BATTLEFIELD_SCORE' or
      event == 'PVP_WORLDSTATE_UPDATE' or
      event == 'ZONE_CHANGED_NEW_AREA' or
      event == 'PLAYER_ENTERING_WORLD')
   then
    updatePVPStats(event)
    render(uiFrame)
  elseif event == 'PLAYER_LOGIN' then
    updateAll(storage)
    render(uiFrame)
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
  frame.Title:SetPoint('TOPLEFT', 2, 10)
  frame.Title:SetText(ADDON_NAME)
  frame.Title:SetFont('Fonts\\FRIZQT__.TTF', 10)

  -- One line output
  frame.root = frame:CreateFontString('root', 'OVERLAY', 'GameTooltipText')
  frame.root:SetPoint('TOPLEFT', 6, -6)

  -- Rank
  -- -- Rank Name Title + Name + Standing
  -- frame.rank = frame:CreateFontString('rank', 'OVERLAY', 'GameTooltipText')
  -- frame.rank:SetPoint('TOPLEFT', 6, -6)

  -- -- Kills
  -- -- -- Kills Amount Title
  -- frame.killsAmountTitle = frame:CreateFontString('killsAmountTitle', 'OVERLAY', 'GameTooltipText')
  -- -- frame.killsAmountTitle:SetFont('Fonts\\FRIZQT__.TTF', 20)
  -- frame.killsAmountTitle:SetPoint('TOPLEFT', 6, -6)
  -- frame.killsAmountTitle:SetText(L['Kills'])
  -- -- -- Kills Amount
  -- frame.killsAmount = frame:CreateFontString('killsAmount', 'OVERLAY', 'GameFontNormal')
  -- -- frame.killsAmount:SetTextColor(0, 0, 0, 1) -- SetTextColor(r, g, b[, a]) - Sets the default text color.
  -- frame.killsAmount:SetPoint('TOPLEFT', 36, -6)

  -- -- Honor
  -- -- -- Honor Amount Title
  -- frame.honorAmountTitle = frame:CreateFontString('honorAmountTitle', 'OVERLAY', 'GameTooltipText')
  -- frame.honorAmountTitle:SetPoint('TOPLEFT', 80, -6)
  -- frame.honorAmountTitle:SetText(HONOR_POINTS .. ' c/w')
  -- -- -- Honor Amount
  -- frame.honorAmount = frame:CreateFontString('honorAmount', 'OVERLAY', 'GameFontNormal')
  -- frame.honorAmount:SetPoint('TOPLEFT', 150, -6)
end

local function initFrame(frame)
  -- if frame and frame:GetHeight() ~= 0 then -- ~ - not
  -- Get whether the object is visible on screen (logically (IsShown() and GetParent():IsVisible()));
  if frame and frame:IsVisible() then
    return
  end

  frame = CreateFrame('Frame', ADDON_NAME .. 'EventFrame', UIParent)

  -- Frame Config
  frame:SetWidth(300)
  frame:SetHeight(24)
  frame:SetAlpha(0.7)

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
  frame:SetBackdropColor(0, 0, 0, .6)

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
