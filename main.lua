local version = GetAddOnMetadata("AcoTools", "Version");

AcoBidAdmin = LibStub("AceAddon-3.0"):NewAddon("AcoBidAdmin", "AceConsole-3.0", "AceComm-3.0", "AceTimer-3.0", "AceSerializer-3.0")
AcoBidAdmin.version = version;
AcoBid_LootHistory = {}
local AceGUI = LibStub("AceGUI-3.0");
local deformat = LibStub("LibDeformat-3.0");
local LD = LibStub("LibDurability");

local AcoBiddings = {}
local eventStarted = false;
local checkFrame = nil;
local checkFramesep1 = nil;
local checkFramesep1text = nil;
local raidroster = {};
local raidroster_durability = {};
local checkSender = nil;
local AcoMasterBids = AceGUI:Create("FrameAco");
local AcoMasterItems = AceGUI:Create("FrameAco");
local bidIndicator = CreateFrame("Frame", nil, UIParent)
local AcoMasterBidsScroll = nil;
local AcoMasterItemsScroll = nil;
local biddingFrames = {};
local bidLinks = {};
local bidwinners = {};
local openBids = 0;
local previousBid = nil;
local Acodkp = {};
local AcoList = {}
local AcoScan = {}
local lootlist = {}
local lootLinks = {}
local classlist = {}
local selectedRanks = {}
local framesReset = {}
local inviteList = {}
local updateInviteList = nil
local selecttypes = {"MAIN-SPEC", "OFF-SPEC", "PVP/FARMING/MISC", "UNCONTESTED-ONLY"};
local myname = UnitName("player");
local realmname = "-"..string.gsub(GetRealmName(), " ", "");
FillLocalizedClassList(classlist)

function RandomNum(length)
	local res = ""
	for i = 1, length do
		res = res .. math.random(0, 9)
	end
	return res
end

function string:splitcsv( inSplitPattern, outResults )
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end

function frameResizeEvent(widget, frameID)
  if(not AcoBid_Data.FrameSettings[frameID]) then AcoBid_Data.FrameSettings[frameID] = {} end
  AcoBid_Data.FrameSettings[frameID]['bottom'] = widget.frame:GetBottom()
  AcoBid_Data.FrameSettings[frameID]['left'] = widget.frame:GetLeft()
  AcoBid_Data.FrameSettings[frameID]['width'] = widget.frame:GetWidth()
  AcoBid_Data.FrameSettings[frameID]['height'] = widget.frame:GetHeight()
end

function setFrameSize(frame, frameID, width, height)
  if(AcoBid_Data.FrameSettings[frameID]) then
    frame:SetWidth(AcoBid_Data.FrameSettings[frameID].width);
    frame:SetHeight(AcoBid_Data.FrameSettings[frameID].height);
    frame:SetPoint("BOTTOMLEFT", UIParent,"BOTTOMLEFT", AcoBid_Data.FrameSettings[frameID].left, AcoBid_Data.FrameSettings[frameID].bottom);
  else
    frame:SetWidth(width);
    frame:SetHeight(height);
  end

  framesReset[frameID] = function()
    frame:ClearAllPoints();
    frame:SetPoint("CENTER", UIParent,"CENTER", 0, 0);
  end

  frame:SetCallback("OnResize", function(widget) frameResizeEvent(widget, frameID) end)
end

function hideIndicator()
  --checks if all admin frames are closed before removing indicator
  local allHidden = true;
  for i,v in pairs(biddingFrames) do
    if(biddingFrames[i].frame.frame:IsShown()) then allHidden = false end
  end
  for i,v in pairs(AcoBiddings) do
    if(AcoBiddings[i].group.frame:IsShown()) then allHidden = false end
  end
  if(allHidden == true) then do_callback(0.25, function() bidIndicator:Hide() end) end
end

function AcoBidAdmin:OnInitialize()

  if not AcoBid_Data then
    AcoBid_Data = {
      ["FrameSettings"] = {},
      ["LocalData"] = {},
      ["WebData"] = {},
      ["Minimap"] = {},
    }
  end

  AcoBidAdmin.MiniMapButton.Init()
  LD:Register("AcoTools", durabilityCheckUpdate)
  
  AcoBidAdmin:RegisterChatCommand('bid', 'startbid');
  AcoBidAdmin:RegisterChatCommand('bidcheck', 'checkforaddon');
  AcoBidAdmin:RegisterChatCommand('bids', 'openbidswindow');
  AcoBidAdmin:RegisterChatCommand('dkp', 'opendkpwindow');
  -- AcoBidAdmin:RegisterChatCommand('item', 'addManualLoot');
  AcoBidAdmin:RegisterChatCommand('invitelist', 'listInvites');
  AcoBidAdmin:RegisterChatCommand('invitescan', 'openscanwindow');
  AcoBidAdmin:RegisterChatCommand('raidroll', 'raidroll');
  --AcoBidAdmin:RegisterChatCommand('itemcheck', 'ItemCheck');
  AcoBidAdmin:RegisterChatCommand('commonloot', 'commonLoot');
  AcoBidAdmin:RegisterChatCommand('durabilitycheck', 'durabilityCheck');
  AcoBidAdmin:RegisterChatCommand('acobidreset', 'acobidReset');
  AcoBidAdmin:RegisterChatCommand('acobidminimap', 'acobidMinimap');

  print('|cFFDAB812Type /acohelp for available AcoTools commands|r')
  AcoBidAdmin:RegisterChatCommand('acohelp', function()
  
    print([[|n|cFFDAB812Commands available for AcoTools|r
|cFF69FAF5/bids|r → Opens the bids window
|cFF69FAF5/bid [itemlink] minbid|r → Starts bidding for item
|cFF69FAF5/bidcheck|r → Does addon check for raid members
|cFF69FAF5/dkp|r → Opens dkp window
|cFF69FAF5/dkp playername|r → Checks dkp of playername if dkp is hosted
|cFF69FAF5/dkp classname|r → Checks dkp of classname if dkp is hosted
|cFF69FAF5/durabilitycheck|r → Does durability check for raid members
|cFF69FAF5/invitescan|r → Opens invite keyword window for self-service raid invites
|cFF69FAF5/invitelist|r → Opens invite list window for csv import invites
|cFF69FAF5/acobidreset|r → Resets the acobid windows back to the center of your screen
|cFF69FAF5/acobidminimap|r → Toggles minimap button
|cFF69FAF5/raidroll|r → Rolls a random person in your raid group
|cFF69FAF5/commonloot|r → Sets common loot threshold to group or master]])

--|cFF69FAF5/item [itemlink]|r → Manually add item to loot frame

  end);

  AcoBidAdmin:RegisterComm("AcoBidStart", "AcoBidStartCallback")
  AcoBidAdmin:RegisterComm("AcoBidCheck", "AcoBidCheckCallback")
  AcoBidAdmin:RegisterComm("AcoBidReturn", "AcoBidReturnCallback")
  AcoBidAdmin:RegisterComm("AcoDKPCheck", "AcoDKPCheckCallback")
  AcoBidAdmin:RegisterComm("AcoDKPHost", "AcoDKPHostCallback")
  AcoBidAdmin:RegisterComm("AcoDKPGet", "AcoDKPGetCallback")
  AcoBidAdmin:RegisterComm("AcoDKPAdjust", "AcoDKPAdjustCallback")
  AcoBidAdmin:RegisterComm("AcoBidCanLoot", "AcoBidCanLootCallback")
  -- AcoBidAdmin:RegisterComm("AcoBidItem", "AcoBidItemCallback")
  -- AcoBidAdmin:RegisterComm("AcoBidItemR", "AcoBidItemRCallback")
  -- AcoBidAdmin:RegisterComm("AcoBidItemAdd", "AcoBidItemAddCallback")

  bidIndicator:SetFrameStrata("TOOLTIP")
  bidIndicator:SetWidth(10)
  bidIndicator:SetHeight(10)

  bidIndicator.texture = bidIndicator:CreateTexture()
  bidIndicator.texture:SetAllPoints(bidIndicator)
  bidIndicator.texture:SetColorTexture(255,0,0,1)
  
  bidIndicator:SetPoint("TOPLEFT", "UIParent", "TOPLEFT",0,0)
  bidIndicator:Hide()

  AcoMasterBids:SetTitle("AcoTools v"..version);
  setFrameSize(AcoMasterBids, 'MasterBids', 300, 300)
  AcoMasterBids:SetLayout("Flow")
  AcoMasterBids.frame:SetMinResize(200, 100)
  AcoMasterBids.content:SetPoint("BOTTOMRIGHT", -17, 27)
  AcoMasterBids.statusbg:Hide();
  AcoMasterBids.closebutton:Hide();

  AcoMasterBids:SetCallback("OnClose", function(widget)
    print("You can re-open the bids window at any time using /bids")
  end)

  local button1 = AceGUI:Create("Button")
  button1:SetText("Loot")
  button1:SetRelativeWidth(0.332);
  button1:SetDisabled(true);
  AcoMasterBids:AddChild(button1)

  local button2 = AceGUI:Create("Button")
  button2:SetText("DKP")
  button2:SetRelativeWidth(0.332);
  AcoMasterBids:AddChild(button2)

  local button3 = AceGUI:Create("Button")
  button3:SetText("Close")
  button3:SetRelativeWidth(0.332);
  AcoMasterBids:AddChild(button3)

  local sep1 = AceGUI:Create("Heading")
  sep1:SetRelativeWidth(1);
  AcoMasterBids:AddChild(sep1)

  local scrollcontainer = AceGUI:Create("SimpleGroup")
  scrollcontainer:SetFullWidth(true)
  scrollcontainer:SetFullHeight(true)
  scrollcontainer:SetLayout("Fill")

  AcoMasterBids:AddChild(scrollcontainer)

  local scroll = AceGUI:Create("ScrollFrame")
  scroll:SetLayout("List")
  scrollcontainer:AddChild(scroll)

  AcoMasterBidsScroll = scroll;
  AcoMasterBids.frame:Hide();

  button1:SetCallback("OnClick", function(widget)
    AcoMasterItems.frame:Show();
  end)

  button2:SetCallback("OnClick", function(widget)
    AcoBidAdmin:opendkpwindow()
  end)

  button3:SetCallback("OnClick", function(widget)
    AcoMasterBids.frame:Hide();
  end)

  AcoMasterBids.frame:RegisterEvent("GROUP_ROSTER_UPDATE");
  AcoMasterBids.frame:RegisterEvent("PLAYER_ENTERING_WORLD");
  AcoMasterBids.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
  AcoMasterBids.frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
  AcoMasterBids.frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
  AcoMasterBids.frame:RegisterEvent("TRADE_SHOW");
  AcoMasterBids.frame:RegisterEvent("TRADE_CLOSED");
  AcoMasterBids.frame:SetScript("OnEvent", eventHandler);

  AcoMasterItems:SetTitle("AcoTools Loot");
  setFrameSize(AcoMasterItems, 'MasterItems', 300, 300)
  AcoMasterItems:SetLayout("Flow")
  AcoMasterItems.frame:SetMinResize(200, 100)
  AcoMasterItems.content:SetPoint("BOTTOMRIGHT", -17, 27)
  AcoMasterItems.statusbg:Hide();

  local scrollcontainer2 = AceGUI:Create("SimpleGroup")
  scrollcontainer2:SetFullWidth(true)
  scrollcontainer2:SetFullHeight(true)
  scrollcontainer2:SetLayout("Fill")

  AcoMasterItems:AddChild(scrollcontainer2)

  local scroll2 = AceGUI:Create("ScrollFrame")
  scroll2:SetLayout("List")
  scrollcontainer2:AddChild(scroll2)

  AcoMasterItemsScroll = scroll2;
  AcoMasterItems.frame:Hide();
