local addonName, SlerneNotesViewer = ...

local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
local LDBIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)
if not (LDB and LDBIcon) then return end

local dataObj = LDB:NewDataObject("SlerneNotesViewer", {
    type = "launcher",
    text = "Slerne Notes Viewer",
    icon = "Interface\\AddOns\\SlerneNotesViewer\\img\\theme\\LogoMinimap.tga",
    OnClick = function(_, button)
        local f = SlerneNotesViewer.frame
        if not f then return end
        if f:IsShown() then f:Hide() else f:Show() end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Slerne Notes Viewer")
        tooltip:AddLine("|cffffff00Click|r to toggle the window.", 1, 1, 1)
    end,
})

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, _, arg1)
    if arg1 == "SlerneNotesViewer" then
        SlerneNotesViewerDB = SlerneNotesViewerDB or {}

        if SlerneNotesViewerDB.minimap == nil then SlerneNotesViewerDB.minimap = { hide = true } end
        if not LDBIcon:IsRegistered("SlerneNotesViewer") then
            LDBIcon:Register("SlerneNotesViewer", dataObj, SlerneNotesViewerDB.minimap)
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

function SlerneNotesViewer.SetMinimapHidden(hide)
    SlerneNotesViewerDB.minimap = SlerneNotesViewerDB.minimap or {}
    SlerneNotesViewerDB.minimap.hide = hide and true or false
    if SlerneNotesViewerDB.minimap.hide then LDBIcon:Hide("SlerneNotesViewer") else LDBIcon:Show("SlerneNotesViewer") end
end

function SlerneNotesViewer.IsMinimapHidden()
    return SlerneNotesViewerDB and SlerneNotesViewerDB.minimap and SlerneNotesViewerDB.minimap.hide or false
end
