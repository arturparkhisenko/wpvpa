std = 'lua51'
max_line_length = 120
self = false

exclude_files = {
  '.luacheckrc'
}

ignore = {
  '11./SLASH_.*', -- Setting an undefined (Slash handler) global variable
  '11./BINDING_.*', -- Setting an undefined (Keybinding header) global variable
  '113/LE_.*', -- Accessing an undefined (Lua ENUM type) global variable
  '113/NUM_LE_.*', -- Accessing an undefined (Lua ENUM type) global variable
  -- '211', -- Unused local variable
  -- '211/L', -- Unused local variable "L"
  -- '211/CL', -- Unused local variable "CL"
  -- '212', -- Unused argument
  -- '213', -- Unused loop variable
  -- '231', -- Set but never accessed
  -- '311', -- Value assigned to a local variable is unused
  -- '314', -- Value of a field in a table literal is unused
  -- '42.', -- Shadowing a local variable, an argument, a loop variable.
  -- '43.', -- Shadowing an upvalue, an upvalue argument, an upvalue loop variable.
  -- '542' -- An empty if branch
}

globals = {
  -- misc custom
  'wpvpa_character_config',
  -- FrameXML misc
  'DEFAULT_CHAT_FRAME',
  'SlashCmdList',
  -- FrameXML frames
  'UIParent',
  -- FrameXML globals
  'ChatFontNormal',
  'FONT_COLOR_CODE_CLOSE',
  'RED_FONT_COLOR_CODE',
  'STANDARD_TEXT_FONT',
  -- API functions
  'CreateFrame',
  'GetAchievementInfo',
  'GetAddOnMetadata',
  'GetInspectHonorData',
  'GetInspectPVPRankProgress',
  'GetLocale',
  'GetPersonalRatedInfo',
  'GetPVPLastWeekStats',
  'GetPVPLifetimeStats',
  'GetPVPRankInfo',
  'GetPVPThisWeekStats',
  'GetRealmName',
  'GetUnitName',
  'UnitClass',
  'UnitHonor',
  'UnitHonorLevel',
  'UnitHonorMax',
  -- framexml functions
  -- Constants.lua
  'PLAYER_FACTION_GROUP',
  -- GlobalStrings.lua
  'HONOR_POINTS',
  'WOW_PROJECT_CLASSIC',
  'WOW_PROJECT_ID'
}