end

function AcoBidAdmin:commonLoot(input)

  if IsInRaid() == false then
    print('|cFFFF0000You must be in a raid')
    return false
  end

  if UnitIsGroupLeader("player") == false then
    print('|cFFFF0000You must be raid lead to change loot method.')
    return false
  end

  local loottype, extra = AcoBidAdmin:GetArgs(input, 2);

  if loottype == nil or (loottype ~= "group" and loottype ~= "master") or extra then
    print('|cFFFF0000Command /commonloot takes exactly 1 argument (master or group)')
    return false
  end

  if loottype == "group" then SetLootMethod(loottype,"1") end
  if loottype == "master" then

    local lootmethod, masterlooterPartyID, masterlooterRaidID = GetLootMethod()

    if lootmethod == "master" then
      local name = GetRaidRosterInfo(masterlooterRaidID);
      SetLootMethod(loottype,name,"1")
    else
      SetLootMethod(loottype,"player","1")
    end
  end
end

function AcoBidAdmin:durabilityCheck(input)

  if IsInRaid() == false then
    print('|cFFFF0000You must be in a raid')
    return false
  end

  if(durabilityFrame) then durabilityFrame.frame:Hide() end
  durabilityFrame = nil;
  raidroster_durability = {};
  checkSender = nil;

  local frame = AceGUI:Create("FrameAco");
  frame:SetTitle("AcoTools Durability");
  setFrameSize(frame, 'durabilityFrame', 300, 300)
  frame:SetLayout("Flow")
  frame.frame:SetMinResize(300, 100)
  frame.statusbg:Hide();
  durabilityFrame = frame;

  local scrollcontainer = AceGUI:Create("SimpleGroup")
  scrollcontainer:SetFullWidth(true)
  scrollcontainer:SetFullHeight(true)
  scrollcontainer:SetLayout("Fill")

  frame:AddChild(scrollcontainer)

  local scroll = AceGUI:Create("ScrollFrame")
  scroll:SetLayout("List")
  scrollcontainer:AddChild(scroll)

  for i = 1, 40 do
    name = GetRaidRosterInfo(i);
    if name ~= nil then
      local names = AceGUI:Create("InteractiveLabel")

      if(UnitIsConnected(string.gsub(name, realmname, ""))) then
        names:SetText('|cFFFF0000'..string.gsub(name, realmname, ""));
      else
        names:SetText('|cFF9C9C9C'..string.gsub(name, realmname, ""));
      end

      names:SetImage("Interface\\RaidFrame\\ReadyCheck-Waiting");
      names:SetFont(GameFontNormal:GetFont());
      names:SetRelativeWidth(1);
      names:SetImageSize(17, 17)
      scroll:AddChild(names);

      table.insert(raidroster_durability, {['name'] = string.gsub(name, realmname, ""), ["percent"] = nil, ["broken"] = 0, label = names})
    end
  end

  LD:RequestDurability('RAID')

end

function durabilityCheckUpdate(percent, broken, sender, channel)

  for i = 1, #raidroster_durability do
    if raidroster_durability[i].name == sender then
      raidroster_durability[i].percent = math.floor(percent);
      raidroster_durability[i].broken = broken;
    end
  end

  for i = 1, #raidroster_durability do
    if(not UnitIsConnected(string.gsub(raidroster_durability[i].name, realmname, "")) or raidroster_durability[i].percent == nil) then
      raidroster_durability[i].label:SetText('|cFF9C9C9C'..string.gsub(raidroster_durability[i].name, realmname, ""));
      raidroster_durability[i].label:SetImage("Interface\\RaidFrame\\ReadyCheck-Waiting");
    elseif(raidroster_durability[i].broken > 0) then
      raidroster_durability[i].label:SetText('|cFFFF0000'..raidroster_durability[i].name..'|r - '..raidroster_durability[i].broken..' broken');
      raidroster_durability[i].label:SetImage("Interface\\RaidFrame\\ReadyCheck-NotReady");
    else
      raidroster_durability[i].label:SetText('|cFF00FF00'..raidroster_durability[i].name..'|r - '..raidroster_durability[i].percent..'%');
      raidroster_durability[i].label:SetImage("Interface\\RaidFrame\\ReadyCheck-Ready");
    end
  end

end

function AcoBidAdmin:acobidReset()
  AcoBid_Data.FrameSettings = {}

  for k, v in pairs(framesReset) do
    if framesReset[k] then framesReset[k]() end
  end
end

function AcoBidAdmin:acobidMinimap()
  AcoBidAdmin.MiniMapButton.Toggle()
end

function AcoBidAdmin:startbid(input)
  if IsInRaid() == false then
    print('|cFFFF0000You must be in a raid')
    return false
  end

  if UnitIsGroupLeader("player") == false and UnitIsGroupAssistant("player") == false then
    print('|cFFFF0000You must be raid assist or lead to initiate bidding.')
    return false
  end
  
  local itemLink, minBid, extra = AcoBidAdmin:GetArgs(input, 3);

  if itemLink == nil or minBid == nil or extra then
    print('|cFFFF0000Command /bid takes exactly 2 arguments (itemlink, minimumbid)')
    return false
  end

  local isitemlink = string.match(itemLink, '(%|Hitem%:)');
  if isitemlink == nil then
    print('|cFFFF0000First argument must be an item link')
    return false
  end

  if tonumber(minBid) == nil then
    print('|cFFFF0000Second argument must be an integer')
    return false
  elseif tonumber(minBid) > 9999 then
    print('|cFFFF00009999 is the largest argument accepted for miniumum bid')
    return false
  end

  if string.len(minBid) > 50 then
    print('|cFFFF0000Arguments must be 50 characters or less')
    return false
  end

  if not Acodkp.hasHost and not Acodkp.host then
    AcoBidAdmin:opendkpwindow()
    print('|cFFFF0000DKP is not being hosted')
    return false
  end

  local BID = RandomNum(8);
  local TimerLength = tonumber(GetAddOnMetadata("AcoTools", "X-BidTime"));
  if TimerLength == nil then
    TimerLength = 90 --default back to 90 seconds if none set in toc
  end
  AcoBiddings["BID-ID:"..BID] = {};
  local modinput = input.." BID-ID:"..BID.." "..TimerLength;
  SendChatMessage('[AcoTools] Bidding started for '..itemLink..'! If you do not see the item in the bids window, please say something.', "RAID");
  
  AcoBidAdmin:SendCommMessage("AcoBidStart", modinput, "RAID")

  --send bid start every 5 seconds for those who were reloading or logged out or something
  local timerCount = TimerLength;
  local timer = AcoBidAdmin:ScheduleRepeatingTimer(function()
    timerCount = timerCount - 5;
    if timerCount < 0 then
      return false
    end
    if timerCount == 0 then
      AcoBidAdmin:CancelTimer(timer);
    else
      modinput = input.." BID-ID:"..BID.." "..timerCount;
      AcoBidAdmin:SendCommMessage("AcoBidStart", modinput, "RAID")
    end
  end, 5)

  OpenBiddingFrame(modinput)
end

function AcoBidAdmin:checkforaddon(input)
  if(checkFrame) then checkFrame.frame:Hide() end
  checkFrame = nil;
  raidroster = {};
  checkSender = nil;

  local frame = AceGUI:Create("FrameAco");
  frame:SetTitle("AcoTools Version Check");
  setFrameSize(frame, 'checkFrame', 300, 300)
  frame:SetLayout("Flow")
  frame.frame:SetMinResize(300, 100)
  frame.statusbg:Hide();
  checkFrame = frame;

  local scrollcontainer = AceGUI:Create("SimpleGroup")
  scrollcontainer:SetFullWidth(true)
  scrollcontainer:SetFullHeight(true)
  scrollcontainer:SetLayout("Fill")

  frame:AddChild(scrollcontainer)

  local scroll = AceGUI:Create("ScrollFrame")
  scroll:SetLayout("List")
  scrollcontainer:AddChild(scroll)

  for i = 1, 40 do
    name = GetRaidRosterInfo(i);
    if name ~= nil then
      local names = AceGUI:Create("InteractiveLabel")

      if(UnitIsConnected(string.gsub(name, realmname, ""))) then
        names:SetText('|cFFFF0000'..string.gsub(name, realmname, ""));
        names:SetImage("Interface\\RaidFrame\\ReadyCheck-NotReady");
        names:SetHighlight("Interface\\Buttons\\UI-Listbox-Highlight");
      else
        names:SetText('|cFF9C9C9C'..string.gsub(name, realmname, ""));
        names:SetImage("Interface\\RaidFrame\\ReadyCheck-Waiting");
      end

      names:SetFont(GameFontNormal:GetFont());
      names:SetRelativeWidth(1);
      names:SetImageSize(17, 17)
      scroll:AddChild(names);

      table.insert(raidroster, {['name'] = string.gsub(name, realmname, ""), ['addon'] = false, label = names})
    end
  end

  AcoBidAdmin:SendCommMessage("AcoBidCheck", "AcoBidCheck", "RAID")
