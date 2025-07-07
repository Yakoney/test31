-- Ensure game is loaded
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Service getter
local get_service = setmetatable({}, {
    __index = function(_, index)
        return cloneref(game:GetService(index))
    end
})

-- Services
local workspace               = get_service("Workspace")
local players                 = get_service("Players")
local replicated_storage      = get_service("ReplicatedStorage")
local run_service             = get_service("RunService")
local user_input_service      = get_service("UserInputService")
local virtual_input_manager   = get_service("VirtualInputManager")
local virtual_user            = get_service("VirtualUser")
local marketplace_service     = get_service("MarketplaceService")

-- Player and world
local local_player = players.LocalPlayer
local backpack     = local_player.Backpack
local info         = marketplace_service:GetProductInfo(game.PlaceId)

local world        = workspace:FindFirstChild("World")    or error("World folder not found!")
local npcs         = world:FindFirstChild("NPCs")         or error("NPCs folder not found!")
local hole_folders = world:FindFirstChild("Zones"):FindFirstChild("_NoDig") or error("Holes folder not found!")
local totems       = workspace:FindFirstChild("Active"):FindFirstChild("Totems") or error("Totems folder not found!")

-- Settings
local staff_option    = "Notify"
local dig_option      = "Legit"
local dig_method      = "Fire Signal"
local auto_sell_delay = 5
local tp_walk_speed   = 10

local auto_pizza = false
local anti_staff = false
local auto_sell  = false
local auto_hole  = false
local inf_jump   = false
local anti_afk   = false
local auto_dig   = false
local tp_walk    = false

-- Utility functions
local function get_tool()
    return local_player.Character and local_player.Character:FindFirstChildOfClass("Tool")
end

-- Highlight box and movement logic for auto_hole
local highlight_box
local function create_highlight()
    if highlight_box and highlight_box.Parent then return end
    highlight_box = Instance.new("Part")
    highlight_box.Name = "AutoHoleHighlight"
    highlight_box.Size = Vector3.new(30, 0.2, 30)
    highlight_box.Anchored = true
    highlight_box.CanCollide = false
    highlight_box.Material = Enum.Material.Neon
    highlight_box.Color = Color3.new(0, 1, 0)
    highlight_box.Transparency = 0.5
    highlight_box.Parent = workspace
end

local function random_walk_and_dig()
    create_highlight()
    while auto_hole do
        local center = local_player.Character:GetPivot().Position
        highlight_box.CFrame = CFrame.new(center.X, center.Y, center.Z)
        local rx = math.random(-150, 150)/10
        local rz = math.random(-150, 150)/10
        local target = Vector3.new(center.X + rx, center.Y, center.Z + rz)
        pcall(function() local_player.Character:MoveTo(target) end)
        task.wait(1 + math.random())
        if not local_player.PlayerGui:FindFirstChild("Dig") then
            local tool = get_tool()
            if not tool or not tool.Name:find("Shovel") then
                for _, itm in ipairs(backpack:GetChildren()) do
                    if itm.Name:find("Shovel") then
                        itm.Parent = local_player.Character; break
                    end
                end
            end
            virtual_input_manager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            virtual_input_manager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end
        task.wait(0.5)
    end
    if highlight_box then highlight_box:Destroy(); highlight_box = nil end
end

-- Anti-AFK
local anti_afk_conn = local_player.Idled:Connect(function()
    if anti_afk then
        virtual_user:CaptureController()
        virtual_user:ClickButton2(Vector2.new())
    end
end)

-- Dig minigame helper
local function click_mobile(btn)
    local pos, size = btn.AbsolutePosition, btn.AbsoluteSize
    local x, y = pos.X + size.X/2, pos.Y + size.Y/2
    virtual_input_manager:SendMouseButtonEvent(x, y, 0, true, game, 1)
    virtual_input_manager:SendMouseButtonEvent(x, y, 0, false, game, 1)
end

local function setup_dig_minigame(gui)
    local strong = gui.Safezone.Holder.Area_Strong
    local bar    = gui.Safezone.Holder.PlayerBar
    local btn    = gui.MobileClick
    bar:GetPropertyChangedSignal("Position"):Connect(function()
        if not auto_dig or auto_pizza then return end
        local within = math.abs(bar.Position.X.Scale - strong.Position.X.Scale) <= 0.04
        if (dig_option == "Legit" and within) or dig_option == "Blatant" then
            if dig_option == "Blatant" then
                bar.Position = UDim2.new(strong.Position.X.Scale,0,0,0)
            end
            if dig_method == "Fire Signal" then
                firesignal(btn.Activated)
            else
                click_mobile(btn)
            end
            task.wait()
        end
    end)
end

-- Listen for Dig GUI
local dig_conn = local_player.PlayerGui.ChildAdded:Connect(function(gui)
    if auto_dig and not auto_pizza and gui.Name == "Dig" then
        setup_dig_minigame(gui)
    end
end)

