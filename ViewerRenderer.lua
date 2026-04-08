local addonName, SlerneNotesViewer = ...
local modPool = {}

local function Clear(f)
    if not f then return end
    for _, c in ipairs({f:GetChildren()}) do c:Hide() end
end

function SlerneNotesViewer.Render()
    local canvas = SlerneNotesViewer.canvasPanel
    if not canvas then return end

    Clear(canvas)
    local currentX, currentY, rowMaxHeight, index = 0, 0, 0, 0
    local containerWidth = canvas:GetWidth() or 1580

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

        if meta.type == "Assignment Box" then
            local pCount, i = 0, 0
            for player in pairs(players) do
                pCount = pCount + 1; i = i + 1
                local textFs = modFrame.playerTexts[i]
                if not textFs then
                    textFs = modFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    modFrame.playerTexts[i] = textFs
                end
                textFs:SetText(player)
                textFs:SetPoint("TOPLEFT", 15, -20 - (i*15))
                
                local classToken = SlerneNotesViewer.currentClasses[player]
                if classToken and SlerneNotesViewer.ClassColors[classToken] then
                    local c = SlerneNotesViewer.ClassColors[classToken]
                    textFs:SetTextColor(c.r, c.g, c.b, 1)
                else
                    textFs:SetTextColor(0.8, 0.8, 0.8, 1)
                end
                textFs:Show()
            end
            modFrame:SetSize(180, math.max(60, 40 + (pCount * 15)))
            
        elseif meta.type == "List" or meta.type == "Image List" then
            local rowHeight, listWidth = 25, 220 
            local totalWidth = listWidth
            local minHeight = 40 + (meta.length * rowHeight)
            local totalHeight = minHeight
            
            if meta.type == "Image List" and meta.image and meta.image ~= "" then
                -- Direct load from Viewer's img folder since input is only filename now
                local viewerImgPath = "Interface\\AddOns\\Slerne_Notes_Viewer\\img\\" .. meta.image
                modFrame.displayImage:SetTexture(viewerImgPath)

                local imgW, imgH = meta.imgW or 400, meta.imgH or 300
                modFrame.displayImage:SetSize(imgW, imgH)
                modFrame.displayImage:ClearAllPoints()
                modFrame.displayImage:SetPoint("TOPLEFT", modFrame, "TOPLEFT", listWidth + 15, -30)
                modFrame.displayImage:Show()
                totalWidth = listWidth + imgW + 25
                totalHeight = math.max(minHeight, imgH + 50)
            end
            
            modFrame:SetSize(totalWidth, totalHeight)

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
                else
                    row.value:SetText("")
                end
                row:Show()
            end
        
        elseif meta.type == "Reminders" then
            modFrame:SetSize(250, 200)
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

        local modW, modH = modFrame:GetWidth(), modFrame:GetHeight()
        if currentX + modW > containerWidth and currentX > 0 then
            currentX = 0; currentY = currentY + rowMaxHeight + 15; rowMaxHeight = 0
        end

        modFrame:SetPoint("TOPLEFT", canvas, "TOPLEFT", currentX, -currentY)
        currentX = currentX + modW + 15
        if modH > rowMaxHeight then rowMaxHeight = modH end
        modFrame:Show()
    end
end