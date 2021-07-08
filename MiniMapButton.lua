local useAddonScope = true
local addonName, MenuClass

if useAddonScope then
    addonName, MenuClass = ...
else
    addonName, MenuClass = "AcoTools", {}
end

function MenuClass:New()
    local ret = {}
    
    -- set the defaults
    ret.menuList = {}
    ret.anchor = 'cursor'; -- default at the cursor
    ret.x = nil;
    ret.y = nil;
    ret.displayMode = 'MENU'; -- default
    ret.autoHideDelay = 1;
    ret.menuFrame = nil; -- If not defined, :Show() will create a generic menu frame
    ret.uniqueID = 1

    -- import the functions
    for k,v in pairs(self) do
        ret[k] = v
    end
    
    -- return a copy of the class
    return ret
end

--[[
    Return the index where "text" lives.
    ; text : The text to search for.
--]]
function MenuClass:GetItemByText(text)
    for k,v in pairs(self.menuList) do
        if v.text == text then
            return k
        end
    end
end

--[[
    Add menu items
    ; text : The display text.
    ; func : The function to execute OnClick.
    ; isTitle : 1 if this is a header (usually the first one)
    ; otherAttributes : table - { ["attribute"] = value, }
    returns the last index of the menu item that was just added.
--]]
function MenuClass:AddItem(text, func, isTitle, otherAttributes)
    local info = {}
    
	if not isTitle then text = "    "..text end

    info["text"] = text
    info["isTitle"] = isTitle
    info["func"] = func
	info["notCheckable"] = true
    
    if type(otherAttributes) == "table" then
        for attribute, value in pairs(otherAttributes) do
            info[attribute] = value
        end
    end

    table.insert(self.menuList, info)
    return #self.menuList
end

--[[
    Set an attribute for the menu item.
    Valid attributes are found in the FrameXML\UIDropDownMenu.lua file with their valid values.
    Arbitrary non-official attributes are allowed, but are only useful if you plan to access them with :GetAttribute().
    ; text : The text of the menu item or index of the menu item.
    ; attribute : Set this attribute to "value".
    ; value : The value to set the attribute to.
--]]
function MenuClass:SetAttribute(text, attribute, value)
    self.menuList[self:GetItemByText(text) or (self.menuList[text] and text) or 1][attribute or "uniqueID"] = value
end

--[[
    Get an attribute for the menu item.
    Valid attributes are found in the FrameXML\UIDropDownMenu.lua file with their valid values or any arbitrary attribute set with :SetAttribute().
    ; text : The text of the menu item or index of the menu item.
    ; attribute : Get this attribute.
--]]
function MenuClass:GetAttribute(text, attribute)
    return self.menuList[self:GetItemByText(text) or (self.menuList[text] and text) or 1][attribute or "uniqueID"]
end

--[[
    Remove the first item matching "text"
    ; text : The text to search for.
--]]
function MenuClass:RemoveItem(text)
    table.remove(self.menuList, self:GetItemByText(text))
end

--[[
    ; anchor : Set the anchor point. 
--]]
function MenuClass:SetAnchor(anchor)
    if anchor ~= 'cursor' then
        self.x = 0
        self.y = 0
    end
    self.anchor = anchor
end

--[[
    ; displayMode : "MENU"
--]]
function MenuClass:SetDisplayMode(displayMode)
    self.displayMode = displayMode
end

--[[
    ; autoHideDelay : How long, without a click, before the menu goes away.
--]]
function MenuClass:SetAutoHideDelay(autoHideDelay)
    self.autoHideDelay = tonumber(autoHideDelay)
end

--[[
    ; menuFrame : Should inherit a Drop Down Menu template.
--]]
function MenuClass:SetMenuFrame(menuFrame)
    self.menuFrame = menuFrame
end

function MenuClass:GetMenuList()
    return self.menuList
end

--[[
    ; x : X position
    ; save : When not nil, will add to the current value rather than replace it
--]]
function MenuClass:SetX(x, save)
    if save then
        self.x = self.x + x
    else
        self.x = x
    end
end

--[[
    ; y : Y position
    ; save : When not nil, will add to the current value rather than replace it
--]]
function MenuClass:SetY(y, save)
    if save then
        self.y = self.y + y
    else
        self.y = y
    end
end

function MenuClass:Activate()
    if not self.menuFrame then
        while _G['GenericMenuClassFrame'..self.uniqueID] do -- ensure that there's no namespace collisions
            self.uniqueID = self.uniqueID + 1
        end
        -- the frame must be named for some reason
        self.menuFrame = CreateFrame('Frame', 'GenericMenuClassFrame'..self.uniqueID, UIParent, "UIDropDownMenuTemplate")
    end
    self.menuFrame.menuList = self.menuList
end

--[[
    Show the menu.
--]]
function MenuClass:Show()
    self:Activate()
    EasyMenu(self.menuList, self.menuFrame, self.anchor, self.x, self.y, self.displayMode, self.autoHideDelay)
end

-- If you're not using the addon-scoped variables, you must have a global variable in order to use this menu.
if not useAddonScope then
    _G[addonName.."Menu"] = MenuClass
end


-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)
local type = type
local abs, sqrt = math.abs, math.sqrt

