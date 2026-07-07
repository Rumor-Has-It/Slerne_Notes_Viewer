local addonName, SlerneNotesViewer = ...

local PREFIX = "SlerneLoot"
C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)

local SLOTS = { 1, 2, 3, 15, 5, 9, 10, 6, 7, 8, 11, 12, 13, 14, 16, 17 }

local function BuildGearString()
    local parts = {}
    for _, slot in ipairs(SLOTS) do
        local loc = ItemLocation:CreateFromEquipmentSlot(slot)
        if loc and C_Item.DoesItemExist(loc) then
            local id = C_Item.GetItemID(loc)
            local ilvl = C_Item.GetCurrentItemLevel(loc) or 0
            if id then
                parts[#parts + 1] = slot .. "," .. id .. "," .. ilvl
            end
        end
    end
    return table.concat(parts, ";")
end

local function Broadcast()
    local channel, target
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        channel = "INSTANCE_CHAT"
    elseif IsInRaid() then
        channel = "RAID"
    elseif IsInGroup() then
        channel = "PARTY"
    else
        channel, target = "WHISPER", UnitName("player")
    end
    C_ChatInfo.SendAddonMessage(PREFIX, "GEAR\t" .. BuildGearString(), channel, target)
end

local pending
local function QueueBroadcast(delay)
    if pending then pending:Cancel() end
    pending = C_Timer.NewTimer(delay or 2, function() pending = nil; Broadcast() end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
f:RegisterEvent("CHAT_MSG_ADDON")
f:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, msg = ...
        if prefix == PREFIX and msg == "REQ" then

            QueueBroadcast(0.2 + math.random() * 1.5)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        QueueBroadcast(3)
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        QueueBroadcast(2)
    end
end)
