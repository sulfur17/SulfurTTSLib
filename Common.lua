
--#region Const
FRAMES_TO_SHUFFLE = 40
FRAMES_TO_ROTATION = 1
--#endregion

--#region API

---Move object to new coordinate
---@param obj tts__Object|nil
---@param coords table
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

---Test if all objects initialized
---@param table table
function TestObjectsInit(table)
    for name,obj in pairs(table) do
        if not obj then
            print("Object '" .. name .. "' isn't initialized")
        end
    end
end

function GetDeckCardFromZone(zone, tag)
    local deck, card
    for _,obj in pairs(zone.getObjects()) do

        local continue = false
        if tag then
            continue = not obj.hasTag(tag)
        end

        if not continue then
            if obj.type == 'Deck' then
                deck = obj
            elseif obj.type == 'Card' then
                card = obj
            end
        end

    end
    return deck, card
end

function LoadedState(script_state)
    local state, loaded
    if script_state == '' then
        state = ''
        loaded = false
    else
        state = JSON.decode(script_state)
        loaded = true
    end
    return state, loaded
end

---Returns first not-nil value
---@param ... table
---@return any
function First(...)
    local params = {...}
    for i,val in pairs(params) do
        if val then
            return val
        end
    end
    return nil
end


function Choose(expression, onTrue, onFalse)
    if expression then
        return onTrue
    else
        return onFalse
    end
end

function SetFaceUp(obj)
    local curr = obj.getRotation()
    obj.setRotation({curr.x, curr.y, 0})
end

function SetFaceUpSmooth(obj)
    local curr = obj.getRotation()
    obj.setRotationSmooth({curr.x, curr.y, 0})
end

function SetFaceDown(obj)
    local curr = obj.getRotation()
    obj.setRotation({curr.x, curr.y, 180})
end

function SetFaceDownSmooth(obj)
    local curr = obj.getRotation()
    obj.setRotationSmooth({curr.x, curr.y, 180})
end

---Returns table keys
---@param tab table
---@return table table
function Keys(tab)
    local res = {}
    for k,v in pairs(tab) do
        table.insert(res, k)
    end
    return res
end

---Returns table values
---@param tab table
---@return table table
function Values(tab)
    local res = {}
    for k,v in pairs(tab) do
        table.insert(res, v)
    end
    return res
end

function KeyIsInTable(key, tab)
    return (tab[key] ~= nil)
end

function ValueIsInTable(val, tab)
    for _,v in pairs(tab) do
        if v == val then
            return true
        end
    end
    return false
end

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

function ShuffleAsync(deck, callback)

    deck.shuffle()

    if callback then
        Wait.frames(callback, FRAMES_TO_SHUFFLE)
    end
end

function SetFaceDownAsync(obj, callback)
    SetFaceDown(obj)

    if callback then
        Wait.frames(callback, FRAMES_TO_ROTATION)
    end
end

function SetFaceUpAsync(obj, callback)
    SetFaceUp(obj)

    if callback then
        Wait.frames(callback, FRAMES_TO_ROTATION)
    end
end

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

function Log(...)
    for _,val in pairs({...}) do
        log(val)
    end
end

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