
--#region Const
FRAMES_TO_SHUFFLE = 50
FRAMES_TO_ROTATION = 1
--#endregion

--#region API

---Перемещает объект на новые координаты
---@param obj tts__Object|nil
---@param coords table можно задать любые из координат, например {x=10, y=-2}
function Move(obj, coords)
    if not obj then
        return
    end
    local pos = obj.getPosition()
    local newX = First(coords.x, pos.x)
    local newY = First(coords.y, pos.y)
    local newZ = First(coords.z, pos.z)
    obj.setPosition({newX, newY, newZ})
end

---Поворачивает объект на новые координаты
---@param obj tts__Object|nil
---@param coords table можно задать любые из координат, например {x=10, y=-2}
function RotateSmooth(obj, coords)
    if not obj then
        return
    end
    local pos = obj.getRotation()
    local newX = First(coords.x, pos.x)
    local newY = First(coords.y, pos.y)
    local newZ = First(coords.z, pos.z)
    obj.setRotationSmooth({newX, newY, newZ})
end

---Проверяет что все объекты в таблице инициализированы
---@param tab table
function TestObjectsInit(tab)
    for name,obj in pairs(tab) do
        if not obj then
            print("Object '" .. name .. "' isn't initialized")
        end
    end
end

---Получает колоду и/или карту находящуюся в зоне
---@param zone tts__ScriptingTrigger
---@param tag string если передан, то все объекты без этого тэга игнорируются
---@return tts__Deck|nil
---@return tts__Card|nil
function GetDeckCardFromZone(zone, tag)
    local deck, card
    for _,obj in pairs(zone.getObjects()) do

        if not tag or tag and obj.hasTag(tag) then
            if obj.type == 'Deck' then
                deck = obj
            elseif obj.type == 'Card' then
                card = obj
            end
        end

    end
    return deck, card
end

---Загружает состояние
---@param script_state string
---@return nil|any state декодированный JSON, обычно множество
---@return boolean loaded загружено ли
function LoadedState(script_state)
    local state, loaded
    if script_state == '' then
        state = nil
        loaded = false
    else
        state = JSON.decode(script_state)
        loaded = true
    end
    return state, loaded
end

---Возвращает первое значение из переданной таблицы которое не nil
---@param ... table
---@return any val первое не-nil значение
function First(...)
    local params = {...}
    for i,val in pairs(params) do
        if val then
            return val
        end
    end
    return nil
end

---Возвращает первое или второе, в зависимости от выражения
---@param expression boolean
---@param onTrue any
---@param onFalse any
---@return any
function Choose(expression, onTrue, onFalse)
    if expression then
        return onTrue
    else
        return onFalse
    end
end

---Переворачивает объект в открытую
---@param obj tts__Object
function SetFaceUp(obj)
    local curr = obj.getRotation()
    obj.setRotation({curr.x, curr.y, 0})
end

---Переворачивает объект в открытую плавно
---@param obj tts__Object
---@param direction '+/-' направление поворота: налево или направо
function SetFaceUpSmooth(obj, direction)
    local curr = obj.getRotation()
    local z = 0
    if     direction == '+' then
        z = z + 0.1
    elseif direction == '-' then
        z = z - 0.1
    end
    obj.setRotationSmooth({curr.x, curr.y, z})
end

---Переворачивает объект взакрытую
---@param obj tts__Object
function SetFaceDown(obj)
    local curr = obj.getRotation()
    obj.setRotation({curr.x, curr.y, 180})
end

---Переворачивает объект взакрытую плавно
---@param obj tts__Object
---@param direction '+/-' направление поворота: налево или направо
function SetFaceDownSmooth(obj, direction)
    local curr = obj.getRotation()
    local z = 180
    if     direction == '-' then
        z = z + 0.5
    elseif direction == '+' then
        z = z - 0.5
    end
    obj.setRotationSmooth({curr.x, curr.y, z})
end

---Возвращает ключи таблицы
---@param tab table
---@return table
function Keys(tab)
    local res = {}
    for k,v in pairs(tab) do
        table.insert(res, k)
    end
    return res
end

---Возвращает значения таблицы
---@param tab table
---@return table
function Values(tab)
    local res = {}
    for k,v in pairs(tab) do
        table.insert(res, v)
    end
    return res
end

---Проверяет что ключ есть в таблице
---@param key any
---@param tab table
---@return boolean
function KeyIsInTable(key, tab)
    return (tab[key] ~= nil)
end

---Проверяет что значение есть в таблице
---@param val any
---@param tab table
---@return boolean
function ValueIsInTable(val, tab)
    for _,v in pairs(tab) do
        if v == val then
            return true
        end
    end
    return false
end