end

function AcoBidAdmin:openbidswindow(input)
  if AcoMasterBids.frame:IsShown() then
    AcoMasterBids.frame:Hide();
  else
    AcoMasterBids.frame:Show();
  end
end

function AcoBidAdmin:AcoBidStartCallback(name,input,distribution,sender)
  local itemLink, minBid, bidID, timer_amount = AcoBidAdmin:GetArgs(input, 5);
  
  --already have this item, ignore request
  if(biddingFrames[bidID] or bidLinks[bidID]) then
    return false;
  end

  AddItemToMaster(itemLink,minBid,sender,bidID, timer_amount)
  
  if sender == myname then
    return false;
  end
  
  biddingFrames[bidID] = {};
  AddItemToFrame(itemLink,minBid,sender,bidID, timer_amount)
end

function AcoBidAdmin:AcoBidItemAddCallback(name,input,distribution,sender)
  local success, itemData = AcoBidAdmin:Deserialize(input)
  
  if not AcoBid_LootHistory[itemData.unit] then AcoBid_LootHistory[itemData.unit] = {} end
  table.insert(AcoBid_LootHistory[itemData.unit], {["link"]=itemData.link, ["quality"]=itemData.quality, ["uid"]=itemData.uid})

  updateItemsWindow()
end

function AcoBidAdmin:AcoBidCheckCallback(name,input,distribution,sender)
  checkSender = sender
  AcoBidAdmin:SendCommMessage("AcoBidReturn", version, "RAID")
end

function AcoBidAdmin:AcoBidReturnCallback(name,input,distribution,sender)
  
  if checkSender ~= myname then
    return false;
  end

  for i = 1, #raidroster do
    if raidroster[i].name == sender then
      raidroster[i].addon = true;
      raidroster[i].version = input;
    end
  end

  local message = '';
  for i = 1, #raidroster do
    if UnitIsConnected(raidroster[i].name) then
      if raidroster[i].addon then
        if raidroster[i].version == version then
          raidroster[i].label:SetText('|cFF00FF00'..raidroster[i].name);
          raidroster[i].label:SetHighlight("");
          raidroster[i].label:SetImage("Interface\\RaidFrame\\ReadyCheck-Ready");
          raidroster[i].label:SetCallback("OnClick", function(widget) end)
        else
          raidroster[i].label:SetCallback("OnClick", function(widget)
            SendChatMessage('[AcoTools] Your version of AcoTools is out-of-date! Your version v'..raidroster[i].version..' - Current version v'..version, "WHISPER", "Common", raidroster[i].name);
          end)
          raidroster[i].label:SetImage("Interface\\Buttons\\UI-OptionsButton");
          raidroster[i].label:SetText('|cFFFFA500'..raidroster[i].name..'|r - v'..raidroster[i].version);
        end
      else
        raidroster[i].label:SetCallback("OnClick", function(widget)
          SendChatMessage('[AcoTools] Please install our required addon AcoTools v'..version..'. A link can be found pinned to the #wow_addons channel in Discord.', "WHISPER", "Common", raidroster[i].name);
        end)
      end
    end
  end
end

function OpenBiddingFrame(input)
  local itemLink, minBid, bidID, timer_amount = AcoBidAdmin:GetArgs(input, 5);

  local frame = AceGUI:Create("FrameAco");
  frame:SetTitle("AcoTools v"..version);
  frame:SetStatusText(timer_amount.." Seconds left to bid...")
  setFrameSize(frame, 'BidAdmin', 500, 500)
  frame:SetLayout("Flow")
  frame.frame:Hide();

  frame:SetCallback("OnClose", function(widget, event, key, checked)
    hideIndicator()
  end)

  local scrollcontainer = AceGUI:Create("SimpleGroup")
  scrollcontainer:SetFullWidth(true)
  scrollcontainer:SetFullHeight(true)
  scrollcontainer:SetLayout("Fill")

  frame:AddChild(scrollcontainer)

  local scroll = AceGUI:Create("ScrollFrame")
  scroll:SetLayout("Flow")
  scrollcontainer:AddChild(scroll)

  local sep1 = AceGUI:Create("Heading")
  sep1:SetText(itemLink)
  sep1:SetRelativeWidth(1);
  scroll:AddChild(sep1)
  AcoBiddings[bidID].itemLink = itemLink;

  local details1 = AceGUI:Create("Label")
  details1:SetText("|cffffd100Minimum Bid: " .. minBid .. " DKP");
  details1:SetRelativeWidth(1);
  details1:SetFont(GameFontNormal:GetFont());
  scroll:AddChild(details1)

  -- local details2 = AceGUI:Create("Label")
  -- details2:SetText("|cffffd100Priority: " ..lootPriority);
  -- details2:SetRelativeWidth(1);
  -- details2:SetFont(GameFontNormal:GetFont());
  -- scroll:AddChild(details2)

  local editbox = AceGUI:Create("EditBox")
  editbox:SetLabel("Winner")
  editbox:SetRelativeWidth(0.25);
  editbox:DisableButton(true);
  editbox:SetText('')
  scroll:AddChild(editbox)
  AcoBiddings[bidID].winner = editbox;

  local editbox2 = AceGUI:Create("EditBox")
  editbox2:SetLabel("Amount")
  editbox2:SetRelativeWidth(0.25);
  editbox2:DisableButton(true);
  editbox2:SetText('')
  scroll:AddChild(editbox2)
  AcoBiddings[bidID].winningbid = editbox2;

  local editbox3 = AceGUI:Create("EditBox")
  editbox3:SetLabel("Bidding For")
  editbox3:SetRelativeWidth(0.25);
  editbox3:DisableButton(true);
  editbox3:SetText('')
  scroll:AddChild(editbox3)
  AcoBiddings[bidID].winningspec = editbox3;

  local button = AceGUI:Create("Button")
  button:SetText("Announce")
  button:SetRelativeWidth(0.25);
  scroll:AddChild(button)

  button:SetCallback("OnClick", function(widget)

    local message = "Congrats "..string.gsub(editbox:GetText(), realmname, "").." "..itemLink.." "..editbox2:GetText().." DKP! ("..editbox3:GetText()..")";
    SendChatMessage(message, "RAID_WARNING");

    local itemtext = itemLink.."|cFFFFA501\n"..string.gsub(editbox:GetText(), realmname, "");
    if string.len(editbox2:GetText()) > 0 then
      itemtext = itemtext..' | '..editbox2:GetText();
    end

    if string.len(editbox3:GetText()) > 0 then
      itemtext = itemtext ..' | '..editbox3:GetText();
    end
    bidLinks[bidID].text = itemtext;
    bidLinks[bidID]:SetText(itemtext);

    bidwinners[bidID] = string.gsub(editbox:GetText(), realmname, "");
    
    AcoBidAdmin:SendCommMessage("AcoDKPAdjust", AcoBidAdmin:Serialize(bidID, string.gsub(editbox:GetText(), realmname, ""), (tonumber(editbox2:GetText()) or 0)), "RAID")

    do_callback(0.5, function() Screenshot() end)
  end)

  local sep2 = AceGUI:Create("Heading")
  sep2:SetText("Bids")
  sep2:SetRelativeWidth(1);
  scroll:AddChild(sep2)

  AcoBiddings[bidID].group = frame;
  AcoBiddings[bidID].scroll = scroll;
  AcoBiddings[bidID].bids = {}
  AcoBiddings[bidID].temp = {}
  AcoBiddings[bidID].checks = {};

  if eventStarted == false then
    frame.frame:RegisterEvent("CHAT_MSG_WHISPER");
    frame.frame:SetScript("OnEvent", ProcessBid);
    eventStarted = true;
  end
  
  local timerCount = timer_amount;
  local timer = AcoBidAdmin:ScheduleRepeatingTimer(function()
    timerCount = timerCount - 1;
    if timerCount <= 0 then
      AcoBidAdmin:CancelTimer(timer);
      AcoBiddings[bidID].closed = true;
      frame:SetStatusText("Bids Closed!");
    else
      frame:SetStatusText(timerCount .. " Seconds left to bid...")
    end
  end, 1)

end

function ProcessBid(self, event, msg, player)
  if event ~= "CHAT_MSG_WHISPER" then
    return false;
  end

  local bidID, itemLink, bidType, bidAmount, dkpAmount = AcoBidAdmin:GetArgs(msg, 6);

  dkpAmount = dkpAmount or "FALSE"

  bidID = string.match(bidID, '^%[(BID%-ID%:%d%d%d%d%d%d%d%d)%]$')
  if bidID and AcoBiddings[bidID] then

    if AcoBiddings[bidID].closed then
      return false;
    end

    local new = true;
    for i = 1, #AcoBiddings[bidID].bids do
      local b = AcoBiddings[bidID].bids[i];
      if player == b.player then
        new = false;
        AcoBiddings[bidID].bids[i] = {['player']=player, ['bidType']=bidType, ['bidAmount']=bidAmount, ['dkpAmount']=dkpAmount};
      end
    end

    if new then
      table.insert(AcoBiddings[bidID].bids, {['player']=player, ['bidType']=bidType, ['bidAmount']=bidAmount, ['dkpAmount']=dkpAmount})
    end

    local receipt = "[AcoTools] Bid Updated: ".. AcoBiddings[bidID].itemLink .. " - " .. bidAmount .. " DKP";
    if tonumber(bidAmount) <= 0 then
      receipt = "[AcoTools] Bid Canceled : ".. AcoBiddings[bidID].itemLink;
    elseif new then
      receipt = "[AcoTools] Bid Accepted: ".. AcoBiddings[bidID].itemLink .. " - " .. bidAmount .. " DKP";
    end

    SendChatMessage(receipt .. " (you may update your bid until the bidding time runs out)", "WHISPER", "Common", player);

    for i = 1, #AcoBiddings[bidID].temp do
      AcoBiddings[bidID].temp[i]:ReleaseChildren();
      AcoBiddings[bidID].temp[i]:SetHeight(0);
      AcoBiddings[bidID].temp[i]:SetRelativeWidth(0.000000000001);
      AcoBiddings[bidID].temp[i].frame:Hide();
      AcoBiddings[bidID].temp[i].frame:SetScale(0.0001);
    end
    AcoBiddings[bidID].temp = {}

    table.sort(AcoBiddings[bidID].bids, function(a,b)
      local index_a = 1;
      local index_b = 1;

      for i = 1, #selecttypes do
        if(selecttypes[i] == a.bidType) then index_a = i end
        if(selecttypes[i] == b.bidType) then index_b = i end
      end

      if(index_a ~= index_b) then
        return index_a < index_b
      else
        return tonumber(a.bidAmount) > tonumber(b.bidAmount)
      end
      
    end)

    for i = 1, #AcoBiddings[bidID].bids do
      local b = AcoBiddings[bidID].bids[i];
      table.insert(AcoBiddings[bidID].temp, AddBidder(bidID, AcoBiddings[bidID].scroll, b.player, b.bidType, b.bidAmount, b.dkpAmount, i%2~=0))
    end

  end
