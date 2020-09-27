CPRStatus_ShowList = 4;
CPRStatus_RangeStatus = 0;
CPRStatus_CurrentTime = 0;
CPRStatus_LastTimeCheck = 0;
CPRStatus_Scale = 2;
CPRStatus_Locked = 0;
CPRStatus_Players = {};
CPRActionButton = 120;

function CPR_OnLoad()
	this:RegisterEvent("VARIABLES_LOADED");
	SLASH_CPR1 = "/cpr";
	SlashCmdList["CPR"] = CPR_SlashHandler;
end

function CPR_SlashHandler(arg1)
	local _, _, command, args = string.find(arg1, "(%w+)%s?(.*)");
	if(command) then
		command = strlower(command);
	else
		command = "";
	end

	if(command == "lock") then
		CPRStatus_Locked = 1;
		CPR_Print("Position locked.");
	elseif(command == "unlock") then
		CPRStatus_Locked = 0;
		CPR_Print("Position unlocked.");
	elseif(command == "reset") then
		CPRStatus_Locked = 0;
		CPRFrame:SetScale(2);
		CPRStatus_Scale = 2;
		CPRActionButton = -1;
		CPRFrame:ClearAllPoints();
		CPRFrame:SetPoint("CENTER", "UIParent");
		CPR_Print("Position reset|r.");
	elseif(command == "scale") then
		if(tonumber(args)) then
			local newscale = tonumber(args);
			CPRStatus_Locked = 0;
			CPRFrame:SetScale(newscale);
			CPRStatus_Scale = newscale;
			CPRFrame:ClearAllPoints();
			CPRFrame:SetPoint("CENTER", "UIParent");
			CPR_Print("Scale is "..newscale..".");
		end
	elseif(command == "button") then
		local button = tonumber(args);
		if button < 1 or button > 120 then
			CPR_Print("Enter a number between 1 and 120.");
			return;
		else
			CPRActionButton = button;
			CPR_Print("You choose the action button "..button..".");
		end
	elseif(command == "list") then
		if(tonumber(args)) then
			local newlines = tonumber(args);
			CPRStatus_ShowList = newlines;
			CPR_Print("Player List is "..newlines..".");
		end
	elseif(command == "help") then
		CPR_Print("Command List:");
		DEFAULT_CHAT_FRAME:AddMessage("     /cpr on/off", 0.988, 0.819, 0.086);
		DEFAULT_CHAT_FRAME:AddMessage("     /cpr button 1..120", 0.988, 0.819, 0.086);
		DEFAULT_CHAT_FRAME:AddMessage("     /cpr list 0..40", 0.988, 0.819, 0.086);
		DEFAULT_CHAT_FRAME:AddMessage("     /cpr scale 1..9", 0.988, 0.819, 0.086);
		DEFAULT_CHAT_FRAME:AddMessage("     /cpr reset", 0.988, 0.819, 0.086);
		DEFAULT_CHAT_FRAME:AddMessage("     /cpr lock", 0.988, 0.819, 0.086);
		DEFAULT_CHAT_FRAME:AddMessage("     /cpr unlock", 0.988, 0.819, 0.086);
	elseif(command == "on") then
		CPR_On();
	elseif(command == "off") then
		CPR_Off();
	else
		CPR_Print("Try 'cpr help'.");
	end
end

function CPR_OnEvent(event)
	if(event == "VARIABLES_LOADED") then
		CPRFrame:SetScale(CPRStatus_Scale);
	end

	-- slot 120 (default) is already in use for druids
	local _, PlayerClass = UnitClass("player");
	if PlayerClass == "DRUID" then
		CPRActionButton = -1;
	end
end

function CPR_OnUpdate(timeElapsed)
	CPRStatus_CurrentTime = CPRStatus_CurrentTime + timeElapsed;
	if(CPRStatus_CurrentTime < (CPRStatus_LastTimeCheck + 1)) then
		return;
	end

	if (not CPR_HasBandageOnAction()) then
		CPR_Print("You need a bandage on action button "..CPRActionButton..".");
		CPR_Off();
		return;
	end

	-- saving the target name to later restore the target
	local targetName = UnitName("target");

	-- range checking loop
	CPRStatus_Players = {};
	for i = 1, GetNumRaidMembers(), 1 do
		local unitid = "raid"..i;
		local unitName, _ = UnitName(unitid);

		if (not UnitIsDeadOrGhost(unitid)) and (not UnitIsUnit(unitid, "player")) then
			if CheckInteractDistance(unitid, 2) then -- less than 11.11 yards
				tinsert(CPRStatus_Players, unitName);
			elseif CheckInteractDistance(unitid, 4) then -- less than 28 yards
				-- check if bandage is in range (15 yards)
				TargetUnit(unitid);
				if (IsActionInRange(CPRActionButton) == 1) then
					tinsert(CPRStatus_Players, unitName);
				end

				-- restore the target
				if not targetName then
					ClearTarget();
				elseif targetName ~= unitName then
					TargetLastTarget();
				end
			end
		end
	end

	if(getn(CPRStatus_Players) > 0) then
		CPRStatus_RangeStatus = 1;
		CPRStatusTexture:SetVertexColor(1,0,0);
	else
		CPRStatus_RangeStatus = 0;
		CPRStatusTexture:SetVertexColor(0,1,0);
	end

	CPR_UpdateList();
	CPRStatus_LastTimeCheck = CPRStatus_CurrentTime;
end

function CPR_UpdateList()
	CPRTooltip:SetOwner(CPRFrame, "ANCHOR_BOTTOMRIGHT");
	CPRTooltip:SetFrameStrata("MEDIUM");
	if(CPRStatus_RangeStatus == 0 or CPRStatus_ShowList == 0) then
		CPRTooltip:Hide();
	else
		CPRTooltip:ClearLines();
		CPRTooltip:AddLine("Linking:",0.890,0.811,0.341,0);
		local index = 1;
		for _, player in CPRStatus_Players do
			CPRTooltip:AddLine("- "..player,0.666,0.666,1,0);
			if(index >= CPRStatus_ShowList) then
				break;
			end
			index = index + 1;
		end
		CPRTooltip:Show();
	end
end

function CPR_HasBandageOnAction()
	local texturePath = GetActionTexture(CPRActionButton);
	return (texturePath ~= nil and string.find(texturePath, "Bandage") ~= nil);
end

function CPR_SetupBandage()
	for i = 0,4 do
		for j = 1, GetContainerNumSlots(i) do
			local texturePath = GetContainerItemInfo(i, j)
			if (texturePath ~= nil and string.find(texturePath, "Bandage") ~= nil) then
				PickupContainerItem(i, j);
				PlaceAction(CPRActionButton);
				ClearCursor();
				return true;
			end
		end
	end
	return false;
end

function CPR_On()
	if (CPRActionButton < 1 or CPRActionButton > 120) then
		message("Choose an action button with '/cpr button X' where X is the button id you want.");
		return;
	end
	
	local found = true;
	if (not CPR_HasBandageOnAction()) then
		found = CPR_SetupBandage();
	end

	if found then
		CPRFrame:Show();
		CPR_Print("On.");
	else
		message("You need a bandage in your bag !");
	end
end

function CPR_Off()
	CPRFrame:Hide();
	CPRTooltip:Hide();
	CPR_Print("Off.");
end

function CPR_Print(msg)
	local prefix = "|cFFFF9955CPR: |r"
	DEFAULT_CHAT_FRAME:AddMessage(prefix..msg, 0.988, 0.819, 0.086);
end
