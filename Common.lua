
--#region Const
FRAMES_TO_SHUFFLE = 50
FRAMES_TO_ROTATION = 1
TurnsType = {Auto = 1, Custom = 2}
--#endregion

--#region TTS

--#region Player

---Определяет цвет ближайшей к объекту руки
---@param object tts__Object
---@return tts__Color
function GetColorByDistance(object)
    local res

    local distance = 999
    for _,hand in pairs(Hands.getHands()) do
        local newDistance = Vector.distance(object.getPosition(), hand.getPosition())
        if newDistance < distance then
            distance = newDistance
            res = hand.getValue()
        end
    end

    return res
end

---Возвращает следующего игрока
---@param list tts__PlayerColor[] порядок хода игроков, цветами
---@param color tts__PlayerColor следующего после этого цвета
---@return tts__PlayerColor
function NextPlayer(list, color)
    list = Choose(list, list, Turns.order)
    color = Choose(color, color, Turns.turn_color)

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
---@return tts__PlayerColor[]
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

---Возвращает игроков кроме ГМ'а и зрителей
---@return tts__PlayerColor[]
function GetTruePlayers()
    local colors = {}
    for _,player in ipairs(Player.getPlayers()) do
        if player.color ~='Black' and player.color ~='Grey' then
            table.insert(colors, player.color)
        end
    end
    return colors
end

---Возвращает игрока по цвету
---@param color tts__PlayerColor
---@return tts__Player|nil
function GetPlayerByColor(color)
    local players = Player.getPlayers()
    for _,player in ipairs(players) do
        if player.color == color then
            return player
        end
    end
    return nil
end

---Руки заданного цвета
---@param color tts__Color
function PlayerHands(color)
    local res = {}
    for _,hand in ipairs(Hands.getHands()) do
        if hand.getValue() == color then
            table.insert(res, hand)
        end
    end
    return res
end

---Определяет порядок хода по расположению рук по часовой стрелке
---@return string[] цвета
function TurnOrder()
    local res = {}

    -- выясняем угол отклонения для каждой руки
    local resUnsorted = {}
    local middle = MiddlePoint()
    for _,hand in ipairs(Hands.getHands()) do
        local color = hand.getValue()
        local direction = hand.getPosition() - middle
        local angle
        if direction.z == 0 then
            angle = Choose(direction.x > 0, 90, 270)
        else
            angle = math.atan(direction.x / direction.z)
            angle = math.deg(angle)
            local sector = Sector(direction.x, direction.z)
            if     sector == 1 then
            elseif sector == 2 then
                angle = angle + 180
            elseif sector == 3 then
                angle = angle + 180
            elseif sector == 4 then
                angle = angle + 360
            end
        end
        local index = math.floor(angle * 100)
        resUnsorted[index] = color
    end

    -- упорядочиваем руки по возрастанию угла
    local keys = Keys(resUnsorted)
    table.sort(keys)
    for _,i in ipairs(keys) do
        table.insert(res, resUnsorted[i])
    end

    return res
end

