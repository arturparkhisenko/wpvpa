-- UPVALUES -----------------------------
local UIParent = UIParent
local CreateFrame = CreateFrame
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local GetAddOnMetadata = GetAddOnMetadata
local GetUnitName = GetUnitName

-- CONSTANTS ----------------------------

local ADDON_NAME, namespace = ...
local ADDON_VERSION = GetAddOnMetadata(ADDON_NAME, 'Version')
local COMMAND = '/' .. ADDON_NAME
local DEBUG = nil
local LOG_PREFIX = ADDON_NAME .. ': %s'

-- IMPORTS ------------------------------

local L = namespace.L -- Languages Table
local UTILS = namespace.UTILS

-- VARIABLES ----------------------------

local uiFrame = nil
local storage = nil
local classic = nil

-- EVENTS -------------------------------

local function onEvent(self, event, unit, ...)
  if (DEBUG) then
    UTILS.log('onEvent:', event, 'unit:', unit)
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

local function registerEvents(frame)
  for _, eventName in pairs(EVENTS) do
    frame:RegisterEvent(eventName)
  end
end

local function setEventListeners(frame)
  frame:SetScript('OnEvent', onEvent)
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

-- COMMANDS -----------------------------

SlashCmdList['WPVPA_SLASHCMD'] = function(msg)
  UTILS.log(msg)
  local command = string.lower(msg:match('^(%S*)%s*(.-)$'))
  if command == 'show' then
    uiFrame:Show()
  elseif command == 'hide' then
    uiFrame:Hide()
  elseif command == 'help' or command == '?' then
    UTILS.printHelp()
  elseif command == 'dump' then
    UTILS.log(dump(storage))
    render(uiFrame)
  end
end
SLASH_WPVPA_SLASHCMD1 = COMMAND

-- MAIN ---------------------------------

local function onLoad()
  classic = UTILS.isClassic()
  UTILS.loadAPI(classic)
  UTILS.log('|cffc01300loaded')
  UTILS.printHelp()
  uiFrame = initFrame(uiFrame)
  initContent(uiFrame)
  registerEvents(uiFrame)
  setEventListeners(uiFrame)
end

onLoad()