end

function AddBidder(bidID, parent, name_str, spec_str, bid_str, dkp_str, odd)
  local group = AceGUI:Create("SimpleGroup")
  group:SetRelativeWidth(1);
  group:SetLayout("Flow")
  if odd then
    group.frame.texture = group.frame:CreateTexture()
    group.frame.texture:SetAllPoints(group.frame)
    group.frame.texture:SetColorTexture(1,1,1,0.1)
  end

  local choose = AceGUI:Create("CheckBox")
  choose:SetWidth(25);
  group:AddChild(choose);
  table.insert(AcoBiddings[bidID].checks, choose)

  choose:SetCallback("OnValueChanged", function(widget)
    for i = 1, #AcoBiddings[bidID].checks do
      AcoBiddings[bidID].checks[i]:SetValue(false);
    end
    choose:SetValue(true);
    AcoBiddings[bidID].winner:SetText(name_str);
    AcoBiddings[bidID].winningbid:SetText(bid_str);
    AcoBiddings[bidID].winningspec:SetText(spec_str);
  end)

  localizedClass, englishClass = UnitClass(string.gsub(name_str, realmname, ""));
  rPerc, gPerc, bPerc, argbHex = GetClassColor(englishClass)

  local name = AceGUI:Create("InteractiveLabel")
  name:SetText("|c"..argbHex..name_str);
  name:SetFont(GameFontNormal:GetFont());
  name:SetRelativeWidth(0.35);
  group:AddChild(name);

  local spec = AceGUI:Create("InteractiveLabel")
  spec:SetText(spec_str);
  spec:SetFont(GameFontNormal:GetFont());
  spec:SetRelativeWidth(0.45);
  group:AddChild(spec);

  local bid = AceGUI:Create("InteractiveLabel")
  if(dkp_str == "FALSE" or tonumber(bid_str) <= tonumber(dkp_str)) then
    bid:SetText(bid_str);
  else
    bid:SetText("|cffff0000"..bid_str);
  end
  bid:SetFont(GameFontNormal:GetFont());
  bid:SetRelativeWidth(0.1);
  group:AddChild(bid);

  parent:AddChild(group)
  return group;
end

function AddItemToFrame(itemLink,minBid,sender,bidID, timer_amount)

  local itemID, itemType, itemSubType, itemEquipLoc, icon = GetItemInfoInstant(itemLink)

  local frame = AceGUI:Create("FrameAco");
  frame:SetTitle("AcoTools v"..version);
  frame:SetStatusText(timer_amount.." Seconds left to bid...")
  setFrameSize(frame, 'BidItem', 400, 270)
  frame.frame:SetMinResize(400, 270)
  frame.frame:Hide();

  local group = AceGUI:Create("SimpleGroup")
  group:SetRelativeWidth(1);
  group:SetLayout("Flow")

  local item = AceGUI:Create("InteractiveLabel")
  item:SetText(itemLink);
  item:SetFont(GameFontNormal:GetFont());
  item:SetImage(icon);
  item:SetImageSize(30, 30)
  item:SetRelativeWidth(1);
  item:SetHighlight("Interface\\Buttons\\UI-Listbox-Highlight");
  group:AddChild(item)

  item:SetCallback("OnEnter", function(widget)
    ShowTooltip(item.frame, itemLink)
  end)

  item:SetCallback("OnLeave", function(widget)
    GameTooltip:Hide();
  end)

  item:SetCallback("OnClick", function(widget, event, button)
    if IsControlKeyDown() then
      DressUpItemLink(itemLink);
      return false;
    end
  end)

  local sep1 = AceGUI:Create("Heading")
  sep1:SetText('')
  sep1:SetRelativeWidth(1);
  group:AddChild(sep1)

  local details1 = AceGUI:Create("Label")
  details1:SetText("|cffffd100Minimum Bid: " .. minBid .. " DKP");
  details1:SetRelativeWidth(1);
  details1:SetFont(GameFontNormal:GetFont());
  group:AddChild(details1)

  -- local details2 = AceGUI:Create("Label")
  -- details2:SetText("|cffffd100Priority: " ..lootPriority);
  -- details2:SetRelativeWidth(1);
  -- details2:SetFont(GameFontNormal:GetFont());
  -- group:AddChild(details2)

  local details3 = AceGUI:Create("Label")
  details3:SetText("|cffffd100Available DKP: |cFFFF7D0A(attempting to fetch...)");
  details3:SetRelativeWidth(1);
  details3:SetFont(GameFontNormal:GetFont());
  group:AddChild(details3)

  local editbox = AceGUI:Create("EditBox")
  editbox:SetLabel("Bid amount: |cffff0000*")
  editbox:SetRelativeWidth(0.5);
  editbox:DisableButton(true);
  editbox:SetMaxLetters(4);
  group:AddChild(editbox)

  local selectbox = AceGUI:Create("Dropdown")
  selectbox:SetLabel("Bidding for: |cffff0000*")
  selectbox:SetRelativeWidth(0.5);
  selectbox:SetList(selecttypes);
  group:AddChild(selectbox)

  local button = AceGUI:Create("Button")
  button:SetText("Send Bid")
  button:SetRelativeWidth(1);
  button:SetDisabled(true)
  group:AddChild(button)

  local errors = AceGUI:Create("Label")
  errors:SetFont(GameFontNormal:GetFont());
  errors:SetRelativeWidth(1);
  group:AddChild(errors)

  frame:AddChild(group)

  biddingFrames[bidID].frame = frame;
  biddingFrames[bidID].dkp = details3;

  AcoBidAdmin:SendCommMessage("AcoDKPGet", bidID, "RAID")

  biddingFrames[bidID]['timer'] = true;
  biddingFrames[bidID]['timerrunning'] = true;
  AcoBidAdmin:ScheduleTimer(function() 
    biddingFrames[bidID].timerrunning = false;
    if(biddingFrames[bidID].timer) then
      details3:SetText("|cffffd100Available DKP: |cffff0000(couldn't fetch data)");  
    end
  end, 3)

  local timerCount = timer_amount;
  local timer = AcoBidAdmin:ScheduleRepeatingTimer(function()
    timerCount = timerCount - 1;
    if timerCount <= 0 then
      AcoBidAdmin:CancelTimer(timer);
      frame:SetStatusText("Bids Closed!");
      button:SetDisabled(true)
    else
      frame:SetStatusText(timerCount .. " Seconds left to bid...")
    end
  end, 1)

  local bidGood = false;
  local typeGood = false;
  editbox:SetCallback("OnTextChanged", function(widget)

    if tonumber(editbox:GetText()) == nil then
      errors:SetText("|cffff0000Error: Bid must be an integer!");
      bidGood = false;
      button:SetDisabled(true)
    else
      errors:SetText("");
      bidGood = true;
      if typeGood and timerCount > 0 then
        button:SetDisabled(false)
      end
    end

  end)

  selectbox:SetCallback("OnValueChanged", function(widget)

    if selecttypes[selectbox:GetValue()] == nil then
      typeGood = false;
      button:SetDisabled(true)
    else
      typeGood = true;
      if bidGood and timerCount > 0 then
        errors:SetText("");
        button:SetDisabled(false)
      end
    end

  end)

  button:SetCallback("OnClick", function(widget)

    if typeGood and bidGood and timerCount > 0 then
      local message = '['..bidID..'] '..itemLink..' "'..selecttypes[selectbox:GetValue()]..'" '..tonumber(editbox:GetText()).." "..(biddingFrames[bidID].dkpamount or 'FALSE');
      if previousBid then
        if previousBid == message then
          errors:SetText('|cFFFF0000You\'ve already sent a bid with that value.')
        else
          previousBid = message;
          errors:SetText('')
          SendChatMessage(message, "WHISPER", "Common", sender);
        end
      else
        previousBid = message;
        errors:SetText('')
        SendChatMessage(message, "WHISPER", "Common", sender);
      end
    end

  end)

end

