local addonName, SlerneNotesViewer = ...
local frame = SlerneNotesViewer.frame

frame:SetSize(1600, 950)
frame:SetPoint("CENTER")
frame:SetFrameStrata("FULLSCREEN_DIALOG")
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

-- Close the viewer with ESC
tinsert(UISpecialFrames, "SlerneNotesViewerFrame")

-- Main window: dark + diamond border. Starts at x=110 so the extruded plugin
-- tabs protrude into the left strip (same idea as Slerne Notes).
local bg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 110, 0)
bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
bg:SetFrameLevel(frame:GetFrameLevel() + 5)
SlerneNotesViewer.Skin.OuterFrame(bg)

-- TAB BAR (left): "Notes" and "Config" extruded folder tabs.
-- Level +1 so idle tabs tuck BEHIND the window (bg, +5) like Slerne Notes;
-- the active tab raises itself above the content (FolderTab handles that).
local tabBar = CreateFrame("Frame", nil, frame)
tabBar:SetSize(90, 920)
tabBar:SetPoint("TOPLEFT", 10, -10)
tabBar:SetFrameLevel(frame:GetFrameLevel() + 1)

local btnNotes = CreateFrame("Button", nil, tabBar, "UIPanelButtonTemplate")
btnNotes:SetSize(108, 54); btnNotes:SetPoint("TOPRIGHT", tabBar, "TOPRIGHT", 22, -16)
btnNotes:SetText("Notes")

local btnConfig = CreateFrame("Button", nil, tabBar, "UIPanelButtonTemplate")
btnConfig:SetSize(108, 54); btnConfig:SetPoint("TOPRIGHT", btnNotes, "BOTTOMRIGHT", 0, -10)
btnConfig:SetText("Config")

SlerneNotesViewer.Skin.FolderTab(btnNotes)
SlerneNotesViewer.Skin.FolderTab(btnConfig)

-- CONTENT CONTAINERS (inset inside bg, raised above it so they draw in front).
-- Inset 22 so the active tab joins the dark margin, not the content border.
local CONTENT_INSET = 22
local CONTENT_LEVEL = frame:GetFrameLevel() + 15

local notesTab = CreateFrame("Frame", nil, frame)
notesTab:SetPoint("TOPLEFT", bg, "TOPLEFT", CONTENT_INSET, -CONTENT_INSET)
notesTab:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -CONTENT_INSET, CONTENT_INSET)
notesTab:SetFrameLevel(CONTENT_LEVEL)

local configTab = CreateFrame("Frame", nil, frame)
configTab:SetPoint("TOPLEFT", bg, "TOPLEFT", CONTENT_INSET, -CONTENT_INSET)
configTab:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -CONTENT_INSET, CONTENT_INSET)
configTab:SetFrameLevel(CONTENT_LEVEL)
configTab:Hide()

-- =====================================================================
-- NOTES TAB  (the canvas view -- unchanged functionality)
-- =====================================================================
local header = CreateFrame("Frame", nil, notesTab, "BackdropTemplate")
header:SetHeight(42)
header:SetPoint("TOPLEFT", 0, 0)
header:SetPoint("TOPRIGHT", 0, 0)
SlerneNotesViewer.Skin.Panel(header)

local lbl = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
lbl:SetPoint("LEFT", 15, 0)
lbl:SetText("Canvas:")
SlerneNotesViewer.Skin.Title(lbl)

local canvasDropdown = CreateFrame("DropdownButton", "SlerneNotesViewerCanvasDropdown", header, "WowStyle1DropdownTemplate")
canvasDropdown:SetPoint("LEFT", lbl, "RIGHT", 12, 0)
canvasDropdown:SetWidth(260)
canvasDropdown:SetupMenu(function(dropdown, root)
    local canvases = (SlerneNotesViewer.GetCanvases and SlerneNotesViewer.GetCanvases()) or {}
    local names = {}
    for name in pairs(canvases) do table.insert(names, name) end
    table.sort(names)
    if #names == 0 then
        root:CreateButton("(no canvases received yet)", function() end)
        return
    end
    for _, name in ipairs(names) do
        root:CreateRadio(name,
            function() return name == (SlerneNotesViewer.GetActiveCanvas and SlerneNotesViewer.GetActiveCanvas()) end,
            function() SlerneNotesViewer.SetActiveCanvas(name) end)
    end
end)
SlerneNotesViewer.Skin.Dropdown(canvasDropdown)

function SlerneNotesViewer.RefreshCanvasDropdown()
    if canvasDropdown.GenerateMenu then canvasDropdown:GenerateMenu() end
end
-- Kept for Core.lua compatibility; now just refreshes the dropdown display.
function SlerneNotesViewer.UpdateHeader()
    SlerneNotesViewer.RefreshCanvasDropdown()
end

-- Exit button (top-right of the header)
local exitBtn = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
exitBtn:SetSize(100, 30)
exitBtn:SetPoint("RIGHT", -10, 0)
exitBtn:SetText("Exit")
exitBtn:SetScript("OnClick", function() frame:Hide() end)
SlerneNotesViewer.Skin.Button(exitBtn)