-- Infinite Jump
user_input_service.JumpRequest:Connect(function()
    if inf_jump then
        local_player.Character:FindFirstChild("Humanoid"):ChangeState("Jumping")
        task.wait()
    end
end)

-- Teleport Walk
local move_conn = run_service.Heartbeat:Connect(function()
    if tp_walk and local_player.Character and local_player.Character:FindFirstChild("Humanoid") then
        local dir = local_player.Character.Humanoid.MoveDirection
        if dir.Magnitude > 0 then
            local_player.Character:TranslateBy(dir * tp_walk_speed/10)
        end
    end
end)

-- Load WindUI
local wind_ui = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Create Window
local window = wind_ui:CreateWindow({
    Title       = "Made by @nauriiokas on discord",
    Icon        = "zap",
    Author      = "@nauriiokas on discord",
    Folder      = "ur a skid<3",
    Size        = UDim2.fromOffset(1000,1000),
    Transparent = true,
    Theme       = "Dark",
    SideBarWidth= 200,
    BackgroundImageTransparency=0.42,
    HideSearchBar=true,
    ScrollBarEnabled=false,
    User={Enabled=true,Anonymous=true,Callback=function()end}
})

-- Tabs
local farm_tab      = window:Tab({Title="Farm",Icon="tractor"})
local misc_tab      = window:Tab({Title="Misc",Icon="cog"})
local inventory_tab = window:Tab({Title="Inventory",Icon="backpack"})
local teleport_tab  = window:Tab({Title="Teleport",Icon="flip-horizontal-2"})

-- Farm Section
farm_tab:Section({Title="Dig Settings",TextXAlignment="Left",TextSize=17})
farm_tab:Toggle({Title="Auto Dig Minigame",Desc="Automatically does the dig minigame for you",Icon="check",Type="Checkbox",Default=auto_dig,Callback=function(v) auto_dig=v end})
farm_tab:Dropdown({Title="Choose Dig Option:",Values={"Legit","Blatant"},Value=dig_option,Callback=function(v) dig_option=v end})
farm_tab:Dropdown({Title="Choose Dig Method:",Values={"Fire Signal","Activate Tool"},Value=dig_method,Callback=function(v) dig_method=v end})
farm_tab:Toggle({Title="30x30 Stud Box Auto Dig (Stuck-Proof)",Desc="Walks and digs within a 30x30 stud green box",Icon="check",Type="Checkbox",Default=auto_hole,Callback=function(v)
    auto_hole=v
    if v then spawn(random_walk_and_dig) end
end})

-- Farm Settings
farm_tab:Section({Title="Farm Settings",TextXAlignment="Left",TextSize=17})
farm_tab:Toggle({Title="Auto Pizza Delivery",Desc="Automatically does pizza deliveries",Icon="check",Type="Checkbox",Default=auto_pizza,Callback=function(v)
    auto_pizza=v
    if v then
        spawn(function()
            while auto_pizza do
                replicated_storage.Remotes.Change_Zone:FireServer("Penguins Pizza")
                replicated_storage.DialogueRemotes.StartInfiniteQuest:InvokeServer("Pizza Penguin")
                task.wait(math.random(1,3))
                local cust = workspace.Active.PizzaCustomers:FindFirstChildOfClass("Model")
                if cust then local_player.Character:MoveTo(cust:GetPivot().Position) end
                task.wait(math.random(2,5))
                replicated_storage.DialogueRemotes.Quest_DeliverPizza:InvokeServer()
                task.wait(math.random(1,3))
                replicated_storage.Remotes.Change_Zone:FireServer("Penguins Pizza")
                replicated_storage.DialogueRemotes.CompleteInfiniteQuest:InvokeServer("Pizza Penguin")
                task.wait(math.random(60,90))
            end
        end)
    end
end})

-- Misc Section
misc_tab:Section({Title="Staff Settings",TextXAlignment="Left",TextSize=17})
local function is_staff(p)
    local rank = p:GetRankInGroup(35289532)
    local role = p:GetRoleInGroup(35289532)
    if rank >= 2 then
        if staff_option == "Kick" then
            local_player:Kick(role.." detected! Username: "..p.DisplayName)
        else
            wind_ui:Notify({Title="Staff Detected!",Content=role.." detected! Username: "..p.DisplayName,Icon="message-circle-warning",Duration=5})
        end
    end
end
misc_tab:Toggle({Title="Anti Staff",Desc="Kicks/Notifies when staff joins",Icon="check",Type="Checkbox",Default=anti_staff,Callback=function(v)
    anti_staff=v
    if v then for _,p in ipairs(players:GetPlayers()) do if p~=local_player then is_staff(p) end end end
end})
misc_tab:Dropdown({Title="Choose Staff Method:",Values={"Notify","Kick"},Value=staff_option,Callback=function(v) staff_option=v end})

