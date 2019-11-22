local version = GetAddOnMetadata("AcoBid", "Version");

AcoBid = LibStub("AceAddon-3.0"):NewAddon("AcoBid", "AceConsole-3.0", "AceComm-3.0", "AceTimer-3.0")
local AceGUI = LibStub("AceGUI-3.0-custom")
CreateFrame("GameTooltip", "tooltip", nil, "GameTooltipTemplate");
tooltip:SetScale(GetCVar("uiScale"))
tooltip:Hide();

local checkSender = nil;
local AcoMasterBids = AceGUI:Create("Frame");
local AcoMasterBidsScroll = nil;
local biddingFrames = {};
local openBids = 0;
local previousBid = nil;

local myname = UnitName("player");

function AcoBid:OnInitialize()
  name, title, notes, enabled = GetAddOnInfo("AcoBid-Admin");
  if enabled then
    return false;
  end

  AcoBid:RegisterChatCommand('bids', 'openbidswindow');

  AcoBid:RegisterComm("AcoBidStart", "AcoBidStartCallback")
  AcoBid:RegisterComm("AcoBidCheck", "AcoBidCheckCallback")

  AcoMasterBids:SetTitle("AcoBid v"..version);
  AcoMasterBids:SetWidth(300);
  AcoMasterBids:SetHeight(300);
  AcoMasterBids:SetLayout("Flow")
  AcoMasterBids.frame:SetMinResize(300, 200)
  AcoMasterBids.content:SetPoint("BOTTOMRIGHT", -17, 27)
  AcoMasterBids.statusbg:Hide();
  AcoMasterBids.closebutton:Hide();

  scrollcontainer = AceGUI:Create("SimpleGroup")
  scrollcontainer:SetFullWidth(true)
  scrollcontainer:SetFullHeight(true)
  scrollcontainer:SetLayout("Fill")

  AcoMasterBids:AddChild(scrollcontainer)

  scroll = AceGUI:Create("ScrollFrame")
  scroll:SetLayout("List")
  scrollcontainer:AddChild(scroll)

  AcoMasterBidsScroll = scroll;
  AcoMasterBids.frame:Hide();
end

function AcoBid:openbidswindow(input)
  if AcoMasterBids.frame:IsShown() then
    AcoMasterBids.frame:Hide();
  else
    AcoMasterBids.frame:Show();
  end
end

function AcoBid:AcoBidStartCallback(name,input,distribution,sender)
  local itemLink, minBid, lootPriority, bidID, timer_amount = AcoBid:GetArgs(input, 5);
  
  AddItemToMaster(itemLink,minBid,lootPriority,sender,bidID, timer_amount)
    
  biddingFrames[bidID] = {};
  AddItemToFrame(itemLink,minBid,lootPriority,sender,bidID, timer_amount)
end

function AcoBid:AcoBidCheckCallback(name,input,distribution,sender)
  checkSender = sender
  AcoBid:SendCommMessage("AcoBidReturn", version, "RAID")
end

function AddItemToFrame(itemLink,minBid,lootPriority,sender,bidID, timer_amount)

  local itemID, itemType, itemSubType, itemEquipLoc, icon = GetItemInfoInstant(itemLink)

  local frame = AceGUI:Create("Frame");
  frame:SetTitle("AcoBid v"..version);
  frame:SetStatusText(timer_amount.." Seconds left to bid...")
  frame:SetWidth(400);
  frame:SetHeight(270);
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
    tooltip:Hide();
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

  local details2 = AceGUI:Create("Label")
  details2:SetText("|cffffd100Priority: " ..lootPriority);
  details2:SetRelativeWidth(1);
  details2:SetFont(GameFontNormal:GetFont());
  group:AddChild(details2)

  local editbox = AceGUI:Create("EditBox")
  editbox:SetLabel("Bid amount: |cffff0000*")
  editbox:SetRelativeWidth(0.5);
  editbox:DisableButton(true);
  editbox:SetMaxLetters(4);
  group:AddChild(editbox)

  local selectbox = AceGUI:Create("Dropdown")
  local selecttypes = {"MAIN-SPEC", "OFF-SPEC", "ALT"};
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
  
  local timerCount = timer_amount;
  local timer = AcoBid:ScheduleRepeatingTimer(function()
    timerCount = timerCount - 1;
    if timerCount <= 0 then
      AcoBid:CancelTimer(timer);
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
        button:SetDisabled(false)
      end
    end

  end)

  button:SetCallback("OnClick", function(widget)

    if typeGood and bidGood and timerCount > 0 then
      guildName, guildRankName, guildRankIndex = GetGuildInfo("player");
      if guildRankName == nil then
        guildRankName = 'NO RANK'
      end
      local message = '['..bidID..'] '..itemLink..' "'..string.upper(guildRankName)..'" "'..selecttypes[selectbox:GetValue()]..'" '..tonumber(editbox:GetText());
      if previousBid then
        if previousBid == message then
          print('|cFFFF0000You already sent a bid with that value.')
        else
          previousBid = message;
          SendChatMessage(message, "WHISPER", "Common", sender);
        end
      else
        previousBid = message;
        SendChatMessage(message, "WHISPER", "Common", sender);
      end
    end

  end)

end

function AddItemToMaster(itemLink,minBid,lootPriority,sender,bidID, timer_amount)
  openBids = openBids + 1;
  AcoMasterBids.frame:Show()

  local itemID, itemType, itemSubType, itemEquipLoc, icon = GetItemInfoInstant(itemLink)

  function getItemText(itemLink,time)
    local msg = itemLink.."|cFFFFA500";
    if time == nil then
      msg = msg .. "\n"..timer_amount.."s left to bid..."
    elseif time == 'done' then
      msg = msg .. "\nBids Closed!"
    else
      msg = msg .. "\n"..time.."s left to bid..."
    end
    return msg
  end

  local item = AceGUI:Create("InteractiveLabel")
  item:SetText(getItemText(itemLink,nil));
  item:SetImage(icon);
  item:SetImageSize(25, 25)
  item:SetRelativeWidth(1);
  item:SetHighlight("Interface\\Buttons\\UI-Listbox-Highlight");
  AcoMasterBidsScroll:AddChild(item)

  item:SetCallback("OnEnter", function(widget)
    ShowTooltip(item.frame, itemLink)
  end)

  item:SetCallback("OnLeave", function(widget)
    tooltip:Hide();
  end)

  item:SetCallback("OnClick", function(widget, event, button)
    if biddingFrames[bidID] then
      if biddingFrames[bidID].frame.frame:IsShown() then
        biddingFrames[bidID].frame.frame:Hide();
      else
        biddingFrames[bidID].frame.frame:Show();
      end
    end
  end)

  local timerCount = timer_amount;
  local timer = AcoBid:ScheduleRepeatingTimer(function()
    timerCount = timerCount - 1;
    if timerCount < 0 then
      return false
    end
    if timerCount == 0 then
      AcoBid:CancelTimer(timer);
      openBids = openBids - 1;
      
      if sender ~= myname then
        item:SetText('');
        item:SetImage('');
        item.frame:Hide();
        item.frame:SetScale(0.0001);
      else
        item:SetText(getItemText(itemLink,'done'));
      end

      if openBids <= 0 then
        AcoMasterBids.frame:Hide()
      end
    else
      item:SetText(getItemText(itemLink,timerCount));
    end
  end, 1)
end

function ShowTooltip(frame,itemLink)
  tooltip:SetOwner(frame, 'ANCHOR_BOTTOM')
  tooltip:SetHyperlink(itemLink)
  tooltip:Show();
end