-- Delete Canvas confirmation (themed dialog above the window)
local confirmDel = CreateFrame("Frame", "SlerneNotesViewerConfirmDelete", frame, "BackdropTemplate")
confirmDel:SetSize(360, 120)
confirmDel:SetPoint("CENTER")
confirmDel:SetFrameStrata("FULLSCREEN_DIALOG")
confirmDel:SetFrameLevel(frame:GetFrameLevel() + 300)
confirmDel:EnableMouse(true)
SlerneNotesViewer.Skin.OuterFrame(confirmDel)
if confirmDel.SetBackdropColor then confirmDel:SetBackdropColor(0.06, 0.04, 0.08, 1) end
if confirmDel._snGrad then confirmDel._snGrad:SetColorTexture(0.06, 0.04, 0.08, 1) end
confirmDel:Hide()

local confirmDelTitle = confirmDel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
confirmDelTitle:SetPoint("TOP", 0, -25)
SlerneNotesViewer.Skin.Title(confirmDelTitle)

local confirmDelYes = CreateFrame("Button", nil, confirmDel, "UIPanelButtonTemplate")
confirmDelYes:SetSize(90, 26)
confirmDelYes:SetPoint("BOTTOMLEFT", 50, 20)
confirmDelYes:SetText("Delete")
confirmDelYes:SetScript("OnClick", function()
    SlerneNotesViewer.DeleteActiveCanvas()
    confirmDel:Hide()
end)
SlerneNotesViewer.Skin.Button(confirmDelYes)

local confirmDelNo = CreateFrame("Button", nil, confirmDel, "UIPanelButtonTemplate")
confirmDelNo:SetSize(90, 26)
confirmDelNo:SetPoint("BOTTOMRIGHT", -50, 20)
confirmDelNo:SetText("Cancel")
confirmDelNo:SetScript("OnClick", function() confirmDel:Hide() end)
SlerneNotesViewer.Skin.Button(confirmDelNo)

local delBtn = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
delBtn:SetSize(120, 30)
delBtn:SetPoint("LEFT", canvasDropdown, "RIGHT", 15, 0)
delBtn:SetText("Delete Canvas")
delBtn:SetScript("OnClick", function()
    local active = SlerneNotesViewer.GetActiveCanvas()
    if not active then return end
    confirmDelTitle:SetText("Delete \"" .. active .. "\"?")
    confirmDel:Show()
end)
SlerneNotesViewer.Skin.Button(delBtn)

-- CANVAS PANEL (modules render here, on the dark window background)
SlerneNotesViewer.canvasPanel = CreateFrame("Frame", nil, notesTab)
SlerneNotesViewer.canvasPanel:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -10)
SlerneNotesViewer.canvasPanel:SetPoint("BOTTOMRIGHT", notesTab, "BOTTOMRIGHT", 0, 0)

-- =====================================================================
-- CONFIG TAB  (Theme + Minimap, moved out of the header)
-- =====================================================================
local function GetVTheme()
    SlerneNotesViewerDB.theme = SlerneNotesViewerDB.theme or { font = "Default", button = "Default" }
    return SlerneNotesViewerDB.theme
end
local function MakeThemeDropdown(parent, getKey, setKey)
    local dd = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dd:SetWidth(160)
    SlerneNotesViewer.Skin.Dropdown(dd)
    dd:SetupMenu(function(dropdown, root)
        for _, c in ipairs(SlerneNotesViewer.ThemeColorChoices) do
            root:CreateRadio(c.label,
                function() return getKey() == c.key end,
                function()
                    setKey(c.key)
                    SlerneNotesViewer.Skin.RefreshTheme() -- live, no reload
                    if dropdown.GenerateMenu then dropdown:GenerateMenu() end
                end)
        end
    end)
    return dd
end

-- THEME panel
local themePanel = CreateFrame("Frame", nil, configTab, "BackdropTemplate")
themePanel:SetSize(440, 220)
themePanel:SetPoint("TOPLEFT", 20, -20)
SlerneNotesViewer.Skin.Panel(themePanel)

local themeTitle = themePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
themeTitle:SetPoint("TOP", 0, -14); themeTitle:SetText("Theme")
SlerneNotesViewer.Skin.Title(themeTitle)

local fontLbl = themePanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
fontLbl:SetPoint("TOPLEFT", 24, -56); fontLbl:SetText("Font color")
SlerneNotesViewer.Skin.Title(fontLbl)
local fontColorDD = MakeThemeDropdown(themePanel, function() return GetVTheme().font end, function(k) GetVTheme().font = k end)
fontColorDD:SetPoint("TOPLEFT", 22, -76)

local btnLbl = themePanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
btnLbl:SetPoint("TOPLEFT", 24, -122); btnLbl:SetText("Button background color")
SlerneNotesViewer.Skin.Title(btnLbl)
local btnColorDD = MakeThemeDropdown(themePanel, function() return GetVTheme().button end, function(k) GetVTheme().button = k end)
btnColorDD:SetPoint("TOPLEFT", 22, -142)