function AddItemToMaster(itemLink,minBid,sender,bidID, timer_amount)
  openBids = openBids + 1;



  AcoMasterBids.frame:Show()

  local itemID, itemType, itemSubType, itemEquipLoc, icon = GetItemInfoInstant(itemLink)

  function getItemText(itemLink,time,item)
    if string.match(item.text, "FFFFA501") then return item.text end

    local msg = itemLink.."|cFFFFA500";
    if time == nil then
      msg = msg .. "\n"..timer_amount.."s left to bid..."
    elseif time == 'done' then
      msg = msg .. "\nBids Closed!"
    else
      msg = msg .. "\n"..time.."s left to bid..."
    end
    item.text = msg
    return msg
  end

  local item = AceGUI:Create("InteractiveLabel")
  item.text = '';
  item:SetText(getItemText(itemLink,nil,item));
  item:SetImage(icon);
  item:SetImageSize(25, 25)
  item:SetRelativeWidth(1);
  item:SetHighlight("Interface\\Buttons\\UI-Listbox-Highlight");
  AcoMasterBidsScroll:AddChild(item)
  bidLinks[bidID] = item;

  item.frame.texture = item.frame:CreateTexture("back", "BACKGROUND")
  item.frame.texture:SetAllPoints(item.frame)
  item.frame.texture:SetColorTexture(0,255,118,0)

  item:SetCallback("OnEnter", function(widget)
    ShowTooltip(item.frame, itemLink)
  end)
  
  item:SetCallback("OnLeave", function(widget)
    GameTooltip:Hide();
  end)

  item:SetCallback("OnClick", function(widget, event, button)
    
    if IsControlKeyDown() then
      DressUpItemLink(itemLink);
      return false;
    end

    if IsAltKeyDown() then

      if not bidwinners[bidID] then
        print('|cFFFF0000No winner selected!')
        return false
      end

      if not TradeFrame:IsShown() then
        print('|cFFFF0000You must trade '..bidwinners[bidID]..' first.')
        return false
      end

      for b = 0, NUM_BAG_SLOTS do
          for s = 1, GetContainerNumSlots(b) do
              if GetContainerItemID(b, s) == itemID then
                UseContainerItem(b,s,bidwinners[bidID])
                break
              end
          end
      end
      return false;
    end

    if biddingFrames[bidID] then
      if biddingFrames[bidID].frame.frame:IsShown() then
        biddingFrames[bidID].frame.frame:Hide();
        hideIndicator()
      else
        bidIndicator:Show()
        do_callback(0.25, function() biddingFrames[bidID].frame.frame:Show() end)
      end
    end

    if AcoBiddings[bidID] then
      if AcoBiddings[bidID].group.frame:IsShown() then
        AcoBiddings[bidID].group.frame:Hide();
        hideIndicator()
      else
        bidIndicator:Show()
        do_callback(0.25, function() AcoBiddings[bidID].group.frame:Show() end)
      end
    end
  end)

  local timerCount = timer_amount;
  local timer = AcoBidAdmin:ScheduleRepeatingTimer(function()
    timerCount = timerCount - 1;
    if timerCount < 0 then
      return false
    end
    if timerCount == 0 then
      AcoBidAdmin:CancelTimer(timer);
      openBids = openBids - 1;
      
      if sender ~= myname then
        item:SetText('');
        item:SetImage('');
        item.frame:Hide();
        item.frame:SetScale(0.0001);
      else
        item:SetText(getItemText(itemLink,'done',item));
      end

      if openBids <= 0 then
        AcoMasterBids.frame:Hide()
      end
    else
      item:SetText(getItemText(itemLink,timerCount,item));
    end
  end, 1)
end

function updateItemsWindow()
  AcoMasterItems.frame:Show()

  for source, items in pairs(AcoBid_LootHistory) do

    for i, lootItem in pairs(items) do
      local itemID, itemType, itemSubType, itemEquipLoc, icon = GetItemInfoInstant(lootItem.link)
      if(lootItem.quality == nil) then
        local _, _, itemQuality = GetItemInfo(itemID)
        lootItem.quality = itemQuality
      end

      function getItemText(itemLink,time,item)
        --if string.match(item.text, "FFFFA501") then return item.text end

        local msg = itemLink.."|cFFFFA500";
        if(time) then
          msg = msg .. "\n".."Item Queued | "..time
        else
          msg = msg .. "\n".."Item Queued | |cFFFF0000Alerts OFF"
        end
        item.text = msg
        return msg
      end

      if(lootLinks[lootItem.uid] == nil) then
        local item = AceGUI:Create("InteractiveLabel")
        item.text = '';
        item:SetText(getItemText(lootItem.link,nil,item));
        item:SetImage(icon);
        item:SetImageSize(25, 25)
        item:SetRelativeWidth(1);
        item:SetHighlight("Interface\\Buttons\\UI-Listbox-Highlight");
        lootLinks[lootItem.uid] = item;

        AcoMasterItemsScroll:AddChild(lootLinks[lootItem.uid])
  
        item:SetCallback("OnEnter", function(widget)
          ShowTooltip(item.frame, lootItem.link, "Dropped by "..source)
        end)
        
        item:SetCallback("OnLeave", function(widget)
          GameTooltip:Hide();
        end)
  
        item:SetCallback("OnClick", function(widget, event, button)
          
          if IsControlKeyDown() then
            DressUpItemLink(lootItem.link);
            return false;
          end
  
          if IsAltKeyDown() then
          end

          if lootItem['alerts'] then
            lootItem['alerts'] = false;
            item:SetText(getItemText(lootItem.link,'|cFFFF0000Alerts OFF',item));
          else
            lootItem['alerts'] = true;
            item:SetText(getItemText(lootItem.link,'|cFF00FF00Alerts ON',item));
          end
          
        end)
      end
    end
  end

end

function ShowTooltip(frame,itemLink,addline)
  GameTooltip:SetOwner(frame, 'ANCHOR_BOTTOM')
  GameTooltip:SetHyperlink(itemLink)
  if(addline ~= nil) then GameTooltip:AddLine(addline) end
  GameTooltip:Show();
end

function AcoBidAdmin:opendkpwindow(input)

  if IsInRaid() == false then
    print('|cFFFF0000You must be in a raid')
    return false
  end

  if(Acodkp.frame) then
    if Acodkp.frame:IsShown() then
      Acodkp.frame.frame:Hide()
      Acodkp.frame = false;
    end
  end

  local playername = nil
  if input then
    playername = AcoBidAdmin:GetArgs(input, 1);    
  end

  if(Acodkp.hasHost or playername) then
    if(playername) then
      if(Acodkp.timerrunning) then
        print('|cFFFF0000DKP query throttle!')
        return false
      end
      AcoBidAdmin:SendCommMessage("AcoDKPCheck", playername, "RAID")
      Acodkp['timer'] = true;
      Acodkp['timerrunning'] = true;
      AcoBidAdmin:ScheduleTimer(function() 
        Acodkp.timerrunning = false;
        if(Acodkp.timer) then
          print('|cFFFF0000No DKP response after 3 seconds! Someone needs to host DKP for queries to be made...')
        end
      end, 3)
    else

      if UnitIsGroupLeader("player") == false and UnitIsGroupAssistant("player") == false then
        print('|cFFFF0000You must be raid assist or lead to host DKP.')
        return false
      end

      print('|cFFFF0000'..Acodkp.hasHost..' is already hosting DKP! type "/dkp playername" to check a specific player')
    end

    return false
  end

  if UnitIsGroupLeader("player") == false and UnitIsGroupAssistant("player") == false then
    print('|cFFFF0000You must be raid assist or lead to host DKP.')
    return false
  end
  
  local frame = AceGUI:Create("FrameAco");
  frame:SetTitle("AcoTools DKP");
  setFrameSize(frame, 'DKPList', 370, 400)
  frame.frame:SetMinResize(200, 200)
  frame:SetLayout("Flow")

  Acodkp['frame'] = frame;

  local scrollcontainer = AceGUI:Create("SimpleGroup")
  scrollcontainer:SetFullWidth(true)
  scrollcontainer:SetFullHeight(true)
  scrollcontainer:SetLayout("Fill")

  frame:AddChild(scrollcontainer)

  local scroll = AceGUI:Create("ScrollFrame")
  scroll:SetLayout("Flow")
  scrollcontainer:AddChild(scroll)

  local addgroup = AceGUI:Create("SimpleGroup")
  addgroup:SetRelativeWidth(1);
  addgroup:SetLayout("Flow")
  scroll:AddChild(addgroup)

  local date_info_local = 'UNKNOWN';
  local local_disabled = true;
  local label_color_local = '|cFFFF0000';
  local label_context_local = ' - local data must be < 2 hours old to be loaded.';
  if(AcoBid_Data.LocalData.timestamp) then
    date_info_local = date("%b %d, %Y %H:%M:%S", AcoBid_Data.LocalData.timestamp);

    if(time() - (AcoBid_Data.LocalData.timestamp) < (60*60*2)) then
      local_disabled = false;
      label_color_local = '|cFF00FF00';
      label_context_local = '';
    end
  end

  local button = AceGUI:Create("Button")
  button:SetText("Reload From Local")
  button:SetRelativeWidth(1);
  button:SetDisabled(local_disabled)
  addgroup:AddChild(button)

  local updated = AceGUI:Create("Label")
  updated:SetText(label_color_local..'Local Data last update: '..date_info_local..label_context_local)
  updated:SetRelativeWidth(1);
  addgroup:AddChild(updated)

  local sep1 = AceGUI:Create("Heading")
  sep1:SetText('OR')
  sep1:SetRelativeWidth(1);
  addgroup:AddChild(sep1)

  local date_info = 'UNKNOWN';
  local website_disabled = true;
  local label_color = '|cFFFF0000';
  local label_context = ' - website data must be < 12 hours old to be imported.';
  if(AcoBid_Data.LastUpdated) then
    date_info = date("%b %d, %Y %H:%M:%S", AcoBid_Data.LastUpdated/1000);

    if(time() - (AcoBid_Data.LastUpdated/1000) < (60*60*12)) then
      website_disabled = false;
      label_color = '|cFF00FF00';
      label_context = '';
    end
  end

  local button2 = AceGUI:Create("Button")
  button2:SetText("Load from website")
  button2:SetRelativeWidth(1);
  button2:SetDisabled(website_disabled)
  addgroup:AddChild(button2)

  local updated2 = AceGUI:Create("Label")
  updated2:SetText(label_color..'Website data last updated: '..date_info..label_context)
  updated2:SetRelativeWidth(1);
  addgroup:AddChild(updated2)

  local sep1 = AceGUI:Create("Heading")
  sep1:SetText('OR')
  sep1:SetRelativeWidth(1);
  addgroup:AddChild(sep1)

  local editbox = AceGUI:Create("MultiLineEditBox")
  editbox:SetLabel("DKP String (type !dkpstring in discord)")
  editbox:SetRelativeWidth(1);
  editbox:SetText('')
  addgroup:AddChild(editbox)


  if(Acodkp.timestamp) then
    renderdkplist(addgroup,scroll,frame)
  else
    frame:SetStatusText("Please load DKP!")
  end

  editbox:SetCallback("OnEnterPressed", function(widget, event, text)
    setinitaldkp(text, function(success)
      if(not success) then
        editbox:SetText('')
        return false
      end
      renderdkplist(addgroup,scroll,frame)
    end)
  end)

  button:SetCallback("OnClick", function(widget, event)
    reloadinitaldkp(function(success)
      if(not success) then
        editbox:SetText('')
        return false
      end
      renderdkplist(addgroup,scroll,frame)
    end)
  end)

  button2:SetCallback("OnClick", function(widget, event)
    setinitaldkp(false, function(success)
      if(not success) then
        editbox:SetText('')
        return false
      end
      renderdkplist(addgroup,scroll,frame)
    end)
  end)

