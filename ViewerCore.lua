local addonName, SlerneNotesViewer = ...
_G.SlerneNotesViewer = SlerneNotesViewer

SlerneNotesViewer.ClassColors = {
    ["DEATHKNIGHT"] = {r=0.77, g=0.12, b=0.23}, ["DEMONHUNTER"] = {r=0.64, g=0.19, b=0.79},
    ["DRUID"]       = {r=1.00, g=0.49, b=0.04}, ["EVOKER"]      = {r=0.20, g=0.58, b=0.50},
    ["HUNTER"]      = {r=0.67, g=0.83, b=0.45}, ["MAGE"]        = {r=0.25, g=0.78, b=0.92},
    ["MONK"]        = {r=0.00, g=1.00, b=0.60}, ["PALADIN"]     = {r=0.96, g=0.55, b=0.73},
    ["PRIEST"]      = {r=1.00, g=1.00, b=1.00}, ["ROGUE"]       = {r=1.00, g=0.96, b=0.41},
    ["SHAMAN"]      = {r=0.00, g=0.44, b=0.87}, ["WARLOCK"]     = {r=0.53, g=0.53, b=0.93},
    ["WARRIOR"]     = {r=0.78, g=0.61, b=0.43},
}

function SlerneNotesViewer.GetClassHex(classToken)
    local c = classToken and SlerneNotesViewer.ClassColors[classToken]
    if c then return string.format("%02x%02x%02x", math.floor(c.r*255), math.floor(c.g*255), math.floor(c.b*255)) end
    return "ffffff"
end

local function Unescape(str)
    if not str then return "" end
    str = string.gsub(str, "%%n", "\n")
    str = string.gsub(str, "%%e", "=")
    str = string.gsub(str, "%%c", ":")
    str = string.gsub(str, "%%s", ";")
    str = string.gsub(str, "%%p", "%%")
    return str
end

function SlerneNotesViewer.ParseImportString(str)
    local layout = {}
    local classMap = {}
    local roleMap = {}
    local modules = {strsplit(";", str)}
    
    for _, modStr in ipairs(modules) do
        if modStr and modStr ~= "" then
            -- Updated to include mPosX and mPosY at the end of the split
            local modName, mType, mLen, mImg, mImgW, mImgH, mText, mLabels, mPlayers, mClasses, mRoles, mPosX, mPosY = strsplit(":", modStr)
            modName = Unescape(modName)
            
            local meta = {
                type = Unescape(mType), length = tonumber(Unescape(mLen)) or 0,
                image = Unescape(mImg), imgW = tonumber(Unescape(mImgW)) or 400,
                imgH = tonumber(Unescape(mImgH)) or 300, text = Unescape(mText),
                posX = tonumber(Unescape(mPosX)), -- Extract shared X position
                posY = tonumber(Unescape(mPosY)), -- Extract shared Y position
                labels = {}
            }
            
            if mLabels and mLabels ~= "" then
                for _, lbl in ipairs({strsplit(",", mLabels)}) do
                    local k, v = strsplit("=", lbl)
                    meta.labels[tonumber(Unescape(k)) or Unescape(k)] = Unescape(v)
                end
            end

            local players = {}
            if mPlayers and mPlayers ~= "" then
                for _, ply in ipairs({strsplit(",", mPlayers)}) do
                    local k, v = strsplit("=", ply)
                    local key = Unescape(k)
                    local val = Unescape(v)
                    key = tonumber(key) or key
                    if val == "true" then val = true end
                    players[key] = val
                end
            end
            
            if mClasses and mClasses ~= "" then
                for _, cls in ipairs({strsplit(",", mClasses)}) do
                    local name, class = strsplit("=", cls)
                    classMap[Unescape(name)] = Unescape(class)
                end
            end
            
            if mRoles and mRoles ~= "" then
                for _, rls in ipairs({strsplit(",", mRoles)}) do
                    local name, role = strsplit("=", rls)
                    roleMap[Unescape(name)] = Unescape(role)
                end
            end

            layout[modName] = { meta = meta, players = players }
        end
    end
    return layout, classMap, roleMap
end

SlerneNotesViewer.currentLayout = {}
SlerneNotesViewer.currentClasses = {}
SlerneNotesViewer.currentRoles = {}
SlerneNotesViewer.roster = {}

SlerneNotesViewer.frame = CreateFrame("Frame", "SlerneNotesViewerFrame", UIParent)

C_ChatInfo.RegisterAddonMessagePrefix("SlerneNotes")
local chunks = {}

SlerneNotesViewer.frame:RegisterEvent("ADDON_LOADED")
SlerneNotesViewer.frame:RegisterEvent("CHAT_MSG_ADDON")
SlerneNotesViewer.frame:RegisterEvent("GROUP_ROSTER_UPDATE")

local function UpdateRoster()
    wipe(SlerneNotesViewer.roster)
    local numGroup = GetNumGroupMembers()
    if numGroup == 0 then
        local name = UnitName("player")
        if name then
            local shortName = strsplit("-", name)
            local _, classToken = UnitClass("player")
            SlerneNotesViewer.roster[shortName] = classToken
        end
    else
        for i = 1, numGroup do
            local name, _, _, _, _, classToken = GetRaidRosterInfo(i)
            if name then
                local shortName = strsplit("-", name)
                SlerneNotesViewer.roster[shortName] = classToken
            end
        end
    end
end

SlerneNotesViewer.frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local arg1 = ...
        if arg1 == "Slerne_Notes_Viewer" then 
            UpdateRoster()
            print("Slerne Notes Viewer loaded. Listening for canvas broadcasts.") 
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        UpdateRoster()
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, text, channel, sender = ...
        if prefix == "SlerneNotes" then
            local msgID, chunkNum, totalChunks, data = strsplit(":", text, 4)
            msgID = tonumber(msgID)
            chunkNum = tonumber(chunkNum)
            totalChunks = tonumber(totalChunks)
            
            if not msgID or not chunkNum or not totalChunks then return end
            
            if not chunks[msgID] then chunks[msgID] = {} end
            chunks[msgID][chunkNum] = data
            
            local isComplete = true
            for i = 1, totalChunks do
                if not chunks[msgID][i] then isComplete = false; break end
            end
            
            if isComplete then
                local fullStr = ""
                for i = 1, totalChunks do
                    fullStr = fullStr .. chunks[msgID][i]
                end
                chunks[msgID] = nil 
                
                local canvasName, layoutStr = strsplit("|", fullStr, 2)
                SlerneNotesViewer.currentLayout, SlerneNotesViewer.currentClasses, SlerneNotesViewer.currentRoles = SlerneNotesViewer.ParseImportString(layoutStr)
                if SlerneNotesViewer.UpdateHeader then SlerneNotesViewer.UpdateHeader(canvasName) end
                SlerneNotesViewer.Render()
                
                if not SlerneNotesViewer.frame:IsShown() then
                    SlerneNotesViewer.frame:Show()
                end
            end
        end
    end
end)

SLASH_SLERNENOTESVIEWER1 = "/snv"
SlashCmdList["SLERNENOTESVIEWER"] = function()
    if SlerneNotesViewer.frame:IsShown() then SlerneNotesViewer.frame:Hide() else SlerneNotesViewer.frame:Show() end
end