---Находит середину стола
---@return tts__Vector
function MiddlePoint()
    local res = Vector(0,0,0)
    for _,hand in ipairs(Hands.getHands()) do
        res = res + hand.getPosition()
    end
    return res * (1 / #Hands.getHands())
end

--#endregion Player

---Отправляет лог на web-форму
function SendStartLog()

    local function PlayerDescription(player)
        if not player then
            return '-'
        end

        local res = string.format('%s https://steamcommunity.com/profiles/%s', player.steam_name, player.steam_id)
        return res
    end

    -- Выясняем хоста
    local host
    for _,player in ipairs(Player.getPlayers()) do
        if player.host then
            host = player
            break
        end
    end

    -- Выясняем других игроков и зрителей
    local players = {}
    for _,player in ipairs(Player.getPlayers()) do
        if not player.host then
            table.insert(players, player)
        end
    end
    table.sort(players, function (a, b) return (a.steam_name < b.steam_name) end)
    local playersDescriptions = {}
    for _,player in ipairs(players) do
        table.insert(playersDescriptions, PlayerDescription(player))
    end
    local playersTotal = table.concat(playersDescriptions, '\n')

    -- Отправляем
    local infoTable = {
        ['entry.866993041'] = PlayerDescription(host),-- Хост
        ['entry.2082571243'] = Info.name, -- Игра
        ['entry.1561105720'] = playersTotal -- Игроки
    }

    local url = 'https://docs.google.com/forms/d/e/1FAIpQLSceeSmVFufBIO6IWTxIEFXYAWvfpvk8Oi4ptSYqIVOuiT-kdw/formResponse'

    WebRequest.post(url, infoTable)

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

---Делает из списка гуидов список объектов
---@param guids string[] Список гуидов
function ObjectsFromGUIDS(guids)
    local res = {}
    for i,guid in ipairs(guids) do
        local obj = getObjectFromGUID(guid)
        table.insert(res, i, obj)
    end
    return res
end

---Делает из списка объектов список гуидов
---@param objects tts__Object[] Список объектов
function ObjectsGUIDS(objects)
    local res = {}
    for i,obj in ipairs(objects) do
        local obj = obj.guid
        table.insert(res, i, obj)
    end
    return res
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

---Проверяет что объект лежит в открытую
---@param obj tts__Object
---@return boolean
function IsFaceUp(obj)
    local curr = obj.getRotation()
    local res = InVicinity(curr.z, 0, 1)
    return res
end

---Проверяет что объект лежит в закрытую
---@param obj tts__Object
---@return boolean
function IsFaceDown(obj)
    return not IsFaceUp(obj)
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

---Логирует все переданные значения по очереди
---@param ... any[]
function Log(...)
    for _,val in pairs({...}) do
        log(val)
    end
end

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

---Располагает объекты по кругу вокруг точки
---@param objectList tts__Object[]
---@param radius number
---@param optionalParams table
    -- startAngle number стартовый угол
    -- center tts__Vector
    -- y number
    -- additionalRotate number
function ArrangeInCircle(objectList, radius, optionalParams)
    if not optionalParams then
        optionalParams = {}
    end

    local startAngle = First(optionalParams.startAngle, 0)
    local center = First(optionalParams.center, Vector(0,0,0))
    local y = First(optionalParams.y, objectList[1].getPosition().y)
    local additionalRotate = First(optionalParams.additionalRotate, 0)

    local angleStep = 360 / #objectList
    local angle = startAngle
    for _,obj in ipairs(objectList) do
        local z = math.cos(math.rad(angle)) * radius + center.z
        local x = math.sin(math.rad(angle)) * radius + center.x
        obj.setPositionSmooth(Vector(x, y, z))
        obj.setRotationSmooth(Vector(0, angle + additionalRotate, 0))
        angle = angle + angleStep
    end
end

---Удаляет лишние руки
function DestructExtraHands()

    local colors = {}
    for _,player in ipairs(Player.getPlayers()) do
        table.insert(colors, player.color)
    end

    local toDelete = {}
    for _,hand in ipairs(Hands.getHands()) do
        if not ValueIsInTable(hand.getValue(), colors) then
            table.insert(toDelete, hand)
        end
    end

    while #toDelete > 0 do
        toDelete[#toDelete].destruct()
        toDelete[#toDelete] = nil
    end
end

function SetAllInteractable()
    for _,obj in ipairs(getObjects()) do
        obj.interactable = true
    end
end

function HasAnyTagFrom(object, tags)
    for _,tag in ipairs(tags) do
        if object.hasTag(tag) then
            return true
        end
    end
    return false
end

---Устанавливает кулдаун на нажатие кнопки или другое событие
---@param list string[] массив для названий кулдаунов
---@param name string имя кулдауна
function SetOnCooldown(list, name)
    local result = IsOnCooldown(list, name)
    list[name] = true
    Wait.time(function() list[name] = nil end, 0.3)
    return result
end

---Проверяет установлен ли кулдаун
---@param list string[]
---@param name string
---@return boolean
function IsOnCooldown(list, name)
    return list[name]
end

--#endregion TTS

--#region Math

---Выясняет находится ли значение в окрестности
---@param value number значение
---@param target number цель
---@param fault number погрешность
---@return boolean
function InVicinity(value, target, fault)
    local fault = First(fault, 1)
    local res = (target - fault < value) and (value < target + fault)
    return res
end

---Возвращается сектор окружности по координатам
---@param x number
---@param y number
---@return integer|nil
function Sector(x, y)
    local res
    if     x >= 0 and y >= 0 then
        res = 1
    elseif x >= 0 and y < 0 then
        res = 2
    elseif x < 0 and y < 0 then
        res = 3
    elseif x < 0 and y >= 0 then
        res = 4
    end
    return res
end

--#endregion Math

--#region Move

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

---Перемещает объект на новые координаты плавно
---@param obj tts__Object|nil
---@param coords table можно задать любые из координат, например {x=10, y=-2}
function MoveSmooth(obj, coords)
    if not obj then
        return
    end
    local pos = obj.getPosition()
    local newX = First(coords.x, pos.x)
    local newY = First(coords.y, pos.y)
    local newZ = First(coords.z, pos.z)
    obj.setPositionSmooth({newX, newY, newZ})
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

--#endregion Move

--#region Table

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

---Возвращает ключи таблицы
---@param tab table
---@return table
function Keys(tab)
    local res = {}
    for k,_ in pairs(tab) do
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
    for k,v in pairs(tab) do
        if v == val then
            return k
        end
    end
    return nil
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
    return tab
end

function ShuffledList(list)
    for i = #list, 2, -1 do
        local j = math.random(i)
        list[i], list[j] = list[j], list[i]
    end
    return list
end

function RemoveValueFromList(list, val)
    for i,v in ipairs(list) do
        if v == val then
            table.remove(list, i)
        end
    end
    return list
end

function AppendList(listTo, listFrom)
    for _,val in ipairs(listFrom) do
        table.insert(listTo, val)
    end
    return listTo
end

function CopyTable(tab)
    local res = {}
    for k,v in pairs(tab) do
        res[k] = v
    end
    return res
end

function KeyByValue(tab, value)
    for k,v in pairs(tab) do
        if v == value then
            return k
        end
    end
    return nil
end

--#endregion Table

--#region String

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

--#endregion String

--#region Other

---Проверяет что все объекты в таблице инициализированы
---@param tab table
function TestObjectsInit(tab)
    for name,obj in pairs(tab) do
        if not obj then
            print("Object '" .. name .. "' isn't initialized")
        end
    end
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

--#endregion Other




---Возвращает соответствие мест и находящихся на них объектов
--[[function ObjectsOnPlaces(objects, places)
    local objectsByPlaces, placesByObjects = {}, {}

    for _,sec in pairs(places) do
        objectsByPlaces[sec] = {}
    end

    for _,obj in ipairs(objects) do
        if MovableObject(obj) then
            local n = obj.getName()
            local hitlist = Physics.cast({
                origin = obj.getPosition()+Vector(0, 0.5, 0),
                direction = Vector(0, -1, 0),
                type = 1,
                max_distance = 2,
                debug = false,
            })

            local sector = ObjectIsOnSector(hitlist)
            if sector then
                table.insert(objectsByPlaces[sector], obj)
                placesByObjects[obj] = sector
            end
        end
    end

    return objectsByPlaces, placesByObjects
end]]