-- Live preview: a sample button + title text. Skin.Button/Skin.Title register
-- theme refreshers, so these recolor instantly as the dropdowns change.
local previewLbl = themePanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
previewLbl:SetPoint("TOPLEFT", 252, -56); previewLbl:SetText("Preview")
SlerneNotesViewer.Skin.Title(previewLbl)

local sampleBtn = CreateFrame("Button", nil, themePanel, "UIPanelButtonTemplate")
sampleBtn:SetSize(170, 30); sampleBtn:SetPoint("TOPLEFT", 250, -80); sampleBtn:SetText("Sample Button")
SlerneNotesViewer.Skin.Button(sampleBtn)

local sampleTitle = themePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
sampleTitle:SetPoint("TOP", sampleBtn, "BOTTOM", 0, -14); sampleTitle:SetText("Sample Title")
SlerneNotesViewer.Skin.Title(sampleTitle)

-- MINIMAP panel
local mmPanel = CreateFrame("Frame", nil, configTab, "BackdropTemplate")
mmPanel:SetSize(300, 220)
mmPanel:SetPoint("TOPLEFT", themePanel, "TOPRIGHT", 20, 0)
SlerneNotesViewer.Skin.Panel(mmPanel)

local mmTitle = mmPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
mmTitle:SetPoint("TOP", 0, -14); mmTitle:SetText("Minimap")
SlerneNotesViewer.Skin.Title(mmTitle)

local mmCheck = CreateFrame("CheckButton", nil, mmPanel, "UICheckButtonTemplate")
mmCheck:SetSize(24, 24)
mmCheck:SetPoint("TOPLEFT", 24, -56)
if mmCheck.GetCheckedTexture then SlerneNotesViewer.Skin.TintTexture(mmCheck:GetCheckedTexture()) end
local mmCheckLbl = mmCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
mmCheckLbl:SetPoint("LEFT", mmCheck, "RIGHT", 4, 0); mmCheckLbl:SetText("Hidden")
mmCheckLbl:SetTextColor(1, 1, 1)
mmCheck:SetScript("OnClick", function(self)
    if SlerneNotesViewer.SetMinimapHidden then SlerneNotesViewer.SetMinimapHidden(self:GetChecked()) end
end)

-- Pull the saved minimap state into the controls (SavedVariables are ready by
-- the time the user opens Config).
local function RefreshConfigControls()
    if SlerneNotesViewer.IsMinimapHidden then mmCheck:SetChecked(SlerneNotesViewer.IsMinimapHidden()) end
end

-- =====================================================================
-- TAB SWITCHING
-- =====================================================================
SlerneNotesViewer.tabs = { btnNotes, btnConfig }
local function SetActiveTab(active)
    for _, t in ipairs(SlerneNotesViewer.tabs) do
        SlerneNotesViewer.Skin.SetFolderTabActive(t, t == active)
    end
end
local function ShowOnly(which)
    notesTab:SetShown(which == "notes")
    configTab:SetShown(which == "config")
    SlerneNotesViewer.activeViewTab = which
    if SlerneNotesViewer.RefreshPageTabs then SlerneNotesViewer.RefreshPageTabs() end
end
btnNotes:SetScript("OnClick", function() ShowOnly("notes"); SetActiveTab(btnNotes) end)
btnConfig:SetScript("OnClick", function() ShowOnly("config"); SetActiveTab(btnConfig); RefreshConfigControls() end)

-- =====================================================================
-- PAGE TABS (read-only; stick up above the window, flip pages -- Notes only)
-- =====================================================================
local pageTabPool = {}
local PAGE_TAB_W, PAGE_TAB_H, PAGE_TAB_STEP = 40, 28, 35
local function getViewerPageTab(idx)
    local t = pageTabPool[idx]
    if not t then
        t = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        t:SetSize(PAGE_TAB_W, PAGE_TAB_H)
        t:GetFontString():SetFontObject("GameFontNormalLarge")
        SlerneNotesViewer.Skin.PageTab(t)
        pageTabPool[idx] = t
    end
    return t
end

function SlerneNotesViewer.RefreshPageTabs()
    for _, t in ipairs(pageTabPool) do t:Hide() end
    if SlerneNotesViewer.activeViewTab == "config" then return end
    local count = SlerneNotesViewer.GetPageCount()
    local active = SlerneNotesViewer.GetActivePage()
    for p = 1, count do
        local t = getViewerPageTab(p)
        t:SetText(tostring(p))
        t:SetScript("OnClick", function() SlerneNotesViewer.SetActivePage(p) end)
        t:ClearAllPoints()
        t:SetPoint("BOTTOMLEFT", bg, "TOPLEFT", 16 + (p - 1) * PAGE_TAB_STEP, 0)
        SlerneNotesViewer.Skin.SetPageTabActive(t, p == active)
        t:Show()
    end
end

-- Start on the Notes tab.
ShowOnly("notes")
SetActiveTab(btnNotes)