misc_tab:Section({Title="Anti Afk Settings",TextXAlignment="Left",TextSize=17})
misc_tab:Toggle({Title="Anti Afk",Desc="Wont disconnect after 20 minutes",Icon="check",Type="Checkbox",Default=anti_afk,Callback=function(v) anti_afk=v end})

misc_tab:Section({Title="LocalPlayer Settings",TextXAlignment="Left",TextSize=17})
misc_tab:Toggle({Title="Inf Jump",Desc="Infinite jump",Icon="check",Type="Checkbox",Default=inf_jump,Callback=function(v) inf_jump=v end})
misc_tab:Toggle({Title="Tp Walk",Desc="Fast movement",Icon="check",Type="Checkbox",Default=tp_walk,Callback=function(v) tp_walk=v end})
misc_tab:Slider({Title="Tp Walk Speed:",Step=1,Value={Min=1,Max=100,Default=tp_walk_speed},Callback=function(v) tp_walk_speed=v end})

-- Inventory Section
inventory_tab:Section({Title="Sell Settings",TextXAlignment="Left",TextSize=17})
inventory_tab:Toggle({Title="Auto Sell",Desc="Automatically sells inventory items",Icon="check",Type="Checkbox",Default=auto_sell,Callback=function(v)
    auto_sell=v
    if v then spawn(function()
        while auto_sell do
            for _,item in ipairs(backpack:GetChildren()) do
                replicated_storage.DialogueRemotes.SellHeldItem:FireServer(item)
            end
            task.wait(auto_sell_delay)
        end
    end) end
end})
inventory_tab:Slider({Title="Auto Sell Delay:",Step=1,Value={Min=1,Max=60,Default=auto_sell_delay},Callback=function(v) auto_sell_delay=v end})
inventory_tab:Button({Title="Sell All Items Once",Desc="Sells all items in inventory",Locked=false,Callback=function()
    for _,item in ipairs(backpack:GetChildren()) do
        replicated_storage.DialogueRemotes.SellHeldItem:FireServer(item)
    end
end})
inventory_tab:Button({Title="Sell Held Item",Desc="Sells held tool",Locked=false,Callback=function()
    local tool = get_tool()
    if not tool then return wind_ui:Notify({Title="No Tool",Content="No Tool Found!",Icon="message-circle-warning",Duration=5}) end
    if not tool:GetAttribute("InventoryLink") then return wind_ui:Notify({Title="Cant Sell!",Content="Cant Sell This Item!",Icon="message-circle-warning",Duration=5}) end
    replicated_storage.DialogueRemotes.SellHeldItem:FireServer(tool)
end})
inventory_tab:Section({Title="Journal Settings",TextXAlignment="Left",TextSize=17})
inventory_tab:Button({Title="Claim Unclaimed Discovered Items",Desc="Claims unclaimed journal items",Locked=false,Callback=function()
    local journal = local_player.PlayerGui.HUD.Frame.Journal.Scroller
    for _,btn in ipairs(journal:GetChildren()) do
        if btn:IsA("ImageButton") and btn:FindFirstChild("Discovered").Visible then firesignal(btn.MouseButton1Click) end
    end
end})

-- Teleport Section
teleport_tab:Section({Title="Misc Teleports",TextXAlignment="Left",TextSize=17})
teleport_tab:Button({Title="Teleport To Merchant",Desc="Teleports to merchant",Locked=false,Callback=function()
    local loc = npcs:FindFirstChild("Merchant Cart")
    if loc then local_player.Character:MoveTo(loc:GetPivot().Position) end
end})
teleport_tab:Button({Title="Teleport To Meteor",Desc="Teleports to meteor",Locked=false,Callback=function()
    local meteor = workspace:FindFirstChild("Active"):FindFirstChild("ActiveMeteor")
    if meteor then local_player.Character:MoveTo(meteor:GetPivot().Position) else wind_ui:Notify({Title="No Meteor",Content="No Meteor Found!",Icon="message-circle-warning",Duration=5}) end
end})
teleport_tab:Button({Title="Teleport To EnchantmentAltar",Desc="Teleports to EnchantmentAltar",Locked=false,Callback=function()
    local altar = world:FindFirstChild("Interactive"):FindFirstChild("Enchanting"):FindFirstChild("EnchantmentAltar"):FindFirstChild("EnchantPart")
    if altar then local_player.Character:MoveTo(altar:GetPivot().Position) end
end})
teleport_tab:Button({Title="Teleport To Active Totem",Desc="Teleports to closest active totem",Locked=false,Callback=function()
    local t = closest_totem()
    if t then local_player.Character:MoveTo(t:GetPivot().Position) else wind_ui:Notify({Title="No Totem",Content="No Active Totem Found!",Icon="message-circle-warning",Duration=5}) end
end})
