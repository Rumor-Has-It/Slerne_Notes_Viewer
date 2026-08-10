local addonName, SlerneNotesViewer = ...

local COLORS = {
    {1.00, 1.00, 1.00}, {1.00, 0.20, 0.20}, {1.00, 0.55, 0.10}, {1.00, 0.90, 0.20},
    {0.30, 1.00, 0.35}, {0.30, 0.60, 1.00}, {0.75, 0.40, 1.00}, {0.05, 0.05, 0.05},
}
local SAMPLE_DIST2 = 4 * 4
local LINE_THICKNESS = 3

local layer = SlerneNotesViewer.localDrawLayer

local pencilOn = false
local drawing = false
local currentStroke = nil
local activeList = nil
local currentColor = { 1, 1, 1 }

local previewPool = {}

local function cursorLocal()
    local scale = layer:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    cx, cy = cx / scale, cy / scale
    local x = cx - layer:GetLeft()
    local y = cy - layer:GetTop()
    local w, h = layer:GetWidth(), layer:GetHeight()
    x = math.max(0, math.min(w, x))
    y = math.max(-h, math.min(0, y))
    return x, y
end

local function previewSeg(i, x1, y1, x2, y2, c)
    local l = previewPool[i]
    if not l then
        l = layer:CreateLine(nil, "OVERLAY")
        previewPool[i] = l
    end
    l:SetThickness(LINE_THICKNESS)
    l:SetColorTexture(c[1], c[2], c[3], 1)
    l:SetStartPoint("TOPLEFT", layer, x1, y1)
    l:SetEndPoint("TOPLEFT", layer, x2, y2)
    l:Show()
end

local function clearPreview()
    for _, l in ipairs(previewPool) do l:Hide() end
end

local function onDrawUpdate()
    if not drawing or not currentStroke then return end
    local px, py = cursorLocal()
    local pts = currentStroke.points
    local last = pts[#pts]
    local dx, dy = px - last[1], py - last[2]
    if dx * dx + dy * dy >= SAMPLE_DIST2 then
        table.insert(pts, { px, py })
        previewSeg(#pts - 1, last[1], last[2], px, py, currentStroke.color)
    end
end

layer:SetScript("OnMouseDown", function(self, button)
    if button ~= "LeftButton" or not pencilOn then return end
    activeList = SlerneNotesViewer.GetLocalStrokes(true)
    if not activeList then return end
    local px, py = cursorLocal()
    drawing = true
    currentStroke = {
        color = { currentColor[1], currentColor[2], currentColor[3] },
        thickness = LINE_THICKNESS,
        alpha = 1,
        points = { { px, py } },
    }
    self:SetScript("OnUpdate", onDrawUpdate)
end)

layer:SetScript("OnMouseUp", function(self, button)
    if button ~= "LeftButton" or not drawing then return end
    drawing = false
    self:SetScript("OnUpdate", nil)
    if currentStroke and #currentStroke.points >= 2 and activeList then
        activeList[#activeList + 1] = currentStroke
    end
    currentStroke = nil
    activeList = nil
    clearPreview()
    SlerneNotesViewer.RenderLocalStrokes()
end)

local toolbar = CreateFrame("Frame", nil, SlerneNotesViewer.header, "BackdropTemplate")
toolbar:SetHeight(34)
toolbar:SetPoint("LEFT", SlerneNotesViewer.headerDeleteBtn, "RIGHT", 12, 0)
toolbar:SetFrameLevel(SlerneNotesViewer.header:GetFrameLevel() + 5)
SlerneNotesViewer.Skin.Panel(toolbar)

local x = 6

local pencilBtn = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
pencilBtn:SetSize(48, 24)
pencilBtn:SetPoint("LEFT", x, 0)
pencilBtn:SetText("Pencil")
SlerneNotesViewer.Skin.Button(pencilBtn)
x = x + 48 + 3

local pencilMark = CreateFrame("Frame", nil, pencilBtn, "BackdropTemplate")
pencilMark:SetPoint("TOPLEFT", -1, 1)
pencilMark:SetPoint("BOTTOMRIGHT", 1, -1)
pencilMark:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
pencilMark:SetBackdropBorderColor(1, 0.82, 0.30, 1)
pencilMark:SetFrameLevel(pencilBtn:GetFrameLevel() + 4)
pencilMark:Hide()

local function setPencil(on)
    pencilOn = on
    drawing = false
    currentStroke = nil
    activeList = nil
    layer:SetScript("OnUpdate", nil)
    clearPreview()
    layer:EnableMouse(on)
    pencilMark:SetShown(on)
end

pencilBtn:SetScript("OnClick", function() setPencil(not pencilOn) end)

local colorSel
local function setColor(c, swatch)
    currentColor = { c[1], c[2], c[3] }
    if colorSel and swatch then
        colorSel:ClearAllPoints()
        colorSel:SetPoint("CENTER", swatch, "CENTER", 0, 0)
        colorSel:Show()
    end
end

x = x + 5
local firstSwatch
for _, c in ipairs(COLORS) do
    local sw = CreateFrame("Button", nil, toolbar, "BackdropTemplate")
    sw:SetSize(17, 17)
    sw:SetPoint("LEFT", x, 0)
    sw:EnableMouse(true)
    sw:RegisterForClicks("LeftButtonUp")
    sw:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    sw:SetBackdropColor(c[1], c[2], c[3], 1)
    sw:SetBackdropBorderColor(0, 0, 0, 1)
    sw:SetScript("OnClick", function(self) setColor(c, self) end)
    if not firstSwatch then firstSwatch = sw end
    x = x + 16
end

colorSel = CreateFrame("Frame", nil, toolbar, "BackdropTemplate")
colorSel:SetSize(21, 21)
colorSel:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10 })
colorSel:SetBackdropBorderColor(1, 0.82, 0.30, 1)
colorSel:SetFrameLevel(toolbar:GetFrameLevel() + 5)
colorSel:Hide()

x = x + 8

local clearBtn = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
clearBtn:SetSize(48, 24)
clearBtn:SetPoint("LEFT", x, 0)
clearBtn:SetText("Clear")
SlerneNotesViewer.Skin.Button(clearBtn)
clearBtn:SetScript("OnClick", function()
    local list = SlerneNotesViewer.GetLocalStrokes(false)
    if list then wipe(list) end
    SlerneNotesViewer.RenderLocalStrokes()
end)
clearBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText("Clear my drawings")
    GameTooltip:AddLine("Removes your own pencil strokes on this page.", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)
clearBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
x = x + 48 + 6

toolbar:SetWidth(x)

setColor(COLORS[1], firstSwatch)
setPencil(false)
