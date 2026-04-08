local addonName, SlerneNotesViewer = ...
local frame = SlerneNotesViewer.frame

frame:SetSize(1600, 950)
frame:SetPoint("CENTER")
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

local bg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
bg:SetAllPoints()
bg:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })

local header = CreateFrame("Frame", nil, frame, "BackdropTemplate")
header:SetSize(1580, 50)
header:SetPoint("TOP", 0, -10)
header:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background" })
header:SetBackdropColor(0.05, 0.05, 0.05, 0.95)

local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
headerText:SetPoint("LEFT", 15, 0)
headerText:SetText("Canvas: None")

function SlerneNotesViewer.UpdateHeader(canvasName)
    headerText:SetText("Canvas: " .. (canvasName or "Unknown"))
end

local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButton")
closeBtn:SetSize(32, 32)
closeBtn:SetPoint("RIGHT", header, "RIGHT", -5, 0)
closeBtn:SetScript("OnClick", function() frame:Hide() end)

SlerneNotesViewer.canvasPanel = CreateFrame("Frame", nil, frame)
SlerneNotesViewer.canvasPanel:SetSize(1580, 870)
SlerneNotesViewer.canvasPanel:SetPoint("TOP", header, "BOTTOM", 0, -10)