---Делит строку на части разделителем
---@param str string
---@param splitter string
---@return string[]
function Split(str, splitter)
    if string.len(splitter) ~= 1 then
        error('Split cant work with splitter ' .. splitter)
    end
    local res = {}
    local sub = ''
    for i = 1,string.len(str) do
        local c = string.sub(str, i, i)
        if c == splitter then
            if sub ~= '' then
                table.insert(res, sub)
                sub = ''
            end
        else
            sub = sub .. c
        end
    end
    if sub ~= '' then
        table.insert(res, sub)
    end
    return res
end

---Соответствие из строки
---@param notes string строка в формате "ключ1:знач1;ключ2:знач2"
---@return table set в формате {ключ1='знач1', ключ2='знач2'}
function SetFromNotes(notes)
    local res = {}
    local ss = Split(notes, ';')
    for _,s in ipairs(ss) do
        local k_v = Split(s, ':')
        local k = k_v[1]
        local v = k_v[2]
        res[k] = v
    end
    return res
end

---Перемешивает колоду и через время вызывается callback
---@param deck tts__Deck
---@param callback callback_function
function ShuffleAsync(deck, callback)

    deck.shuffle()

    if callback then
        Wait.frames(callback, FRAMES_TO_SHUFFLE)
    end
end

---Перевернуть взакрытую плавно и затем выполнить функцию
---@param obj tts__Object
---@param callback callback_function
function SetFaceDownAsync(obj, callback)
    SetFaceDown(obj)

    if callback then
        Wait.frames(callback, FRAMES_TO_ROTATION)
    end
end

---Перевернуть в открытую плавно и затем выполнить функцию
---@param obj tts__Object
---@param callback callback_function
function SetFaceUpAsync(obj, callback)
    SetFaceUp(obj)

    if callback then
        Wait.frames(callback, FRAMES_TO_ROTATION)
    end
end

---Удалить значение из таблицы
---@param val any
---@param tab table
function RemoveValueFromTable(val, tab)
    local toRemove = {}
    for i,v in pairs(tab) do
        if v == val then
            table.insert(toRemove, i)
        end
    end
    for _,i in ipairs(toRemove) do
        table.remove(tab, i)
    end
end

---Возвращает следующего игрока
---@param list tts__PlayerColor[] порядок хода игроков, цветами
---@param color tts__PlayerColor
---@return tts__PlayerColor
function NextPlayer(list, color)
    local found = false
    for _,col in ipairs(list) do
        if found then
            return col
        end
        if color == col then
            found = true
        end
    end
    return list[1]
end

---Возвращает очередность ходов, упорядоченную начиная с переданного цвета
---@param list tts__PlayerColor[] порядок ходов
---@param color tts__PlayerColor начинать с этого цвета
---@return tts__PlayerColor[] list
function SortByPlayer(list, color)
    local res = {}

    local found = false
    for _,col in ipairs(list) do
        if color == col then
            found = true
        end
        if found then
            table.insert(res, col)
        end
    end

    found = false
    for _,col in ipairs(list) do
        if color == col then
            found = true
            break
        end
        if not found then
            table.insert(res, col)
        end
    end

    return res
end

---Логирует все переданные значения по очереди
---@param ... any[]
function Log(...)
    for _,val in pairs({...}) do
        log(val)
    end
end

---@class tts__Propertys
---@field tag string
---@field gm_notes string

---Отбирает объекты по свойствам
---@param objects nil|tts__Object[]|tts__IndexedSimpleObjectState[]
---@param properties tts__Propertys[] отбор
---@return nil|tts__Object[]|tts__IndexedSimpleObjectState[]
function GetObjectsByProperty(objects, properties)
    local res = {}
    for _,obj in ipairs(objects) do
        for k,v in pairs(properties) do
            if type(obj) == 'table' then
                if k == 'tag' and ValueIsInTable(v, obj.tags) then
                    table.insert(res, obj)
                elseif obj[k] == v then
                    table.insert(res, obj)
                end
            else
                if k == 'name' and obj.getName() == v then
                    table.insert(res, obj)
                elseif k == 'gm_notes' and obj.getGMNotes() == v then
                    table.insert(res, obj)
                elseif k == 'tag' and ValueIsInTable(v, obj.getTags()) then
                    table.insert(res, obj)
                elseif k == 'description' and obj.getDescription() == v then
                    table.insert(res, obj)
                --[[elseif obj[k] == v then
                    table.insert(res, obj)]]
                end
            end
        end
    end
    return res
end

---Возвращает вектор вращения такой же как у переданного объекта, с возможно отдельным z
---@param object tts__Object
---@param z number|nil
---@return tts__Vector
function XYRotation(object, z)
    local z = Choose(z, z, 0)
    local rotation = object.getRotation()
    return Vector(rotation.x, rotation.y, z)
end

function GetPlayerByColor(color)
    local players = Player.getPlayers()
    for _,player in ipairs(players) do
        if player.color == color then
            return player
        end
    end
    return nil
end

--#endregion