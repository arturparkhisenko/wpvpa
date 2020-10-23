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
  L['Kills'] = 'Tötet'
  L['loaded'] = 'geladen'
  L['stats'] = 'Statistiken'
  L['Unknown'] = 'Unbekannte'
  L['RBG'] = 'BS'
  return
end

-- French
if LOCALE == 'frFR' then
  L['Hello!'] = 'Bonjour!'
  L['Kills'] = 'Tue'
  L['loaded'] = 'chargé'
  L['stats'] = 'Statistiques'
  L['Unknown'] = 'Inconnu'
  L['RBG'] = 'CDBC'
  return
end

-- Spanish
if LOCALE == 'esES' or LOCALE == 'esMX' then
  L['Hello!'] = '¡Hola!'
  L['Kills'] = 'Mata'
  L['loaded'] = 'cargado'
  L['stats'] = 'Estadísticas'
  L['Unknown'] = 'Desconocido'
  L['RBG'] = 'CDBC'
  return
end

-- Brazilian Portuguese
-- Note that the EU Portuguese WoW client also
-- uses the Brazilian Portuguese locale code.
if LOCALE == 'ptBR' then
  L['Hello!'] = 'Olá!'
  L['Kills'] = 'Mata'
  L['loaded'] = 'carregado'
  L['stats'] = 'Estatísticas'
  L['Unknown'] = 'Desconhecido'
  L['RBG'] = 'CDBA'
  return
end

-- Russian
if LOCALE == 'ruRU' then
  L['Hello!'] = 'Привет!'
  L['Kills'] = 'Убийства'
  L['loaded'] = 'загружен'
  L['stats'] = 'Статистика'
  L['Unknown'] = 'Неизвестно'
  L['RBG'] = 'РБГ'
  return
end

-- Korean
if LOCALE == 'koKR' then
  L['Hello!'] = '안녕하세요!'
  L['Kills'] = '살인'
  L['loaded'] = '짐을 실은'
  L['stats'] = '통계'
  L['Unknown'] = '알 수 없는'
  L['RBG'] = '정격 전장'
  return
end

-- Simplified Chinese
if LOCALE == 'zhCN' then
  L['Hello!'] = '您好!'
  L['Kills'] = '杀敌'
  L['loaded'] = '已加载'
  L['stats'] = '统计'
  L['Unknown'] = '未知'
  L['RBG'] = '额定战场'
  return
end

-- Traditional Chinese
if LOCALE == 'zhTW' then
  L['Hello!'] = '您好!'
  L['Kills'] = '殺敵'
  L['loaded'] = '已加載'
  L['stats'] = '統計'
  L['Unknown'] = '未知'
  L['RBG'] = '額定戰場'
  return
end
