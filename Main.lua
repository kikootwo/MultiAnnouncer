MultiAnnouncer = LibStub("AceAddon-3.0"):NewAddon("MultiAnnouncer", "AceConsole-3.0")
-- At the top of your Main.lua, make sure to load the necessary libraries



function MultiAnnouncer:OnInitialize()
    -- This code runs when the addon is loaded
    self.db = LibStub("AceDB-3.0"):New("MultiAnnouncerDB",
    {
        profile =
        {
            text = "",
            lastClicked = -1,
            checkboxStates = {
                ["1"] = false,
                ["2"] = false,
                ["3"] = false,
                ["4"] = false,
                ["5"] = false,
                ["Yell"] = false,
                ["Say"] = false,
            },
            minimap = { hide = false }
        },
    }, true)
    MultiAnnouncerData = self.db.profile
end


function MultiAnnouncer:SetupMinimapIcon()
    local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("MultiAnnouncer", {
        type = "launcher",
        text = "MultiAnnouncer",
        icon = "Interface\\Icons\\ability_warrior_battleshout", -- Replace with your desired icon path
        OnClick = function(clickedframe, button)
            MultiAnnouncer:ToggleWindow()
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine("MultiAnnouncer")
            tooltip:AddLine("Click to show/hide the window.")
        end,
    })

    -- Use the saved variables table for the minimap icon position
    LibStub("LibDBIcon-1.0"):Register("MultiAnnouncer", LDB, self.db.profile.minimap)
end


function MultiAnnouncer:OnEnable()
    -- Code to run when the addon is enabled
    if not self.db.icon then self.db.icon = {} end
    self:CreateUpdaterFrame()  -- Start the updater
    self:SetupMinimapIcon() -- Set up the minimap icon
end

function MultiAnnouncer:OnDisable()
    -- Code to run when the addon is disabled
end

function MultiAnnouncer:CreateUI()
    if self.frame then return end -- If the frame already exists, do nothing

    local AceGUI = LibStub("AceGUI-3.0")
    
    -- Create a frame
    self.frame = AceGUI:Create("Frame")
    self.frame:SetTitle("MultiAnnouncer")
    self.frame:SetStatusText("Ready")
    self.frame:SetLayout("Flow")
    self.frame:SetWidth(400) -- Adjust width as needed
    self.frame:SetHeight(250) -- Adjust height as needed

    self.frame:SetCallback("OnClose", function(widget)
        widget:Hide()
        self:HideWindow()
    end)

    -- Assuming the AceGUI frame is fully created at this point
    -- Attempt to directly name the frame and add to UISpecialFrames
    local frameName = "MultiAnnouncerMainFrame"
    _G[frameName] = self.frame.frame
    tinsert(UISpecialFrames, frameName)
    
    self.frame.frame:SetResizable(false) -- Disable resizing
    -- Assuming self.frame is your AceGUI Frame
    if self.frame and self.frame.sizer_se and self.frame.sizer_s and self.frame.sizer_e then
        self.frame.sizer_se:Hide() -- Hide the resize grip
        self.frame.sizer_s:Hide() -- Hide the resize grip
        self.frame.sizer_e:Hide() -- Hide the resize grip
    end
    -- Create a text box
    local textBox = AceGUI:Create("MultiLineEditBox")
    -- Attempt to hide the 'Accept' button
    local acceptButton = textBox.button
    if acceptButton and acceptButton.Hide then
        acceptButton:Hide()
    end
    textBox:SetLabel("Message (255 characters max)")
    textBox:SetMaxLetters(255)
    textBox:SetNumLines(4) -- Adjust for desired height
    textBox:SetWidth(380) -- Adjust to fit within the window width
    textBox:SetCallback("OnTextChanged", function(widget)
        local text = widget:GetText()
        local remaining = 255 - strlen(text)
        widget:SetLabel("Message (255 characters max) - " .. remaining .. " characters remaining")
        self.db.profile.text = text
    end)
    if self.db.profile.text then textBox:SetText(self.db.profile.text) end
    self.frame:AddChild(textBox)

    
    -- Create checkboxes
    -- Assuming a horizontal flow layout for simplicity
    local checkBoxGroup = AceGUI:Create("SimpleGroup")
    checkBoxGroup:SetFullWidth(true)
    checkBoxGroup:SetLayout("Flow") -- Horizontal layout
    self.checkboxes = {}
    for _, channel in ipairs({"1", "2", "3", "4", "5", "Yell", "Say"}) do
        local checkbox = AceGUI:Create("CheckBox")
        checkbox:SetLabel(channel)
        checkbox:SetWidth(50) -- Adjust the width to fit them in a line
        checkbox:SetCallback("OnValueChanged", function(widget, event, value)
            self.db.profile.checkboxStates[channel] = value
        end)
        checkbox:SetValue(self.db.profile.checkboxStates[channel])
        self.checkboxes[channel] = checkbox
        checkBoxGroup:AddChild(checkbox)
    end
    self.frame:AddChild(checkBoxGroup)

    
    -- Create a send button
    local sendButton = AceGUI:Create("Button")
    sendButton:SetText("Send")
    sendButton:SetFullWidth(true) -- Makes the button fill the width of the window
    sendButton:SetCallback("OnClick", function()
        local message = textBox:GetText() -- Assuming textBox is your EditBox's variable
        if message == "" then return end -- Do nothing if the message is empty
        
        for channel, checkbox in pairs(self.checkboxes) do
            if checkbox:GetValue() then -- Checkbox is checked
                if channel == "Yell" then
                    SendChatMessage(message, "YELL")
                elseif channel == "Say" then
                    SendChatMessage(message, "SAY")
                else
                    SendChatMessage(message, "CHANNEL", nil, GetChannelName(channel))
                end
            end
        end
        
        -- Optionally, update the last clicked time
        self.db.profile.lastClicked = GetTime()
        -- Update any status text or perform other actions post-send here
    end)
    self.frame:AddChild(sendButton)
    
    -- Status text logic here
    self.db.profile.lastClicked = -1
    self.frame:SetStatusText("No spam sent this session") -- Set to empty string to remove it
