local addonName, SlerneNotesViewer = ...
local modPool = {}

local function Clear(f)
    if not f then return end
    for _, c in ipairs({f:GetChildren()}) do c:Hide() end
end

local function GetImagePath(imgName)
    if not imgName or imgName == "" then return "" end
    if string.find(imgName, "\\") or string.find(imgName, "/") then return imgName end
    return "Interface\\AddOns\\Slerne_Notes_Viewer\\img\\raidplans\\" .. imgName
end

local function GetIconPath(iconName)
    return "Interface\\AddOns\\Slerne_Notes_Viewer\\img\\icons\\" .. iconName .. ".tga"
end

function SlerneNotesViewer.Render()
    local canvas = SlerneNotesViewer.canvasPanel
    if not canvas then return end

    Clear(canvas)
    local index = 0

    for modName, modData in pairs(SlerneNotesViewer.currentLayout) do
        index = index + 1
        local meta = modData.meta
        local players = modData.players

        local modFrame = modPool[index]
        if not modFrame then
            modFrame = CreateFrame("Frame", nil, canvas, "BackdropTemplate")
            modFrame:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
            modFrame:SetBackdropColor(0,0,0,0.7)

            modFrame.title = modFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            modFrame.title:SetPoint("TOP", 0, -5)
            modFrame.displayImage = modFrame:CreateTexture(nil, "ARTWORK")
            modFrame.playerTexts = {}
            modFrame.listRows = {}
            modPool[index] = modFrame
        end
        
        for _, pt in ipairs(modFrame.playerTexts) do pt:Hide() end
        for _, row in ipairs(modFrame.listRows) do row:Hide() end
        modFrame.displayImage:Hide()
        if modFrame.scrollFrame then modFrame.scrollFrame:Hide() end

        modFrame.title:SetText(modName)

        local titleWidth = modFrame.title:GetStringWidth() + 45 

        if meta.type == "Assignment" then
            local pCount, i = 0, 0
            for player in pairs(players) do
                pCount = pCount + 1; i = i + 1
                local f = modFrame.playerTexts[i]
                if not f then
                    f = CreateFrame("Frame", nil, modFrame)
                    f:SetSize(160, 15)
                    f.fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    f.fs:SetPoint("LEFT", 0, 0)
                    f.icon = f:CreateTexture(nil, "ARTWORK")
                    f.icon:SetSize(14, 14)
                    f.icon:SetPoint("RIGHT", f.fs, "LEFT", -4, 0)
                    modFrame.playerTexts[i] = f
                end
                
                f.fs:SetText(player)
                f:SetPoint("TOPLEFT", 25, -20 - (i*15))
                
                local classToken = SlerneNotesViewer.currentClasses[player]
                if classToken and SlerneNotesViewer.ClassColors[classToken] then
                    local c = SlerneNotesViewer.ClassColors[classToken]
                    f.fs:SetTextColor(c.r, c.g, c.b, 1)
                else
                    f.fs:SetTextColor(0.8, 0.8, 0.8, 1)
                end
                
                local role = SlerneNotesViewer.currentRoles[player]
                if role then
                    f.icon:SetTexture(GetIconPath(role))
                    f.icon:Show()
                else
                    f.icon:Hide()
                end
                
                f:Show()
            end
            modFrame:SetSize(math.max(180, titleWidth), math.max(60, 40 + (pCount * 15)))
            
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
                    modFrame.displayImage:SetPoint("TOPLEFT", modFrame, "TOPLEFT", 15, -30)
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
                for i = 1, meta.length do
                    local row = modFrame.listRows[i]
                    if not row then
                        row = CreateFrame("Frame", nil, modFrame)
                        row:SetSize(210, 20)
                        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                        row.label:SetPoint("LEFT", 0, 0)
                        row.label:SetWidth(75)
                        row.label:SetJustifyH("RIGHT")
                        
                        row.value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        row.value:SetPoint("LEFT", row.label, "RIGHT", 10, 0)
                        row.value:SetWidth(125)
                        row.value:SetJustifyH("LEFT")
                        
                        row.icon = row:CreateTexture(nil, "ARTWORK")
                        row.icon:SetSize(14, 14)
                        row.icon:SetPoint("RIGHT", row.value, "LEFT", -4, 0)
                        
                        modFrame.listRows[i] = row
                    end
                    
                    row:SetPoint("TOPLEFT", 10, -30 - ((i-1)*rowHeight))
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
                        else
                            row.icon:Hide()
                        end
                    else
                        row.value:SetText("")
                        row.icon:Hide()
                    end
                    row:Show()
                end
            end
        
        elseif meta.type == "Text Block" then
            modFrame:SetSize(math.max(250, titleWidth), 200)
            if not modFrame.scrollFrame then
                modFrame.scrollFrame = CreateFrame("ScrollFrame", nil, modFrame, "UIPanelScrollFrameTemplate")
                modFrame.scrollFrame:SetPoint("TOPLEFT", 15, -30)
                modFrame.scrollFrame:SetPoint("BOTTOMRIGHT", -35, 15)
                
                modFrame.editBox = CreateFrame("EditBox", nil, modFrame.scrollFrame)
                modFrame.editBox:SetMultiLine(true)
                modFrame.editBox:SetAutoFocus(false)
                modFrame.editBox:SetFontObject(ChatFontNormal)
                modFrame.editBox:SetWidth(190)
                modFrame.editBox:SetScript("OnTextChanged", function(self) self:SetText(self.readOnlyText) end)
                modFrame.scrollFrame:SetScrollChild(modFrame.editBox)
            end
            
            modFrame.editBox.readOnlyText = meta.text or ""
            modFrame.editBox:SetText(meta.text or "")
            modFrame.scrollFrame:Show()
        end

        -- Stagger the fallback coordinates so modules don't stack completely flat when data is missing
        local posX = meta.posX or (20 + (index * 30))
        local posY = meta.posY or (-20 - (index * 30))
        
        modFrame:ClearAllPoints()
        modFrame:SetPoint("TOPLEFT", canvas, "TOPLEFT", posX, posY)
        modFrame:Show()
    end
end
