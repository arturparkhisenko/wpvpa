local _, namespace = ...

local L =
  setmetatable(
  {},
  {
    __index = function(t, k)
      local v = tostring(k)
      rawset(t, k, v)
      return v
    end
  }
)

namespace.L = L

local LOCALE = GetLocale()

-- The EU English game client also
-- uses the US English locale code.
if LOCALE == 'enUS' then
  return
end

-- German
if LOCALE == 'deDE' then
  L['Hello!'] = 'Hallo!'
  L['Unknown'] = 'Unbekannte'
  L['stats'] = 'Statistiken'
  L['Kills'] = 'Tötet'
  L['loaded'] = 'geladen'
  return
end

-- French
if LOCALE == 'frFR' then
  L['Hello!'] = 'Bonjour!'
  L['Unknown'] = 'Inconnu'
  L['stats'] = 'Statistiques'
  L['Kills'] = 'Tue'
  L['loaded'] = 'chargé'
  return
end

-- Spanish
if LOCALE == 'esES' or LOCALE == 'esMX' then
  L['Hello!'] = '¡Hola!'
  L['Unknown'] = 'Desconocido'
  L['stats'] = 'Estadísticas'
  L['Kills'] = 'Mata'
  L['loaded'] = 'cargado'
  return
end

-- Brazilian Portuguese
-- Note that the EU Portuguese WoW client also
-- uses the Brazilian Portuguese locale code.
if LOCALE == 'ptBR' then
  L['Hello!'] = 'Olá!'
  L['Unknown'] = 'Desconhecido'
  L['stats'] = 'Estatísticas'
  L['Kills'] = 'Mata'
  L['loaded'] = 'carregado'
  return
end

-- Russian
if LOCALE == 'ruRU' then
  L['Hello!'] = 'Привет!'
  L['Unknown'] = 'Неизвестно'
  L['stats'] = 'Статистика'
  L['Kills'] = 'Убийства'
  L['loaded'] = 'загружен'
  return
end

-- Korean
if LOCALE == 'koKR' then
  L['Hello!'] = '안녕하세요!'
  L['Unknown'] = '알 수 없는'
  L['stats'] = '통계'
  L['Kills'] = '살인'
  L['loaded'] = '짐을 실은'
  return
end

-- Simplified Chinese
if LOCALE == 'zhCN' then
  L['Hello!'] = '您好!'
  L['Unknown'] = '未知'
  L['stats'] = '统计'
  L['Kills'] = '杀敌'
  L['loaded'] = '已加载'
  return
end

-- Traditional Chinese
if LOCALE == 'zhTW' then
  L['Hello!'] = '您好!'
  L['Unknown'] = '未知'
  L['stats'] = '統計'
  L['Kills'] = '殺敵'
  L['loaded'] = '已加載'
  return
end
