local addonName, SlerneNotesViewer = ...
local modPool = {}

local function Clear(f)
    if not f then return end
    for _, c in ipairs({f:GetChildren()}) do c:Hide() end
end

local function GetImagePath(imgName)
    if not imgName or imgName == "" then return "" end

    if string.find(imgName, "[\\/]") then
        return "Interface\\AddOns\\SlerneNotesViewer\\img\\maps\\base\\" .. imgName
    end
    return "Interface\\AddOns\\SlerneNotesViewer\\img\\maps\\custom\\" .. imgName
end

local function GetIconPath(iconName)
    return "Interface\\AddOns\\SlerneNotesViewer\\img\\icons\\" .. iconName .. ".tga"
end

local measureFS
local function MaxLineWidth(text)
    if not measureFS then
        measureFS = UIParent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        measureFS:Hide()
    end
    local maxw = 0
    for line in (tostring(text or "") .. "\n"):gmatch("([^\n]*)\n") do
        measureFS:SetText(line)
        local w = measureFS:GetStringWidth() or 0
        if w > maxw then maxw = w end
    end
    return maxw
end

local function GetMyName()
    local name = UnitName("player")
    if name then

        local shortName = strsplit("-", name)
        return shortName
    end
    return ""
end

local drawLayer = CreateFrame("Frame", nil, SlerneNotesViewer.canvasPanel)
drawLayer:SetAllPoints(SlerneNotesViewer.canvasPanel)
drawLayer:SetFrameLevel(SlerneNotesViewer.canvasPanel:GetFrameLevel() + 50)

local linePool, markerPool, textPool, circlePool = {}, {}, {}, {}
local lineObjPool = {}
local DRAW_FONT = select(1, GameFontNormal:GetFont())
local DRAW_CIRCLE_MASK = "Interface\\Masks\\CircleMaskScalable"