end

function reloadinitaldkp(cb)
  if(not AcoBid_Data.LocalData.timestamp) then return false end

  Acodkp['timestamp'] = time();
  Acodkp['host'] = myname;

  Acodkp.list = {}
  for player, data in pairs(AcoBid_Data.LocalData.list) do
    table.insert(Acodkp.list, data)
  end
  
  AcoBid_Data.LocalData['timestamp'] = Acodkp['timestamp'];

  AcoBidAdmin:SendCommMessage("AcoDKPCheck", "0", "RAID")
  cb(true)
end

function setinitaldkp(text, cb)
  Acodkp['timestamp'] = time();
  Acodkp['host'] = myname;

  if(text) then

    Acodkp['list'] = text:splitcsv(",")
    for i = 1, #Acodkp.list do
      local player, total, adjustments;
      if(Acodkp.list[i]:match("(.-)##([+-]?%d*)##([+-]?%d*)")) then
        player, total, adjustments = Acodkp.list[i]:match("(.-)##([+-]?%d*)##([+-]?%d*)");
      else
        player, total = Acodkp.list[i]:match("(.-)##([+-]?%d*)");
      end

      Acodkp.list[i] = {player = player, total = tonumber(total), adjustments = adjustments or 0}
      if(not player or not tonumber(total)) then
        print('|cFFFF0000Invalid DKP string!')
  
        Acodkp['timestamp'] = nil;
        Acodkp['host'] = nil;
        Acodkp['list'] = nil;
        return cb(false);
      end
    end

  else

    Acodkp['list'] = {}
    for player, total in pairs(AcoBid_Data.WebData) do
      table.insert(Acodkp.list, {player = player, total = tonumber(total), adjustments = 0})
      if(not player or not tonumber(total)) then
        print('|cFFFF0000Invalid Website DKP!')
  
        Acodkp['timestamp'] = nil;
        Acodkp['host'] = nil;
        Acodkp['list'] = nil;
        return cb(false);
      end
    end

  end

  AcoBid_Data.LocalData['timestamp'] = Acodkp['timestamp'];
  AcoBid_Data.LocalData['list'] = {};
  for i = 1, #Acodkp.list do
    AcoBid_Data.LocalData.list[Acodkp.list[i].player] = Acodkp.list[i]
  end

  AcoBidAdmin:SendCommMessage("AcoDKPCheck", "0", "RAID")
  cb(true)
end

function renderdkplist(addgroup,scroll,frame)
  addgroup:Release()

  frame:SetStatusText("DKP Host: " .. Acodkp.host)
  
  local group = AceGUI:Create("SimpleGroup")
  group:SetRelativeWidth(1);
  group:SetLayout("Flow")

  scroll:AddChild(group)

  local name = AceGUI:Create("InteractiveLabel")
  name:SetText("Player");
  name:SetFont(GameFontNormal:GetFont());
  name:SetRelativeWidth(0.33);
  group:AddChild(name);

  local adjustments = AceGUI:Create("InteractiveLabel")
  adjustments:SetText("Spent");
  adjustments:SetFont(GameFontNormal:GetFont());
  adjustments:SetRelativeWidth(0.33);
  adjustments.label:SetJustifyH("CENTER");
  group:AddChild(adjustments);

  local current = AceGUI:Create("InteractiveLabel")
  current:SetText("Available");
  current:SetFont(GameFontNormal:GetFont());
  current:SetRelativeWidth(0.33);
  current.label:SetJustifyH("RIGHT");
  group:AddChild(current);

  for x = 1, 40 do
    name, rank, subgroup, level, class = GetRaidRosterInfo(x);
    if name == nil then
    else

      local current_player = {};
      local current_player_id = false;
      for i = 1, #Acodkp.list do
        if string.lower(string.gsub(name, realmname, "")) == string.lower(Acodkp.list[i].player) then
          current_player = Acodkp.list[i];
          current_player_id = i;
        end
      end

      if(not current_player.player) then
        current_player = {player = name, total = 0, adjustments = 0}
      end
      
      rPerc, gPerc, bPerc, argbHex = GetClassColor(string.upper(class))

      local group = AceGUI:Create("SimpleGroup")
      group:SetRelativeWidth(1);
      group:SetLayout("Flow")
      if x%2~=0 then
        group.frame.texture = group.frame:CreateTexture()
        group.frame.texture:SetAllPoints(group.frame)
        group.frame.texture:SetColorTexture(1,1,1,0.1)
      end

      scroll:AddChild(group)

      local name = AceGUI:Create("InteractiveLabel")
      name:SetText("|c"..argbHex..current_player.player);
      name:SetFont(GameFontNormal:GetFont());
      name:SetRelativeWidth(0.33);
      group:AddChild(name);

      local adjustments = AceGUI:Create("EditBox")
      adjustments:SetText(current_player.adjustments);
      adjustments:SetRelativeWidth(0.33);
      adjustments.label:SetJustifyH("CENTER");
      group:AddChild(adjustments);

      local current = AceGUI:Create("InteractiveLabel")
      current:SetText(current_player.total - current_player.adjustments);
      current:SetFont(GameFontNormal:GetFont());
      current:SetRelativeWidth(0.33);
      current.label:SetJustifyH("RIGHT");
      group:AddChild(current);

      adjustments:SetCallback("OnEnterPressed", function(widget, event, text)
        if(tonumber(text) == nil) then
          adjustments:SetText(current_player.adjustments);
          print('|cFFFF0000Value must be an integer!')
        else

          if(current_player_id) then
            Acodkp.list[current_player_id].adjustments = tonumber(text);
          else
            current_player.adjustments = tonumber(text);
            table.insert( Acodkp.list, current_player)
          end

          AcoBid_Data.LocalData['timestamp'] = Acodkp['timestamp'];
          AcoBid_Data.LocalData['list'] = {};
          for i = 1, #Acodkp.list do
            AcoBid_Data.LocalData.list[Acodkp.list[i].player] = Acodkp.list[i]
          end

          if(Acodkp.frame) then
            if Acodkp.frame:IsShown() then
              Acodkp.frame.frame:Hide()
              Acodkp.frame = false;
              AcoBidAdmin:opendkpwindow('')
            end
          end
        end
      end)
    end
  end 
end

function AcoBidAdmin:AcoDKPCheckCallback(name,input,distribution,sender)
  if(distribution == "WHISPER") then
    Acodkp.timer = false;
    print('|cFF69FAF5'..input)
    return false;
  end

  if(Acodkp.hasHost == sender and input == "0") then
    print('|cFFFF7D0A'..Acodkp.hasHost..' stopped hosting DKP!')
    Acodkp.hasHost = false;
  end

  if(Acodkp.host and input == "0") then
    AcoBidAdmin:SendCommMessage("AcoDKPHost", "true", "RAID")
  elseif(Acodkp.host) then
    getdkpforchar(input,sender)
  else
    AcoBidAdmin:SendCommMessage("AcoDKPHost", "false", "RAID")
  end
end

function AcoBidAdmin:AcoDKPHostCallback(name,input,distribution,sender)
  if(input == "false") then
    return false
  end

  Acodkp.hasHost = sender;
  print('|cFF00FF00'..Acodkp.hasHost..' started hosting DKP!')

  if(Acodkp.frame and (sender ~= myname or Acodkp.hasHost ~= sender)) then
    Acodkp.frame.frame:Hide()
    Acodkp.frame = false;
  end  
end

function getdkpforchar(input,sender)
  local current_player = false;
  local all_of_class = false;

  for i = 1, #Acodkp.list do
    if string.lower(input) == string.lower(Acodkp.list[i].player) then
      current_player = Acodkp.list[i];
    end
  end

  for i = 1, #classlist do
    if string.lower(input) == string.lower(Acodkp.list[i].player) then
      current_player = Acodkp.list[i];
    end
  end

  for k, v in pairs(classlist) do
    if string.lower(input) == string.lower(v) then
      all_of_class = '';
      for x = 1, 40 do
        name, rank, subgroup, level, class = GetRaidRosterInfo(x);
        if name == nil or string.lower(class) ~= string.lower(input) then
        else

          local raid_player = {};
          local raid_player_id = false;
          for i = 1, #Acodkp.list do
            if string.lower(string.gsub(name, realmname, "")) == string.lower(Acodkp.list[i].player) then
              raid_player = Acodkp.list[i];
              raid_player_id = i;
            end
          end

          if(not raid_player.player) then
            raid_player = {player = name, total = 0, adjustments = 0}
          end

          all_of_class = all_of_class .. string.gsub(raid_player.player, realmname, "") .. ':' .. (raid_player.total - raid_player.adjustments) .. ', '
          
        end
      end 
    end
  end

  if(all_of_class) then
    if(string.len(all_of_class) == 0) then
      AcoBidAdmin:SendCommMessage("AcoDKPCheck", 'No '..input..'(s) in raid', "WHISPER", sender)
    else
      AcoBidAdmin:SendCommMessage("AcoDKPCheck", all_of_class:sub(1, -3), "WHISPER", sender)
    end
  elseif(current_player) then
    AcoBidAdmin:SendCommMessage("AcoDKPCheck", current_player.player..": "..tostring(current_player.total-current_player.adjustments).." DKP", "WHISPER", sender)
  else
    AcoBidAdmin:SendCommMessage("AcoDKPCheck", '"'..input..'" Not found (0 DKP)', "WHISPER", sender)
  end
end

