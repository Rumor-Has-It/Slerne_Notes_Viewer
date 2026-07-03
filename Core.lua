local addonName, SlerneNotesViewer = ...
_G.SlerneNotesViewer = SlerneNotesViewer
SlerneNotesViewerDB = SlerneNotesViewerDB or {}

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

-- Reverse of the sender's text escaping (see Core.lua EscDraw).
local function UnescDraw(s)
    s = tostring(s or "")
    s = s:gsub("%%C", ","):gsub("%%S", ";"):gsub("%%H", "#"):gsub("%%P", "%%")
    return s
end

local function HexToRGB(hex)
    hex = hex or "ffffff"
    return (tonumber(hex:sub(1, 2), 16) or 255) / 255,
        (tonumber(hex:sub(3, 4), 16) or 255) / 255,
        (tonumber(hex:sub(5, 6), 16) or 255) / 255
end

-- Deserialize the drawings section sent alongside the layout.
function SlerneNotesViewer.ParseDrawings(str)
    local drawings = { strokes = {}, markers = {}, texts = {}, shapes = {}, lines = {} }
    if not str or str == "" then return drawings end
    local strokesPart, markersPart, textsPart, shapesPart, linesPart = strsplit("#", str, 5)

    if strokesPart and strokesPart ~= "" then
        for _, strokeStr in ipairs({ strsplit(";", strokesPart) }) do
            if strokeStr ~= "" then
                local parts = { strsplit(":", strokeStr) }
                local r, g, b = HexToRGB(parts[1])
                local points = {}
                for i = 2, #parts do
                    local xs, ys = strsplit(",", parts[i])
                    points[#points + 1] = { tonumber(xs) or 0, tonumber(ys) or 0 }
                end
                if #points >= 2 then
                    drawings.strokes[#drawings.strokes + 1] = { color = { r, g, b }, points = points }
                end
            end
        end
    end

    if markersPart and markersPart ~= "" then
        for _, markerStr in ipairs({ strsplit(";", markersPart) }) do
            if markerStr ~= "" then
                local a, b, c, d, e = strsplit(",", markerStr, 5)
                if a == "marker" or a == "role" or a == "class" then
                    -- new format: kind,icon,x,y,size
                    local icon = (a == "marker") and (tonumber(b) or 8) or b
                    drawings.markers[#drawings.markers + 1] =
                        { kind = a, icon = icon, x = tonumber(c) or 0, y = tonumber(d) or 0, size = tonumber(e) or 26 }
                else
                    -- legacy format: icon,x,y
                    drawings.markers[#drawings.markers + 1] =
                        { kind = "marker", icon = tonumber(a) or 8, x = tonumber(b) or 0, y = tonumber(c) or 0, size = 26 }
                end
            end
        end
    end

    if textsPart and textsPart ~= "" then
        for _, ts in ipairs({ strsplit(";", textsPart) }) do
            if ts ~= "" then
                local hex, x, y, size, text = strsplit(",", ts, 5)
                local r, g, b = HexToRGB(hex)
                drawings.texts[#drawings.texts + 1] =
                    { color = { r, g, b }, x = tonumber(x) or 0, y = tonumber(y) or 0,
                      size = tonumber(size) or 22, text = UnescDraw(text) }
            end
        end
    end

    if shapesPart and shapesPart ~= "" then
        for _, ss in ipairs({ strsplit(";", shapesPart) }) do
            if ss ~= "" then
                local hex, x, y, size = strsplit(",", ss)
                local r, g, b = HexToRGB(hex)
                drawings.shapes[#drawings.shapes + 1] =
                    { color = { r, g, b }, x = tonumber(x) or 0, y = tonumber(y) or 0, size = tonumber(size) or 80 }
            end
        end
    end

    if linesPart and linesPart ~= "" then
        for _, ls in ipairs({ strsplit(";", linesPart) }) do
            if ls ~= "" then
                local hex, x1, y1, x2, y2, th, arrow = strsplit(",", ls)
                local r, g, b = HexToRGB(hex)
                drawings.lines[#drawings.lines + 1] =
                    { color = { r, g, b }, x1 = tonumber(x1) or 0, y1 = tonumber(y1) or 0,
                      x2 = tonumber(x2) or 0, y2 = tonumber(y2) or 0, thickness = tonumber(th) or 3,
                      arrow = (arrow == "1") }
            end
        end
    end
    return drawings
end

SlerneNotesViewer.currentLayout = {}
SlerneNotesViewer.currentClasses = {}
SlerneNotesViewer.currentRoles = {}
SlerneNotesViewer.roster = {}

-- =======================
-- MULTI-CANVAS STORAGE
-- The viewer keeps every canvas it receives, keyed by name (new ones added,
-- existing names updated). A dropdown picks which to view. View-only.
-- =======================
function SlerneNotesViewer.GetCanvases()
    return (SlerneNotesViewerDB and SlerneNotesViewerDB.canvases) or {}
end

function SlerneNotesViewer.GetActiveCanvas()
    return SlerneNotesViewerDB and SlerneNotesViewerDB.activeCanvas
end

-- Migrate a legacy flat viewer canvas into the { pages = {...}, activePage } shape.
local function ensureViewerPages(c)
    if not c.pages then
        c.pages = { {
            layout = c.layout or {}, classes = c.classes or {}, roles = c.roles or {},
            drawings = c.drawings or { strokes = {}, markers = {}, texts = {}, shapes = {}, lines = {} },
        } }
        c.activePage = 1
        c.layout, c.classes, c.roles, c.drawings = nil, nil, nil, nil
    end
    return c.pages
end

local function applyPage(c, n)
    local pages = ensureViewerPages(c)
    n = math.max(1, math.min(#pages, n or 1))
    c.activePage = n
    local pg = pages[n] or {}
    SlerneNotesViewer.currentLayout = pg.layout or {}
    SlerneNotesViewer.currentClasses = pg.classes or {}
    SlerneNotesViewer.currentRoles = pg.roles or {}
    SlerneNotesViewer.currentDrawings = pg.drawings or { strokes = {}, markers = {}, texts = {}, shapes = {}, lines = {} }
end

-- pages = array of { layout, classes, roles, drawings } (1..N)
function SlerneNotesViewer.StoreCanvas(name, pages)
    if not name then return end
    SlerneNotesViewerDB = SlerneNotesViewerDB or {}
    SlerneNotesViewerDB.canvases = SlerneNotesViewerDB.canvases or {}
    pages = pages or { { layout = {}, classes = {}, roles = {}, drawings = { strokes = {}, markers = {}, texts = {}, shapes = {}, lines = {} } } }
    -- Keep the reader on their current page across a re-broadcast if it still exists.
    local prev = SlerneNotesViewerDB.canvases[name]
    local keepPage = (prev and prev.activePage and prev.activePage <= #pages) and prev.activePage or 1
    SlerneNotesViewerDB.canvases[name] = { pages = pages, activePage = keepPage }
end

function SlerneNotesViewer.GetPageCount(name)
    name = name or SlerneNotesViewer.GetActiveCanvas()
    local c = name and SlerneNotesViewer.GetCanvases()[name]
    if not c then return 0 end
    return #ensureViewerPages(c)
end

function SlerneNotesViewer.GetActivePage()
    local name = SlerneNotesViewer.GetActiveCanvas()
    local c = name and SlerneNotesViewer.GetCanvases()[name]
    return (c and c.activePage) or 1
end

function SlerneNotesViewer.SetActivePage(n)
    local name = SlerneNotesViewer.GetActiveCanvas()
    local c = name and SlerneNotesViewer.GetCanvases()[name]
    if not c then return end
    applyPage(c, n)
    if SlerneNotesViewer.Render then SlerneNotesViewer.Render() end
    if SlerneNotesViewer.RefreshPageTabs then SlerneNotesViewer.RefreshPageTabs() end
end

function SlerneNotesViewer.SetActiveCanvas(name)
    local c = SlerneNotesViewer.GetCanvases()[name]
    if not c then return end
    SlerneNotesViewerDB.activeCanvas = name
    applyPage(c, c.activePage or 1)
    if SlerneNotesViewer.UpdateHeader then SlerneNotesViewer.UpdateHeader(name) end
    -- Render BEFORE the page tabs so the canvas always draws even if a page-tab
    -- refresh ever hiccups.
    if SlerneNotesViewer.Render then SlerneNotesViewer.Render() end
    if SlerneNotesViewer.RefreshPageTabs then SlerneNotesViewer.RefreshPageTabs() end
end

function SlerneNotesViewer.DeleteCanvas(name)
    if SlerneNotesViewerDB and SlerneNotesViewerDB.canvases then
        SlerneNotesViewerDB.canvases[name] = nil
        if SlerneNotesViewerDB.activeCanvas == name then
            SlerneNotesViewerDB.activeCanvas = next(SlerneNotesViewerDB.canvases)
        end
    end
end

-- Delete the currently-viewed canvas, then show whatever remains (or clear).
function SlerneNotesViewer.DeleteActiveCanvas()
    local active = SlerneNotesViewer.GetActiveCanvas()
    if not active then return end
    SlerneNotesViewer.DeleteCanvas(active)
    local newActive = SlerneNotesViewer.GetActiveCanvas()
    if newActive then
        SlerneNotesViewer.SetActiveCanvas(newActive)
    else
        SlerneNotesViewer.currentLayout = {}
        SlerneNotesViewer.currentClasses = {}
        SlerneNotesViewer.currentRoles = {}
        SlerneNotesViewer.currentDrawings = { strokes = {}, markers = {}, texts = {}, shapes = {}, lines = {} }
        if SlerneNotesViewer.UpdateHeader then SlerneNotesViewer.UpdateHeader() end
        if SlerneNotesViewer.RefreshPageTabs then SlerneNotesViewer.RefreshPageTabs() end
        if SlerneNotesViewer.Render then SlerneNotesViewer.Render() end
    end
end

SlerneNotesViewer.frame = CreateFrame("Frame", "SlerneNotesViewerFrame", UIParent)

C_ChatInfo.RegisterAddonMessagePrefix("SlerneNotes")
local chunks = {}
local chunkTime = {}  -- msgID -> last chunk time, for purging stalled transfers

-- Big multi-page canvases now arrive throttled (over several seconds). If a chunk
-- is ever lost mid-transfer, the partial set would linger forever -- purge any
-- incomplete message that hasn't received a new chunk in a while.
C_Timer.NewTicker(20, function()
    local now = GetTime()
    for id, t in pairs(chunkTime) do
        if now - t > 60 then chunks[id] = nil; chunkTime[id] = nil end
    end
end)

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
        if arg1 == "SlerneNotesViewer" then
            SlerneNotesViewerDB = SlerneNotesViewerDB or {}
            SlerneNotesViewerDB.canvases = SlerneNotesViewerDB.canvases or {}
            -- Saved theme is only available now -> apply it to skinned frames.
            if SlerneNotesViewer.Skin and SlerneNotesViewer.Skin.RefreshTheme then
                SlerneNotesViewer.Skin.RefreshTheme()
            end
            UpdateRoster()
            -- Restore the last viewed canvas (or any stored one) on login
            local active = SlerneNotesViewerDB.activeCanvas
            if not (active and SlerneNotesViewerDB.canvases[active]) then
                active = next(SlerneNotesViewerDB.canvases)
            end
            if active then SlerneNotesViewer.SetActiveCanvas(active) end
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
            chunkTime[msgID] = GetTime()

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
                chunkTime[msgID] = nil

                local parts = { strsplit("|", fullStr) }
                local canvasName = (parts[1] and parts[1] ~= "") and parts[1] or "Canvas"

                -- New format: name | pageCount | L1 | D1 | L2 | D2 | ...
                -- Legacy:     name | layout | drawings  (treated as a single page)
                local pages = {}
                local pageCount = tonumber(parts[2])
                if pageCount and pageCount >= 1 and #parts >= 2 + 2 * pageCount then
                    for p = 1, pageCount do
                        local layoutStr = parts[2 + (p - 1) * 2 + 1] or ""
                        local drawingsStr = parts[2 + (p - 1) * 2 + 2] or ""
                        local layout, classes, roles = SlerneNotesViewer.ParseImportString(layoutStr)
                        pages[p] = {
                            layout = layout, classes = classes, roles = roles,
                            drawings = SlerneNotesViewer.ParseDrawings(drawingsStr),
                        }
                    end
                else
                    local layout, classes, roles = SlerneNotesViewer.ParseImportString(parts[2] or "")
                    pages[1] = {
                        layout = layout, classes = classes, roles = roles,
                        drawings = SlerneNotesViewer.ParseDrawings(parts[3] or ""),
                    }
                end

                -- Save/update this canvas under its name, then view it
                SlerneNotesViewer.StoreCanvas(canvasName, pages)
                SlerneNotesViewer.SetActiveCanvas(canvasName)

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