function SlerneNotesViewer.RenderDrawings(drawings)

    drawLayer:Show()
    for _, l in ipairs(linePool) do l:Hide() end
    for _, m in ipairs(markerPool) do m:Hide() end
    for _, t in ipairs(textPool) do t:Hide() end
    for _, c in ipairs(circlePool) do c:Hide() end
    for _, o in ipairs(lineObjPool) do o.main:Hide(); o.head:Hide() end
    if not drawings then return end

    local used = 0
    for _, stroke in ipairs(drawings.strokes or {}) do
        local pts = stroke.points or {}
        local c = stroke.color or { 1, 1, 1 }
        for i = 2, #pts do
            used = used + 1
            local l = linePool[used]
            if not l then l = drawLayer:CreateLine(nil, "ARTWORK"); linePool[used] = l end
            l:SetThickness(3)
            l:SetColorTexture(c[1], c[2], c[3], 1)
            l:SetStartPoint("TOPLEFT", drawLayer, pts[i - 1][1], pts[i - 1][2])
            l:SetEndPoint("TOPLEFT", drawLayer, pts[i][1], pts[i][2])
            l:Show()
        end
    end

    for idx, mk in ipairs(drawings.markers or {}) do
        local m = markerPool[idx]
        if not m then
            m = CreateFrame("Frame", nil, drawLayer)
            m.tex = m:CreateTexture(nil, "OVERLAY")
            m.tex:SetAllPoints()
            if m.tex.SetSnapToPixelGrid then m.tex:SetSnapToPixelGrid(false) end
            if m.tex.SetTexelSnappingBias then m.tex:SetTexelSnappingBias(0) end
            markerPool[idx] = m
        end
        m:SetSize(mk.size or 26, mk.size or 26)
        if mk.kind == "role" then
            m.tex:SetTexture("Interface\\AddOns\\SlerneNotesViewer\\img\\icons\\" .. tostring(mk.icon) .. ".tga")
            m.tex:SetTexCoord(0, 1, 0, 1)
        elseif mk.kind == "class" then
            m.tex:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
            local t = CLASS_ICON_TCOORDS[mk.icon]
            if t then m.tex:SetTexCoord(t[1], t[2], t[3], t[4]) else m.tex:SetTexCoord(0, 1, 0, 1) end
        elseif mk.kind == "flag" then
            m.tex:SetTexture("Interface\\AddOns\\SlerneNotesViewer\\img\\icons\\flag.tga")
            m.tex:SetTexCoord(0, 1, 0, 1)
        elseif mk.kind == "fight" then
            m.tex:SetTexture("Interface\\AddOns\\SlerneNotesViewer\\img\\fights\\" .. tostring(mk.icon) .. ".tga")
            m.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        elseif mk.kind == "bossicon" then

            m.tex:SetTexture("Interface\\AddOns\\SlerneNotesViewer\\img\\maps\\base\\" .. tostring(mk.icon))
            m.tex:SetTexCoord(0, 1, 0, 1)
        else
            m.tex:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. tostring(mk.icon or 8))
            m.tex:SetTexCoord(0, 1, 0, 1)
        end
        m:ClearAllPoints()
        m:SetPoint("CENTER", drawLayer, "TOPLEFT", mk.x or 0, mk.y or 0)
        m:Show()
    end

    for idx, sh in ipairs(drawings.shapes or {}) do
        local f = circlePool[idx]
        if not f then
            f = CreateFrame("Frame", nil, drawLayer)
            f.fill = f:CreateTexture(nil, "ARTWORK")
            f.fill:SetAllPoints()
            local mask = f:CreateMaskTexture()
            mask:SetAllPoints(f.fill)
            mask:SetTexture(DRAW_CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            f.fill:AddMaskTexture(mask)
            circlePool[idx] = f
        end
        local c = sh.color or { 1, 1, 1 }
        f.fill:SetColorTexture(c[1], c[2], c[3], 0.30)
        f:SetSize(sh.size or 80, sh.size or 80)
        f:ClearAllPoints()
        f:SetPoint("CENTER", drawLayer, "TOPLEFT", sh.x or 0, sh.y or 0)
        f:Show()
    end

    for idx, ln in ipairs(drawings.lines or {}) do
        local o = lineObjPool[idx]
        if not o then
            o = { main = drawLayer:CreateLine(nil, "ARTWORK"),
                  head = drawLayer:CreateTexture(nil, "ARTWORK") }
            o.head:SetTexture("Interface\\Buttons\\WHITE8x8")
            o.head:SetSize(1, 1)
            o.head:SetPoint("TOPLEFT", drawLayer, "TOPLEFT", 0, 0)
            lineObjPool[idx] = o
        end
        local c = ln.color or { 1, 1, 1 }
        local th = ln.thickness or 3
        local x1, y1, x2, y2 = ln.x1 or 0, ln.y1 or 0, ln.x2 or 0, ln.y2 or 0
        o.main:SetThickness(th); o.main:SetColorTexture(c[1], c[2], c[3], 1)
        o.main:SetStartPoint("TOPLEFT", drawLayer, x1, y1)
        o.main:Show()
        if ln.arrow then
            local dx, dy = x2 - x1, y2 - y1
            local len = math.sqrt(dx * dx + dy * dy)
            if len < 1 then len = 1 end
            local ux, uy = dx / len, dy / len
            local hl = math.min(len * 0.5, math.max(14, th * 3.2))
            local hw = math.max(7, th * 1.6)
            local bx, by = x2 - ux * hl, y2 - uy * hl
            local px, py = -uy, ux
            o.main:SetEndPoint("TOPLEFT", drawLayer, bx + ux, by + uy)
            o.head:SetVertexColor(c[1], c[2], c[3], 1)
            o.head:SetVertexOffset(1, bx + px * hw, by + py * hw)
            o.head:SetVertexOffset(2, bx - px * hw, by - py * hw + 1)
            o.head:SetVertexOffset(3, x2 - 1, y2)
            o.head:SetVertexOffset(4, x2 - 1, y2 + 1)
            o.head:Show()
        else
            o.main:SetEndPoint("TOPLEFT", drawLayer, x2, y2)
            o.head:Hide()
        end
    end

    for idx, t in ipairs(drawings.texts or {}) do
        local fs = textPool[idx]
        if not fs then
            fs = drawLayer:CreateFontString(nil, "OVERLAY")
            fs:SetJustifyH("LEFT")
            textPool[idx] = fs
        end
        fs:SetFont(DRAW_FONT, t.size or 22, "OUTLINE")
        local c = t.color or { 1, 1, 1 }
        fs:SetText(t.text or "")
        fs:SetTextColor(c[1], c[2], c[3], 1)
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", drawLayer, "TOPLEFT", t.x or 0, t.y or 0)
        fs:Show()
    end
end

function SlerneNotesViewer.Render()
    local canvas = SlerneNotesViewer.canvasPanel
    if not canvas then return end

    Clear(canvas)
    local index = 0
    local myName = GetMyName()

    for modName, modData in pairs(SlerneNotesViewer.currentLayout) do
        index = index + 1
        local meta = modData.meta
        local players = modData.players

        local modFrame = modPool[index]
        if not modFrame then
            modFrame = CreateFrame("Frame", nil, canvas, "BackdropTemplate")
            SlerneNotesViewer.Skin.Module(modFrame)

            modFrame.title = modFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            modFrame.title:SetPoint("TOP", 0, -5)
            SlerneNotesViewer.Skin.Title(modFrame.title)
            modFrame.displayImage = modFrame:CreateTexture(nil, "ARTWORK")
            modFrame.playerTexts = {}
            modFrame.listRows = {}
            modFrame.actionRows = {}
            modPool[index] = modFrame
        end

        for _, pt in ipairs(modFrame.playerTexts) do pt:Hide(); if pt.highlight then pt.highlight:Hide() end end
        for _, row in ipairs(modFrame.listRows) do row:Hide(); if row.highlight then row.highlight:Hide() end end
        for _, row in ipairs(modFrame.actionRows) do row:Hide() end
        modFrame.displayImage:Hide()
        if modFrame.textFS then modFrame.textFS:Hide() end

        modFrame.title:SetText(modName)

        local titleWidth = modFrame.title:GetStringWidth() + 45

        if meta.type == "Assignment" then

            local roleWeights = { tank = 1, healer = 2, melee = 3, ranged = 4 }
            local sortedPlayers = {}
            for player in pairs(players) do
                table.insert(sortedPlayers, player)
            end

            table.sort(sortedPlayers, function(a, b)
                local roleA = SlerneNotesViewer.currentRoles[a]
                local roleB = SlerneNotesViewer.currentRoles[b]
                local weightA = roleWeights[roleA] or 5
                local weightB = roleWeights[roleB] or 5

                if weightA == weightB then
                    return a < b
                end
                return weightA < weightB
            end)

            local boxW = math.max(180, titleWidth)
            local pCount = #sortedPlayers

            local blockW = 0
            for i, player in ipairs(sortedPlayers) do
                local f = modFrame.playerTexts[i]
                if not f then
                    f = CreateFrame("Frame", nil, modFrame)
                    f:SetSize(160, 15)

                    f.fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")

                    f.icon = f:CreateTexture(nil, "ARTWORK")
                    f.icon:SetSize(17, 17)
                    f.icon:SetPoint("RIGHT", f.fs, "LEFT", -4, 0)

                    f.highlight = f:CreateTexture(nil, "BACKGROUND")
                    f.highlight:SetColorTexture(1, 0.8, 0.2, 0.20)

                    modFrame.playerTexts[i] = f
                end

                f.fs:SetText(player)
                f.fs:ClearAllPoints()
                f.fs:SetPoint("LEFT", 18, 0)

                local classToken = SlerneNotesViewer.currentClasses[player]
                if classToken and SlerneNotesViewer.ClassColors[classToken] then
                    local c = SlerneNotesViewer.ClassColors[classToken]
                    f.fs:SetTextColor(c.r, c.g, c.b, 1)
                else
                    f.fs:SetTextColor(0.8, 0.8, 0.8, 1)
                end

                local role = SlerneNotesViewer.currentRoles[player]
                f.highlight:ClearAllPoints()
                if role then
                    f.icon:SetTexture(GetIconPath(role))
                    f.icon:Show()
                    f.highlight:SetPoint("TOPLEFT", f.icon, "TOPLEFT", -4, 2)
                else
                    f.icon:Hide()
                    f.highlight:SetPoint("TOPLEFT", f.fs, "TOPLEFT", -4, 2)
                end
                f.highlight:SetPoint("BOTTOMRIGHT", f.fs, "BOTTOMRIGHT", 4, -2)

                if player == myName then f.highlight:Show() else f.highlight:Hide() end
                f:Show()

                local w = (f.fs:GetStringWidth() or 0) + 18
                if w > blockW then blockW = w end
            end

            local frameX = math.max(7, (boxW - blockW) / 2)
            for i = 1, pCount do
                modFrame.playerTexts[i]:SetPoint("TOPLEFT", frameX, -20 - (i*15))
            end
            modFrame:SetSize(boxW, math.max(60, 40 + (pCount * 15)))

        elseif meta.type == "List" or meta.type == "Image List" or meta.type == "Image" then
            local rowHeight, listWidth = 25, math.max(220, titleWidth)
            local totalWidth = listWidth
            local minHeight = 40 + ((meta.length or 0) * rowHeight)
            local totalHeight = minHeight

            if (meta.type == "Image List" or meta.type == "Image") and meta.image and meta.image ~= "" then
                local viewerImgPath = GetImagePath(meta.image)
                modFrame.displayImage:SetTexture(viewerImgPath)

                local imgW, imgH = meta.imgW or 400, meta.imgH or 300
                modFrame.displayImage:SetSize(imgW, imgH)
                modFrame.displayImage:ClearAllPoints()

                if meta.type == "Image" then

                    modFrame.displayImage:SetPoint("TOP", modFrame, "TOP", 0, -30)
                    totalWidth = math.max(imgW + 30, titleWidth)
                    totalHeight = math.max(40, imgH + 50)
                else
                    modFrame.displayImage:SetPoint("TOPLEFT", modFrame, "TOPLEFT", listWidth + 15, -30)
                    totalWidth = listWidth + imgW + 25
                    totalHeight = math.max(minHeight, imgH + 50)
                end
                modFrame.displayImage:Show()
            end

            modFrame:SetSize(totalWidth, totalHeight)

            if meta.type == "List" or meta.type == "Image List" then
                local rowX = (meta.type == "List") and math.max(10, (totalWidth - 210) / 2) or 10
                for i = 1, meta.length do
                    local row = modFrame.listRows[i]
                    if not row then
                        row = CreateFrame("Frame", nil, modFrame)
                        row:SetSize(210, 20)

                        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                        row.label:SetPoint("LEFT", 0, 0)
                        row.label:SetWidth(75)
                        row.label:SetJustifyH("RIGHT")
                        row.label:SetTextColor(1, 1, 1)

                        row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        row.value:SetJustifyH("LEFT")

                        row.icon = row:CreateTexture(nil, "ARTWORK")
                        row.icon:SetSize(17, 17)
                        row.icon:SetPoint("RIGHT", row.value, "LEFT", -4, 0)

                        row.highlight = row:CreateTexture(nil, "BACKGROUND")
                        row.highlight:SetColorTexture(1, 0.8, 0.2, 0.20)

                        modFrame.listRows[i] = row
                    end

                    row:SetPoint("TOPLEFT", rowX, -30 - ((i-1)*rowHeight))
                    row.label:SetText((meta.labels[i] or tostring(i)) .. ":")

                    local playerName = players[i]
                    if playerName then
                        row.value:SetText(playerName)
                        local classToken = SlerneNotesViewer.currentClasses[playerName]
                        if classToken and SlerneNotesViewer.ClassColors[classToken] then
                            local c = SlerneNotesViewer.ClassColors[classToken]
                            row.value:SetTextColor(c.r, c.g, c.b, 1)
                        else
                            row.value:SetTextColor(0.8, 0.8, 0.8, 1)
                        end

                        local role = SlerneNotesViewer.currentRoles[playerName]
                        if role then
                            row.icon:SetTexture(GetIconPath(role))
                            row.icon:Show()

                            row.value:ClearAllPoints()
                            row.value:SetPoint("LEFT", row.label, "RIGHT", 23, 0)
                        else
                            row.icon:Hide()

                            row.value:ClearAllPoints()
                            row.value:SetPoint("LEFT", row.label, "RIGHT", 5, 0)
                        end

                        row.highlight:ClearAllPoints()
                        if role then
                            row.highlight:SetPoint("TOPLEFT", row.icon, "TOPLEFT", -4, 2)
                        else
                            row.highlight:SetPoint("TOPLEFT", row.value, "TOPLEFT", -4, 2)
                        end
                        row.highlight:SetPoint("BOTTOMRIGHT", row.value, "BOTTOMRIGHT", 4, -2)

                        if playerName == myName then row.highlight:Show() else row.highlight:Hide() end
                    else
                        row.value:SetText("")
                        row.icon:Hide()
                        row.highlight:Hide()
                    end
                    row:Show()
                end
            end

        elseif meta.type == "Action List" then

            local rowHeight, slotW, editW = 25, 110, 84
            local contentW = 12 + slotW + 12 + editW + 12 + slotW + 12
            local boxW = math.max(contentW, titleWidth)
            modFrame:SetSize(boxW, 40 + ((meta.length or 0) * rowHeight))
            local rowX = math.max(12, (boxW - contentW) / 2)

            local function FillActionSlot(fs, icon, hl, baseX, pname)
                fs:ClearAllPoints()
                if pname and pname ~= "" then
                    fs:SetText(pname)
                    local classToken = SlerneNotesViewer.currentClasses[pname]
                    if classToken and SlerneNotesViewer.ClassColors[classToken] then
                        local c = SlerneNotesViewer.ClassColors[classToken]
                        fs:SetTextColor(c.r, c.g, c.b, 1)
                    else
                        fs:SetTextColor(0.8, 0.8, 0.8, 1)
                    end
                    local role = SlerneNotesViewer.currentRoles[pname]
                    hl:ClearAllPoints()
                    if role then
                        icon:SetTexture(GetIconPath(role))
                        icon:ClearAllPoints()
                        icon:SetPoint("LEFT", icon:GetParent(), "LEFT", baseX, 0)
                        icon:Show()
                        fs:SetPoint("LEFT", fs:GetParent(), "LEFT", baseX + 18, 0)
                        hl:SetPoint("TOPLEFT", icon, "TOPLEFT", -3, 3)
                    else
                        icon:Hide()
                        fs:SetPoint("LEFT", fs:GetParent(), "LEFT", baseX, 0)
                        hl:SetPoint("TOPLEFT", fs, "TOPLEFT", -3, 3)
                    end
                    hl:SetPoint("BOTTOMRIGHT", fs, "BOTTOMRIGHT", 3, -3)
                    if pname == myName then hl:Show() else hl:Hide() end
                else
                    fs:SetText("")
                    fs:SetPoint("LEFT", fs:GetParent(), "LEFT", baseX, 0)
                    icon:Hide()
                    hl:Hide()
                end
            end

            for i = 1, (meta.length or 0) do
                local row = modFrame.actionRows[i]
                if not row then
                    row = CreateFrame("Frame", nil, modFrame)
                    row:SetSize(contentW, 20)

                    row.leftFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    row.leftIcon = row:CreateTexture(nil, "ARTWORK"); row.leftIcon:SetSize(17, 17)
                    row.leftHL = row:CreateTexture(nil, "BACKGROUND"); row.leftHL:SetColorTexture(1, 0.8, 0.2, 0.20)

                    row.midFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    row.midFS:SetSize(editW, 20)
                    row.midFS:SetPoint("LEFT", row, "LEFT", slotW + 12, 0)
                    row.midFS:SetJustifyH("CENTER")
                    row.midFS:SetTextColor(0.9, 0.9, 0.9, 1)

                    row.rightFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    row.rightIcon = row:CreateTexture(nil, "ARTWORK"); row.rightIcon:SetSize(17, 17)
                    row.rightHL = row:CreateTexture(nil, "BACKGROUND"); row.rightHL:SetColorTexture(1, 0.8, 0.2, 0.20)

                    modFrame.actionRows[i] = row
                end

                row:SetPoint("TOPLEFT", rowX, -30 - ((i - 1) * rowHeight))
                row.midFS:SetText(meta.labels[i] or "")
                FillActionSlot(row.leftFS, row.leftIcon, row.leftHL, 0, players["L" .. i])
                FillActionSlot(row.rightFS, row.rightIcon, row.rightHL, slotW + 12 + editW + 12, players["R" .. i])
                row:Show()
            end

        elseif meta.type == "Text Block" then

            local MIN_TEXT_W, MAX_TEXT_W = 150, 500
            if not modFrame.textFS then
                modFrame.textFS = modFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                modFrame.textFS:SetPoint("TOP", modFrame, "TOP", 0, -30)
                modFrame.textFS:SetJustifyH("LEFT")
                modFrame.textFS:SetJustifyV("TOP")
            end
            local boxW = math.max(MIN_TEXT_W, math.min(MAX_TEXT_W, MaxLineWidth(meta.text) + 12))
            modFrame.textFS:SetWidth(boxW)
            modFrame.textFS:SetText(meta.text or "")
            modFrame.textFS:Show()
            local h = modFrame.textFS:GetStringHeight() or 0
            modFrame:SetSize(math.max(titleWidth, boxW + 30), math.max(70, h + 45))
        end

        local posX = meta.posX or (20 + (index * 30))
        local posY = meta.posY or (-20 - (index * 30))

        modFrame:ClearAllPoints()
        modFrame:SetPoint("TOPLEFT", canvas, "TOPLEFT", posX, posY)
        modFrame:Show()
    end

    SlerneNotesViewer.RenderDrawings(SlerneNotesViewer.currentDrawings)
end