function AcoBidAdmin:AcoDKPGetCallback(name,input,distribution,sender)
  if(distribution == "WHISPER") then
    local success, bid_ID, amount = AcoBidAdmin:Deserialize(input)
    biddingFrames[bid_ID].timer = false;
    biddingFrames[bid_ID].dkp:SetText("|cffffd100Available DKP: "..amount);
    biddingFrames[bid_ID].dkpamount = amount;
  else
    if(not Acodkp.host) then
      return false
    end

    local current_player = false;
    for i = 1, #Acodkp.list do
      if string.lower(sender) == string.lower(Acodkp.list[i].player) then
        current_player = Acodkp.list[i];
      end
    end

    if(current_player) then
      AcoBidAdmin:SendCommMessage("AcoDKPGet", AcoBidAdmin:Serialize(input, current_player.total-current_player.adjustments), "WHISPER", sender)
    else
      AcoBidAdmin:SendCommMessage("AcoDKPGet", AcoBidAdmin:Serialize(input, 0), "WHISPER", sender)
    end

  end
end

function AcoBidAdmin:AcoDKPAdjustCallback(name,input,distribution,sender)
  if(Acodkp.host ~= myname) then
    return false
  end

  local success, bid_ID, player, amount = AcoBidAdmin:Deserialize(input)

  if(not Acodkp['winners']) then Acodkp['winners'] = {} end
  if(not Acodkp.winners[bid_ID]) then Acodkp.winners[bid_ID] = {} end
  
  
  local current_player = false;
  local previous_player = false;
  for i = 1, #Acodkp.list do
    if string.lower(player) == string.lower(Acodkp.list[i].player) then
      current_player = i;
    end
    if(Acodkp.winners[bid_ID].player) then
      if string.lower(Acodkp.winners[bid_ID].player) == string.lower(Acodkp.list[i].player) then
        previous_player = i;
      end
    end
  end

  if(previous_player) then
    Acodkp.list[previous_player].adjustments = Acodkp.list[previous_player].adjustments - Acodkp.winners[bid_ID].amount;
  end

  if(current_player) then
    Acodkp.list[current_player].adjustments = Acodkp.list[current_player].adjustments + amount
  else
    table.insert( Acodkp.list, {player = player, total = 0, adjustments = amount})
  end
  
  Acodkp.winners[bid_ID] = {player = player, amount = amount}

  AcoBid_Data.LocalData['timestamp'] = time();
  AcoBid_Data.LocalData['list'] = {}
  for i = 1, #Acodkp.list do
    AcoBid_Data.LocalData.list[Acodkp.list[i].player] = Acodkp.list[i]
  end

  if(Acodkp.frame) then
    if Acodkp.frame:IsShown() then
      Acodkp.frame.frame:Hide()
      Acodkp.frame = false;
      AcoBidAdmin:opendkpwindow('')
    end
  end

end

function eventHandler(self, event, ...)
  local instance, instance_type = IsInInstance();
  if(instance and instance_type == "pvp") then
    return false
  end

  if IsInRaid() == false then
    return false
  end

  if event == "UPDATE_MOUSEOVER_UNIT" then
    render_corpse_tooltip()
    return
  elseif event == "TRADE_SHOW" then
    showItemsWon()
    return
  elseif event == "TRADE_CLOSED" then
    hideItemsWon()
    return
  elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
    local unitTarget, castGuid, spellId = ...

    if unitTarget == "player" and spellId == 21358 then
      SendChatMessage("[AcoTools] I dowsed a rune!", "RAID")
    end

    return
  elseif event ~= "GROUP_ROSTER_UPDATE" and event ~= "PLAYER_ENTERING_WORLD" and event ~= "COMBAT_LOG_EVENT_UNFILTERED" then
    return false;
  end

  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    processCombatEvent(self, event, ...)
    return false
  end

  if(Acodkp.host == myname) then
    return false
  end

  if(Acodkp.hashost) then
    return false
  end

  AcoBidAdmin:SendCommMessage("AcoDKPCheck", "0", "RAID")
end