end

function MultiAnnouncer:ToggleWindow()
    if self.frame and self.frame:IsShown() then
        self:HideWindow()
    else
        self:ShowWindow()
    end
end


function MultiAnnouncer:ShowWindow()
    if not self.frame then
        self:CreateUI()
    end
    self.frame:Show()

    -- Enable the updater frame
    if not self.updaterFrame then
        self:CreateUpdaterFrame()
    end
    self.updaterFrame:SetScript("OnUpdate", function() self:UpdateElapsedTime() end)
end

function MultiAnnouncer:HideWindow()
    if self.frame then
        self.frame:Hide()
    end
    -- Disable the updater frame to conserve resources
    if self.updaterFrame and self.updaterFrame:GetScript("OnUpdate") then
        self.updaterFrame:SetScript("OnUpdate", nil)
    end
end

function MultiAnnouncer:CreateUpdaterFrame()
    if not self.updaterFrame then
        self.updaterFrame = CreateFrame("Frame", nil, UIParent)
    end
end

function MultiAnnouncer:UpdateElapsedTime()
    if not self.frame then return end -- If the frame doesn't exist, do nothing
    if self.db.profile.lastClicked and self.db.profile.lastClicked ~= -1 then
        local currentTime = GetTime()
        local elapsedTime = currentTime - self.db.profile.lastClicked
        -- Convert elapsedTime to a more readable format if needed, e.g., minutes and seconds
        local minutes = math.floor(elapsedTime / 60)
        local seconds = math.floor(elapsedTime % 60)
        -- Update your UI with the elapsed time
        -- For example, if you have a status text element for this:
        self.frame:SetStatusText(string.format("Last Spam: %d min %d sec ago", minutes, seconds))

    end
end



-- Slash Command Setup
SLASH_MULTIANNOUNCER1 = "/multiannouncer"
SlashCmdList["MULTIANNOUNCER"] = function(msg)
    MultiAnnouncer:ToggleWindow()
end