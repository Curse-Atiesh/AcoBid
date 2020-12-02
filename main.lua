if(GetAddOnEnableState(UnitName("player"),'AcoBid-Admin') == 0) then
  local version = GetAddOnMetadata("AcoBid", "Version");
  
  AcoBid = LibStub("AceAddon-3.0"):NewAddon("AcoBid", "AceConsole-3.0", "AceComm-3.0", "AceTimer-3.0", "AceSerializer-3.0")
  AcoBid_FrameSettings = {}
  local AceGUI = LibStub("AceGUI-3.0-custom")
  CreateFrame("GameTooltip", "tooltip", nil, "GameTooltipTemplate");
  tooltip:SetScale(GetCVar("uiScale"))
  tooltip:Hide();
  
  local checkSender = nil;
  local AcoMasterBids = AceGUI:Create("Frame");
  local AcoMasterBidsScroll = nil;
  local biddingFrames = {};
  local bidLinks = {};
  local openBids = 0;
  local previousBid = nil;
  local Acodkp = {};
  local lootlist = {}
  local myname = UnitName("player");

  function frameResizeEvent(widget, frameID)
    if(not AcoBid_FrameSettings[frameID]) then AcoBid_FrameSettings[frameID] = {} end
    AcoBid_FrameSettings[frameID]['bottom'] = widget.frame:GetBottom()
    AcoBid_FrameSettings[frameID]['left'] = widget.frame:GetLeft()
    AcoBid_FrameSettings[frameID]['width'] = widget.frame:GetWidth()
    AcoBid_FrameSettings[frameID]['height'] = widget.frame:GetHeight()
  end
  
  function setFrameSize(frame, frameID, width, height)
    if(AcoBid_FrameSettings[frameID]) then
      frame:SetWidth(AcoBid_FrameSettings[frameID].width);
      frame:SetHeight(AcoBid_FrameSettings[frameID].height);
      frame:SetPoint("BOTTOMLEFT", UIParent,"BOTTOMLEFT", AcoBid_FrameSettings[frameID].left, AcoBid_FrameSettings[frameID].bottom);
    else
      frame:SetWidth(width);
      frame:SetHeight(height);
    end
  
    frame:SetCallback("OnResize", function(widget) frameResizeEvent(widget, frameID) end)
  end
  
  function AcoBid:OnInitialize()
    AcoBid:RegisterChatCommand('bids', 'openbidswindow');
    AcoBid:RegisterChatCommand('dkp', 'checkdkp');

    print('|cFFDAB812Type /acohelp for available AcoBid commands|r')
    AcoBid:RegisterChatCommand('acohelp', function()
  
      print([[|n|cFFDAB812Commands available for AcoBid|r
|cFF69FAF5/bids|r → Opens the bids window
|cFF69FAF5/dkp|r → Check your DKP
|cFF69FAF5/dkp playername|r → Checks dkp of playername if dkp is hosted
|cFF69FAF5/dkp classname|r → Checks dkp of classname if dkp is hosted]])
  
    end);
  
    AcoBid:RegisterComm("AcoBidStart", "AcoBidStartCallback")
    AcoBid:RegisterComm("AcoBidCheck", "AcoBidCheckCallback")
    AcoBid:RegisterComm("AcoDKPCheck", "AcoDKPCheckCallback")
    AcoBid:RegisterComm("AcoDKPHost", "AcoDKPHostCallback")
    AcoBid:RegisterComm("AcoDKPGet", "AcoDKPGetCallback")

    AcoBid:RegisterComm("AcoBidQuint", "AcoBidQuintCallback")
    AcoBid:RegisterComm("AcoBidCanLoot", "AcoBidCanLootCallback")
    AcoBid:RegisterComm("AcoBidItem", "AcoBidItemCallback")
  
    AcoMasterBids:SetTitle("AcoBid v"..version);
    setFrameSize(AcoMasterBids, 'MasterBids', 300, 300)
    AcoMasterBids:SetLayout("Flow")
    AcoMasterBids.frame:SetMinResize(200, 100)
    AcoMasterBids.content:SetPoint("BOTTOMRIGHT", -17, 27)
    AcoMasterBids.statusbg:Hide();
  
    AcoMasterBids:SetCallback("OnClose", function(widget)
      print("You can re-open the bids window at any time using /bids")
    end)
  
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
  
    AcoMasterBids.frame:RegisterEvent("GROUP_ROSTER_UPDATE");
    AcoMasterBids.frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    AcoMasterBids.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    AcoMasterBids.frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
    AcoMasterBids.frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
    AcoMasterBids.frame:SetScript("OnEvent", eventHandler);
  end
  
  function AcoBid:openbidswindow(input)
    if AcoMasterBids.frame:IsShown() then
      AcoMasterBids.frame:Hide();
    else
      AcoMasterBids.frame:Show();
    end
  end
  
  function AcoBid:AcoBidStartCallback(name,input,distribution,sender)
    local itemLink, minBid, bidID, timer_amount = AcoBid:GetArgs(input, 5);
    
    AddItemToMaster(itemLink,minBid,sender,bidID, timer_amount)
      
    biddingFrames[bidID] = {};
    AddItemToFrame(itemLink,minBid,sender,bidID, timer_amount)
  end
  
  function AcoBid:AcoBidCheckCallback(name,input,distribution,sender)
    checkSender = sender
    AcoBid:SendCommMessage("AcoBidReturn", version, "RAID")
  end
  
  function AddItemToFrame(itemLink,minBid,sender,bidID, timer_amount)
  
    local itemID, itemType, itemSubType, itemEquipLoc, icon = GetItemInfoInstant(itemLink)
  
    local frame = AceGUI:Create("Frame");
    frame:SetTitle("AcoBid v"..version);
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
      tooltip:Hide();
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
    local selecttypes = {"MAIN-SPEC", "OFF-SPEC", "ALT-MAIN-SPEC", "ALT-OFF-SPEC", "PVP/FARMING/MISC", "UNCONTESTED-ONLY"};
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
  
    AcoBid:SendCommMessage("AcoDKPGet", bidID, "RAID")
  
    biddingFrames[bidID]['timer'] = true;
    biddingFrames[bidID]['timerrunning'] = true;
    AcoBid:ScheduleTimer(function() 
      biddingFrames[bidID].timerrunning = false;
      if(biddingFrames[bidID].timer) then
        details3:SetText("|cffffd100Available DKP: |cffff0000(couldn't fetch data)");  
      end
    end, 3)
    
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
          errors:SetText("");
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
        local message = '['..bidID..'] '..itemLink..' "'..string.upper(guildRankName)..'" "'..selecttypes[selectbox:GetValue()]..'" '..tonumber(editbox:GetText()).." "..(biddingFrames[bidID].dkpamount or 'FALSE');
        if previousBid then
          if previousBid == message then
            errors:SetText('|cFFFF0000You\'ve already sent a bid with that value.')
          else
            previousBid = message;
            errors:SetText("");
            SendChatMessage(message, "WHISPER", "Common", sender);
          end
        else
          previousBid = message;
          errors:SetText("");
          SendChatMessage(message, "WHISPER", "Common", sender);
        end
      end
  
    end)
  
  end
  
  function AddItemToMaster(itemLink,minBid,sender,bidID, timer_amount)
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

      if IsControlKeyDown() then
        DressUpItemLink(itemLink);
        return false;
      end

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
  
  function AcoBid:AcoDKPCheckCallback(name,input,distribution,sender)
    if(distribution == "WHISPER") then
      Acodkp.timer = false;
      print('|cFF69FAF5'..input)
      return false;
    end
  
    if(Acodkp.hasHost == sender and input == "0") then
      print('|cFFFF7D0A'..Acodkp.hasHost..' stopped hosting DKP!')
      Acodkp.hasHost = false;
    end
  end
  
  function AcoBid:AcoDKPHostCallback(name,input,distribution,sender)
    if(input == "false" or sender == myname or Acodkp.hasHost == sender) then
      return false
    end
  
    Acodkp.hasHost = sender;
    print('|cFF00FF00'..Acodkp.hasHost..' started hosting DKP!')
  end
  
  function AcoBid:AcoDKPGetCallback(name,input,distribution,sender)
    if(distribution == "WHISPER") then
      local success, bid_ID, amount = AcoBid:Deserialize(input)
      biddingFrames[bid_ID].timer = false;
      biddingFrames[bid_ID].dkp:SetText("|cffffd100Available DKP: "..amount);
      biddingFrames[bid_ID].dkpamount = amount;
    end
  end
  
  function AcoBid:checkdkp(input)
  
    if IsInRaid() == false then
      print('|cFFFF0000You must be in a raid')
      return false
    end
  
    local playername = AcoBid:GetArgs(input, 1);
    
    if(Acodkp.timerrunning) then
      print('|cFFFF0000DKP query throttle!')
      return false
    end
    AcoBid:SendCommMessage("AcoDKPCheck", (playername or myname), "RAID")
    Acodkp['timer'] = true;
    Acodkp['timerrunning'] = true;
    AcoBid:ScheduleTimer(function() 
      Acodkp.timerrunning = false;
      if(Acodkp.timer) then
        print('|cFFFF0000No DKP response after 3 seconds! Someone needs to host DKP for queries to be made...')
      end
    end, 3)
    
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
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
      local unitTarget, castGuid, spellId = ...
      
      if unitTarget == "player" and spellId == 21358 then
        SendChatMessage("[AcoBid] I dowsed a rune!", "RAID")
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
  
    AcoBid:SendCommMessage("AcoDKPCheck", "0", "RAID")
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
          AcoBid:SendCommMessage("AcoBidCanLoot", destGuid, "RAID")
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
  
  function AcoBid:AcoBidQuintCallback(name,input,distribution,sender)
    checkSender = sender
  
    local aqualquint = GetItemCount(17333, false);
    local eternalquint = GetItemCount(22754, false);
  
    if(eternalquint > 0) then
      local cooldown = GetItemCooldown(22754)
      if(cooldown > 0) then
        AcoBid:SendCommMessage("AcoBidQuintR", "Cooldown", "RAID")
      else
        AcoBid:SendCommMessage("AcoBidQuintR", "Eternal (Ready)", "RAID")
      end
    elseif(aqualquint > 0) then
      AcoBid:SendCommMessage("AcoBidQuintR", "Aqual", "RAID")
    end
  
  end
  
  function AcoBid:AcoBidCanLootCallback(name,input,distribution,sender)
    if sender == myname then return false end
    if(lootlist[input] == nil) then lootlist[input] = {['looters']={},['timestamp'] = time()} end
    table.insert(lootlist[input].looters, sender)
  end
  
  function AcoBid:AcoBidItemCallback(name,input,distribution,sender)
    checkSender = sender
  
    local item_count = GetItemCount(input, false, false);
    local equipped = false;
  
    for i = 0, 19 do
      if(GetInventoryItemID('player',i) == GetItemInfoInstant(input)) then
        equipped = true
      end
    end
  
    AcoBid:SendCommMessage("AcoBidItemR", AcoBid:Serialize(input, item_count, equipped), "RAID")
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
end