function processCombatEvent(self, event, ...)
  local _, eventName, _, _, _, _, _, destGuid, destName = CombatLogGetCurrentEventInfo()
  local creatureDied = string.sub(destGuid, 1, 8) == "Creature"

  if eventName == "UNIT_DIED" and creatureDied then
    do_callback(1, function()
      local hasLoot, _ = CanLootUnit(destGuid)

      if hasLoot then
        lootlist[destGuid] = {}
        lootlist[destGuid]['looters'] = {myname};
        lootlist[destGuid]['timestamp'] = time();
        AcoBidAdmin:SendCommMessage("AcoBidCanLoot", destGuid, "RAID")
      end

      if(#lootlist > 0) then
        local lowest = nil; local i = 0;
        for key,value in pairs(lootlist) do
          i = i+1;
          if(lowest == nil) then lowest = {['key']=key, ['value']=value.timestamp} end
          if(value.timestamp < lowest.value) then lowest = {['key']=key, ['value']=value.timestamp} end
        end
  
        if(i >= 20) then lootlist[lowest.key] = nil end
      end
    end)
  end
end

-- function processLootOpen()
--   for i = 1, GetNumLootItems() do

--     _G["LootButton"..i]:SetScript("OnMouseUp", function (self, button)
--       if IsAltKeyDown() then 
--         local itemIcon, itemName, _, _, itemQuality = GetLootSlotInfo(i)
--         local itemLink = GetLootSlotLink(i)
--         local unitName = UnitName("target")
--         local uid = RandomNum(16);

--         local itemData = {['unit']=unitName, ['link']=itemLink, ['quality']=itemQuality, ['uid']=uid}
  
--         AcoBidAdmin:SendCommMessage("AcoBidItemAdd", AcoBidAdmin:Serialize(itemData), "RAID")
--       end
--     end)

-- 	end
-- end

function AcoBidAdmin:addManualLoot(input)

  if IsInRaid() == false then
    print('|cFFFF0000You must be in a raid')
    return false
  end

  if UnitIsGroupLeader("player") == false and UnitIsGroupAssistant("player") == false then
    print('|cFFFF0000You must be raid assist or lead to add loot.')
    return false
  end
  
  local itemLink, extra = AcoBidAdmin:GetArgs(input, 2);

  if itemLink == nil or extra then
    print('|cFFFF0000Command /bid takes exactly 1 arguments (itemlink)')
    return false
  end

  local isitemlink = string.match(itemLink, '(%|Hitem%:)');
  if isitemlink == nil then
    print('|cFFFF0000Argument must be an item link')
    return false
  end

  local uid = RandomNum(16);
  local itemData = {['unit']='Manual Entry', ['link']=itemLink, ['uid']=uid}
  
  AcoBidAdmin:SendCommMessage("AcoBidItemAdd", AcoBidAdmin:Serialize(itemData), "RAID")

end

function do_callback(duration, callback)
  local newFrame = CreateFrame("Frame")
  newFrame:SetScript("OnUpdate", function (self, elapsed)
      duration = duration - elapsed
      if duration <= 0 then
          callback()
          newFrame:SetScript("OnUpdate", nil)
      end
  end)
end

function AcoBidAdmin:raidroll()

  if IsInRaid() == false then
    print('|cFFFF0000You must be in a raid')
    return false
  end

  if (GetNumGroupMembers() > 0) then
    local r=random(1,GetNumGroupMembers())
    local name = GetRaidRosterInfo(r)
    SendChatMessage("[AcoTools] "..r.." out of "..GetNumGroupMembers()..". "..name.." wins the roll", "RAID")
  end

end

function AcoBidAdmin:AcoBidCanLootCallback(name,input,distribution,sender)
  if sender == myname then return false end
  if(lootlist[input] == nil) then lootlist[input] = {['looters']={},['timestamp'] = time()} end
  table.insert(lootlist[input].looters, sender)
end

function render_corpse_tooltip()
  if UnitIsDead("mouseover") and IsInRaid() then
    local unitGuid = UnitGUID("mouseover");

    if lootlist[unitGuid] ~= nil then
        if(#lootlist[unitGuid].looters > 1) then
          GameTooltip:AddLine("Lootable by multiple")
        else
          GameTooltip:AddLine("Lootable by "..lootlist[unitGuid].looters[1])
        end

        GameTooltip:Show()
    end
  end
end

function showItemsWon()
  local tradename = TradeFrameRecipientNameText:GetText();

  for bidID, player in pairs(bidwinners) do
    if tradename == player then
      bidLinks[bidID].frame.texture:SetColorTexture(0,255,118,0.25)
    end
  end

end

function hideItemsWon()
  for bidID, f in pairs(bidLinks) do
    bidLinks[bidID].frame.texture:SetColorTexture(0,255,118,0)
  end
end

--[[
function AcoBidAdmin:ItemCheck(input)

  if IsInRaid() == false then
    print('|cFFFF0000You must be in a raid')
    return false
  end
  
  local itemLink, extra = AcoBidAdmin:GetArgs(input, 2);

  if itemLink == nil or extra then
    print('|cFFFF0000Command /itemcheck takes exactly 1 argument (itemlink).')
    return false
  end

  local isitemlink = string.match(itemLink, '(%|Hitem%:)');
  if isitemlink == nil then
    print('|cFFFF0000First argument must be an item link')
    return false
  end

  if(checkFrame) then checkFrame.frame:Hide() end
  checkFrame = nil;
  raidroster = {};
  checkSender = nil;

  raidroster["item"] = itemLink;

  local frame = AceGUI:Create("FrameAco");
  frame:SetTitle("AcoBid-ItemCheck v"..version);
  setFrameSize(frame, 'ItemCheck', 300, 300)
  frame:SetLayout("Flow")
  frame.frame:SetMinResize(300, 100)
  frame.statusbg:Hide();
  checkFrame = frame;

  local scrollcontainer = AceGUI:Create("SimpleGroup")
  scrollcontainer:SetFullWidth(true)
  scrollcontainer:SetFullHeight(true)
  scrollcontainer:SetLayout("Fill")

  frame:AddChild(scrollcontainer)

  local scroll = AceGUI:Create("ScrollFrame")
  scroll:SetLayout("List")
  scrollcontainer:AddChild(scroll)

  local sep1 = AceGUI:Create("InteractiveLabel")
  sep1:SetText(itemLink)
  sep1:SetRelativeWidth(1);
  scroll:AddChild(sep1)
  checkFramesep1 = sep1

  sep1:SetCallback("OnClick", function(widget, event, text)
    SendChatMessage(checkFramesep1text, "RAID");
  end)

  for i = 1, 40 do
    name = GetRaidRosterInfo(i);
    if name ~= nil then
      local names = AceGUI:Create("InteractiveLabel")
      names:SetText('|cFF9C9C9C'..string.gsub(name, realmname, ""));
      names:SetFont(GameFontNormal:GetFont());
      names:SetRelativeWidth(1);
      names:SetImageSize(17, 17)
      scroll:AddChild(names);

      table.insert(raidroster, {['name'] = string.gsub(name, realmname, ""), ["item"] = 0, ["equipped"] = false, label = names})
    end
  end

  AcoBidAdmin:SendCommMessage("AcoBidItem", itemLink, "RAID")
end

function AcoBidAdmin:AcoBidItemCallback(name,input,distribution,sender)
  checkSender = sender

  local item_count = GetItemCount(input, false, false);
  local equipped = false;

  for i = 0, 19 do
    if(GetInventoryItemID('player',i) == GetItemInfoInstant(input)) then
      equipped = true
    end
  end

  AcoBidAdmin:SendCommMessage("AcoBidItemR", AcoBidAdmin:Serialize(input, item_count, equipped), "RAID")
end

function AcoBidAdmin:AcoBidItemRCallback(name,input,distribution,sender)
  
  if checkSender ~= myname then
    return false;
  end

  local success, itemlink, amount, equipped = AcoBidAdmin:Deserialize(input)
  if(raidroster.item == itemLink) then return end

  for i = 1, #raidroster do
    if raidroster[i].name == sender then
      raidroster[i].item = amount;
      raidroster[i].equipped = equipped;
    end
  end

  local message = '';
  local totalcount = 0;
  for i = 1, #raidroster do
    if(raidroster[i].item < 1) then
      raidroster[i].label:SetText('|cFFFF0000'..raidroster[i].name..'|r - (0)');
      raidroster[i].label:SetImage("Interface\\RaidFrame\\ReadyCheck-NotReady");
    else
      local eq = ''
      totalcount = totalcount + tonumber(raidroster[i].item);
      if raidroster[i].equipped then eq = ' (equipped)' end
      raidroster[i].label:SetText('|cFF00FF00'..raidroster[i].name..'|r - ('..raidroster[i].item..')'..eq);
      raidroster[i].label:SetImage("Interface\\RaidFrame\\ReadyCheck-Ready");
    end
  end

  checkFramesep1text = itemlink.." ("..totalcount..")";
  checkFramesep1:SetText(checkFramesep1text)
end--]]

function AcoBidAdmin:openscanwindow(input)
  SetGuildRosterShowOffline(true);

  local roster = {}
  for i = 1, GetNumGuildMembers() do
    name = GetGuildRosterInfo(i);
    table.insert(roster, {['name'] = string.gsub(name, realmname, "")})
  end

  if(AcoScan.frame) then AcoScan.frame.frame:Hide() end
  local frame = AceGUI:Create("FrameAco");
  frame:SetTitle("AcoTools Invite Scan");
  setFrameSize(frame, 'InviteScan', 350, 200)
  frame.frame:SetMinResize(350, 200)
  frame:SetStatusText("close window to stop scan...")

  frame:SetLayout("Flow")

  AcoScan['frame'] = frame;

  local addgroup = AceGUI:Create("SimpleGroup")
  addgroup:SetRelativeWidth(1);
  addgroup:SetLayout("Flow")
  frame:AddChild(addgroup)

  local editbox = AceGUI:Create("EditBox")
  editbox:SetLabel("Keyword (case insensitive)")
  editbox:SetRelativeWidth(1);
  editbox:SetText('invite')
  editbox:SetMaxLetters(12)
  editbox:DisableButton(true)
  editbox:HighlightText()
  editbox:SetFocus()

  addgroup:AddChild(editbox)

  local checkbox = AceGUI:Create("CheckBox")
  checkbox:SetLabel("Guild only")
  checkbox:SetRelativeWidth(0.5);
  checkbox:SetValue(true)
  addgroup:AddChild(checkbox)

  local checkbox2 = AceGUI:Create("CheckBox")
  checkbox2:SetLabel("Master Loot")
  checkbox2:SetRelativeWidth(0.5);
  checkbox2:SetValue(true)
  addgroup:AddChild(checkbox2)

  local announce = AceGUI:Create("Button")
  announce:SetText("Announce in /guild")
  announce:SetRelativeWidth(1);
  addgroup:AddChild(announce)

  frame:SetCallback("OnClose", function(widget, event, key, checked)
    AcoScan.frame.frame:SetScript("OnEvent",nil)
    AcoScan.frame = nil;
  end)

  announce:SetCallback("OnClick", function(widget, event, key, checked)
    SendChatMessage('[AcoTools] Invite-Scanning active. Please whisper me with the keyword "'..string.lower(editbox:GetText())..'" for an invite!', "GUILD");
  end)

  AcoScan.frame.frame:RegisterEvent("CHAT_MSG_WHISPER");
  AcoScan.frame.frame:SetScript("OnEvent", function(self, event, ...)
    if(not AcoScan.frame) then return end
    local msg, sender = ...
    sender = string.gsub(sender, realmname, "")

    if(string.lower(msg) == string.lower(editbox:GetText())) then
      local guild = false;
      local masterloot = true;

      for i = 1, #roster do
        if string.lower(roster[i].name) == string.lower(sender) then guild = true end
      end

      if(not checkbox:GetValue()) then guild = true end
      if(not checkbox2:GetValue()) then masterloot = false end

      if(guild) then
        if(not IsInRaid()) then ConvertToRaid() end
        if(masterloot) then SetLootMethod("master", myname) end
        InviteUnit(sender)
      else
        SendChatMessage('[AcoTools] Sorry, keyword invites enabled for guild members only.', "WHISPER", "Common", sender);
      end
    end
    
  end);
end

function AcoBidAdmin:listInvites(input)

  if(invitelistFrame) then invitelistFrame.frame:Hide() end
  invitelistFrame = nil;
  checkSender = nil;

  local frame = AceGUI:Create("FrameAco");
  frame:SetTitle("AcoTools Invite List");
  setFrameSize(frame, 'invitelistFrame', 300, 300)
  frame:SetLayout("Flow")
  frame.frame:SetMinResize(300, 100)
  frame.statusbg:Hide();
  invitelistFrame = frame;

  local button1 = AceGUI:Create("Button")
  button1:SetText("Import")
  button1:SetRelativeWidth(0.32);
  frame:AddChild(button1)

  local button2 = AceGUI:Create("Button")
  button2:SetText("Invite")
  button2:SetRelativeWidth(0.32);
  frame:AddChild(button2)

  local button3 = AceGUI:Create("Button")
  button3:SetText("Refresh")
  button3:SetRelativeWidth(0.32);
  frame:AddChild(button3)

  local sep1 = AceGUI:Create("Heading")
  sep1:SetRelativeWidth(1);
  frame:AddChild(sep1)

  local scrollcontainer = AceGUI:Create("SimpleGroup")
  scrollcontainer:SetFullWidth(true)
  scrollcontainer:SetFullHeight(true)
  scrollcontainer:SetLayout("Fill")

  frame:AddChild(scrollcontainer)

  local scroll = AceGUI:Create("ScrollFrame")
  scroll:SetLayout("List")
  scrollcontainer:AddChild(scroll)

  updateInviteList = function()
    if(not IsInRaid()) then ConvertToRaid() end

    scroll:ReleaseChildren()
    for i = 1, #inviteList do
      
      local names = AceGUI:Create("InteractiveLabel")
        local name = inviteList[i]
        if(UnitInRaid(name) or UnitInParty(name)) then
          names:SetText('|cFF00FF00'..name);
          names:SetImage("Interface\\RaidFrame\\ReadyCheck-Ready");
        else
          names:SetText('|cFFFF0000'..name);
          names:SetImage("Interface\\RaidFrame\\ReadyCheck-NotReady");
          names:SetHighlight("Interface\\Buttons\\UI-Listbox-Highlight");
        end
  
        names:SetFont(GameFontNormal:GetFont());
        names:SetRelativeWidth(1);
        names:SetImageSize(17, 17)
        scroll:AddChild(names);

        names:SetCallback("OnClick", function(widget, event, text)
          if(not IsInRaid()) then ConvertToRaid() end
          SetLootMethod("master", myname)
          if((not UnitInRaid(name) and not UnitInParty(name)) or not IsInGroup()) then InviteUnit(name) end
      
          do_callback(1, function() updateInviteList() end)
        end)
    end

  end

  button1:SetCallback("OnClick", function(widget, event, text)
    if importFrame:IsShown() then
      importFrame:Hide()
    else
      importFrame:Show()
    end
  end)

  button2:SetCallback("OnClick", function(widget, event, text)
    for i = 1, #inviteList do
      if(not IsInRaid()) then ConvertToRaid() end
      SetLootMethod("master", myname)
      if((not UnitInRaid(inviteList[i]) and not UnitInParty(inviteList[i])) or not IsInGroup()) then InviteUnit(inviteList[i]) end
    end

    do_callback(1, function() updateInviteList() end)
  end)

  button3:SetCallback("OnClick", function(widget, event, text)
    updateInviteList()
  end)

  if(importFrame) then importFrame.frame:Hide() end
  importFrame = nil;

  local frame2 = AceGUI:Create("FrameAco");
  frame2:SetTitle("AcoTools Invite Import");
  setFrameSize(frame2, 'importFrame', 300, 300)
  frame2:SetLayout("Fill")
  frame2.frame:SetMinResize(300, 100)
  frame2.statusbg:Hide();
  frame2:Hide()
  importFrame = frame2;

  local editbox = AceGUI:Create("MultiLineEditBox")
  editbox:SetLabel("CSV Import")
  editbox:SetRelativeWidth(1);
  editbox:SetText('')
  frame2:AddChild(editbox)

  editbox:SetCallback("OnEnterPressed", function(widget, event, text)
    inviteList = text:splitcsv(",")
    updateInviteList()
  end)

end