-- ----------------------------------------------------------------------------
-- AddOn namespace.
-- ----------------------------------------------------------------------------
local AcoBidAdmin = _G.AcoBidAdmin
local LibStub = _G.LibStub
local MiniMapButton = {}
AcoBidAdmin.MiniMapButton = MiniMapButton
local ALButton = LibStub("LibDBIcon-1.0")

local TT_H_1, TT_H_2 = "|cffFFA500AcoTools|r", string.format("|cffFFFFFFv%s|r", AcoBidAdmin.version)
local TT_ENTRY = "|cFFCFCFCF%s:|r %s" --|cffFFFFFF%s|r"

-- LDB
if not LibStub:GetLibrary("LibDataBroker-1.1", true) then return end

local menu = MenuClass:New()

menu:AddItem('DKP Tools',nil,true)
menu:AddItem('Bids Window', function()
	AcoBidAdmin.openbidswindow()
end)

menu:AddItem('DKP Info',nil,false,{
    hasArrow = true,
    menuList = {
        {notCheckable=true, text = "Host DKP", func = function() AcoBidAdmin:opendkpwindow() end },
        {notCheckable=true, isTitle=true, text = ""},
        {notCheckable=true, text = "My DKP", func = function() AcoBidAdmin:opendkpwindow(UnitName("player")) end },
        {notCheckable=true, isTitle=true, text = ""},
        {notCheckable=true, text = "Druid DKP", func = function() AcoBidAdmin:opendkpwindow("Druid") end },
        {notCheckable=true, text = "Hunter DKP", func = function() AcoBidAdmin:opendkpwindow("Hunter") end },
        {notCheckable=true, text = "Mage DKP", func = function() AcoBidAdmin:opendkpwindow("Mage") end },
        {notCheckable=true, text = "Paladin DKP", func = function() AcoBidAdmin:opendkpwindow("Paladin") end },
        {notCheckable=true, text = "Priest DKP", func = function() AcoBidAdmin:opendkpwindow("Priest") end },
        {notCheckable=true, text = "Rogue DKP", func = function() AcoBidAdmin:opendkpwindow("Rogue") end },
        {notCheckable=true, text = "Shaman DKP", func = function() AcoBidAdmin:opendkpwindow("Shaman") end },
        {notCheckable=true, text = "Warlock DKP", func = function() AcoBidAdmin:opendkpwindow("Warlock") end },
        {notCheckable=true, text = "Warrior DKP", func = function() AcoBidAdmin:opendkpwindow("Warrior") end }
    }
})

menu:AddItem('Raid Tools',nil,true)

menu:AddItem('Keyword Invites', function()
	AcoBidAdmin:openscanwindow()
end)

menu:AddItem('List Invites', function()
	AcoBidAdmin:listInvites()
end)

menu:AddItem('Raid Roll', function()
	AcoBidAdmin:raidroll()
end)

menu:AddItem('Durability Check', function()
	AcoBidAdmin:durabilityCheck()
end)

menu:AddItem('Version Check', function()
	AcoBidAdmin:checkforaddon()
end)

menu:AddItem('Options',nil,true)
menu:AddItem('Window Reset', function()
	AcoBidAdmin:acobidReset()
end)

menu:AddItem('Toggle Minimap Button', function()
	MiniMapButton.Toggle()
end)

--Make an LDB object
local MiniMapLDB = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("AcoTools", {
	type = "launcher",
	text = "AcoTools",
	icon = "Interface\\Addons\\AcoTools\\icon",
	OnTooltipShow = function(tooltip)
		tooltip:AddDoubleLine(TT_H_1, TT_H_2);
		tooltip:AddLine(format(TT_ENTRY, "Left Click", "Toggle Bids Window"))
		tooltip:AddLine(format(TT_ENTRY, "Right Click", "Tools Menu"))
	end,
	OnClick = function(self, button)
		if button == "RightButton" then
			menu:Show()
		elseif button == "LeftButton" then
			AcoBidAdmin.openbidswindow()
		end
	end,
})

function MiniMapButton.Init()
	ALButton:Register("AcoTools", MiniMapLDB, AcoBid_Data.Minimap);
end

function MiniMapButton.ResetFrames()
	AcoBid_Data.Minimap.minimapPos = 218;
	ALButton:Refresh("AcoTools");
end

function MiniMapButton.Toggle()
	AcoBid_Data.Minimap.shown = not AcoBid_Data.Minimap.shown
	AcoBid_Data.Minimap.hide = not AcoBid_Data.Minimap.hide
	if not AcoBid_Data.Minimap.hide then
		ALButton:Show("AcoTools")
	else
		ALButton:Hide("AcoTools")
	end
end

function MiniMapButton.Options_Toggle()
	if AcoBid_Data.Minimap.shown then
		ALButton:Show("AcoTools")
		AcoBid_Data.Minimap.hide = nil
	else
		ALButton:Hide("AcoTools")
		AcoBid_Data.Minimap.hide = true
	end
end

function MiniMapButton.Lock_Toggle()
	if AcoBid_Data.Minimap.locked then
		ALButton:Lock("AcoTools");
	else
		ALButton:Unlock("AcoTools");
	end
end