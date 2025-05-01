function AetheriumUI:Demo() -- START OF DEMO FUNCTION
    print("[AetheriumUI] Launching Demo Window...")
    local Window=AetheriumUI:Window({Title="AetheriumUI Demo", Subtitle="Showcasing UI Elements", Size=UDim2.fromOffset(900,650), Keybind=Enum.KeyCode.RightControl, BlurType="UIBlur", AcrylicBlurEnabled=true, ShowUserInfo=true})
    if not Window then print("Failed to create window."); return end -- Check if window creation failed

    -- Global Settings - These look okay structurally
    Window:GlobalSetting({Name="UI Blur", Default=Window:GetAcrylicBlurState(), Callback=function(s) Window:SetAcrylicBlurState(s); Window:Notify({Title="Setting", Description="UI Blur "..(s and "On" or "Off")}) end})
    Window:GlobalSetting({Name="Notifications", Default=Window:GetNotificationsState(), Callback=function(s) Window:SetNotificationsState(s); Window:Notify({Title="Setting", Description="Notifications "..(s and "On" or "Off")}) end})
    Window:GlobalSetting({Name="User Info", Default=Window:GetUserInfoState(), Callback=function(s) Window:SetUserInfoState(s); Window:Notify({Title="Setting", Description="User Info "..(s and "Shown" or "Hidden")}) end})

    -- Tabs - These look okay structurally
    local mainTabGroup=Window:TabGroup({Name="Main Features"})
    local settingsTabGroup=Window:TabGroup({Name="Configuration"})
    local mainTab=mainTabGroup:Tab({Name="Elements", Image=AetheriumUI.Assets.defaultTabIcon})
    local configTab=settingsTabGroup:Tab({Name="Settings", Image=AetheriumUI.Assets.settingsTabIcon})
    local sectionLeft=mainTab:Section({Side="Left"})
    local sectionRight=mainTab:Section({Side="Right"})

    -- Left Section - Checking blocks here carefully
    sectionLeft:Header({Text="Basic Elements"})
    sectionLeft:Button({Name="Show Dialog", Callback=function() Window:Dialog({Title="Example Dialog", Description="This is a test.", Buttons={{Name="Confirm"},{Name="Cancel"}}}) end}) -- OK
    sectionLeft:Button({Name="Show Notify", Callback=function() Window:Notify({Title="Demo Notify", Description="This disappears.", Style="Confirm", Lifetime=4}) end}) -- OK
    sectionLeft:Toggle({Name="Simple Toggle", Default=true}, "DemoToggle") -- OK
    sectionLeft:Label({Text="A descriptive label."}) -- OK
    sectionLeft:Divider() -- OK
    sectionLeft:Header({Text="Input Elements"})
    sectionLeft:Input({Name="Text Input", Placeholder="Enter text...", Default="Hello"}, "DemoInput") -- OK
    sectionLeft:Input({Name="Numeric Input", Placeholder="Enter numbers...", AcceptedCharacters="Numeric"}) -- OK

    -- Keybind - Check the callback function's end
    sectionLeft:Keybind({
        Name="Action Keybind",
        Default=Enum.KeyCode.F,
        Callback=function(k) -- START CALLBACK
            Window:Notify({ Title="Keybind", Description=k.Name.." pressed!"})
        end -- <<<< ENSURE THIS 'end' EXISTS AND IS CORRECT
     }, "DemoKeybind") -- OK

    -- Right Section - Checking blocks here
    sectionRight:Header({Text="Advanced Elements"})
    sectionRight:Slider({Name="Percent Slider", Minimum=0, Maximum=100, Default=50, Precision=0, DisplayMethod="Percent"}, "DemoSlider") -- OK
    sectionRight:Slider({Name="Value Slider", Minimum=-10, Maximum=10, Default=0, Precision=1, Step=0.5, Suffix=" units"}) -- OK
    local demoOpts={"Opt A","Opt B","Opt C","Long Option"}
    sectionRight:Dropdown({Name="Single Select", Options=demoOpts, Default=demoOpts[1], Required=true}, "DemoDropdown") -- OK
    sectionRight:Dropdown({Name="Multi Select", Options={"Apple","Banana","Cherry","Date","Fig","Grape"}, Multi=true, Search=true, Default={"Apple","Cherry"}}, "DemoMultiDropdown") -- OK
    sectionRight:Colorpicker({Name="Primary Color", Default=Color3.fromRGB(80,120,255)}, "DemoColorpicker") -- OK
    sectionRight:Colorpicker({Name="Secondary (Alpha)", Default=Color3.fromRGB(255,80,80), Alpha=0.5}, "DemoColorpickerAlpha") -- OK
    sectionRight:Paragraph({Header="Info", Body="Complex elements here."}) -- OK
    sectionRight:SubLabel({Text="Color pickers included."}) -- OK

    -- Config Section - This calls another function, assume InsertConfigSection is okay from previous checks
    configTab:InsertConfigSection("Left") -- OK

    -- Select initial tab
    mainTab:Select() -- OK

    print("[AetheriumUI] Demo setup complete.")
end -- <<<< ENSURE THIS FINAL 'end' FOR THE DEMO FUNCTION ITSELF EXISTS
