RagnarosWarnerStatus_ShowList = 4;
RagnarosWarnerStatus_RangeStatus = 0;
RagnarosWarnerStatus_CurrentTime = 0;
RagnarosWarnerStatus_LastTimeCheck = 0;
RagnarosWarnerStatus_Scale = 2;
RagnarosWarnerStatus_Locked = 0;
RagnarosWarnerStatus_Players = {};

function RagnarosWarner_OnLoad()
	this:RegisterEvent("VARIABLES_LOADED");
	SLASH_RagnarosWarner1 = "/ragWarn";
	SlashCmdList["RagnarosWarner"] = RagnarosWarner_SlashHandler;
end

function RagnarosWarner_SlashHandler(arg1)
	local _, _, command, args = string.find(arg1, "(%w+)%s?(.*)");
	if(command) then
		command = strlower(command);
	else
		command = "";
	end
	
	if(command == "lock") then
		RagnarosWarnerStatus_Locked = 1;
		RagnarosWarner_Print("|cFFFF9955Position:|r |cFFFFFF00Locked|r.");
	elseif(command == "unlock") then
		RagnarosWarnerStatus_Locked = 0;
		RagnarosWarner_Print("|cFFFF9955Position:|r |cFFFFFF00Unlocked|r.");
	elseif(command == "reset") then
		RagnarosWarnerStatus_Locked = 0;
		RagnarosWarnerFrame:SetScale(2);
		RagnarosWarnerStatus_Scale = 2;
		RagnarosWarnerFrame:ClearAllPoints();
		RagnarosWarnerFrame:SetPoint("CENTER", "UIParent");
		RagnarosWarner_Print("|cFFFF9955Position:|r |cFFFFFF00Reset|r.");
	elseif(command == "scale") then
		if(tonumber(args)) then
			local newscale = tonumber(args);
			RagnarosWarnerStatus_Locked = 0;
			RagnarosWarnerFrame:SetScale(newscale);
			RagnarosWarnerStatus_Scale = newscale;
			RagnarosWarnerFrame:ClearAllPoints();
			RagnarosWarnerFrame:SetPoint("CENTER", "UIParent");
			RagnarosWarner_Print("|cFFFF9955Scale:|r |cFFFFFF00"..newscale.."|r.");
		end
	elseif(command == "list") then
		if(tonumber(args)) then
			local newlines = tonumber(args);
			RagnarosWarnerStatus_ShowList = newlines;
			RagnarosWarner_Print("|cFFFF9955Player List:|r |cFFFFFF00"..newlines.."|r.");
		end
	elseif(command == "help") then
		RagnarosWarner_Print("Command List:");
		DEFAULT_CHAT_FRAME:AddMessage("     /ragWarn on/off", 0.988, 0.819, 0.086);
		DEFAULT_CHAT_FRAME:AddMessage("     /ragWarn list 0..40", 0.988, 0.819, 0.086);
		DEFAULT_CHAT_FRAME:AddMessage("     /ragWarn scale 1..9", 0.988, 0.819, 0.086);
		DEFAULT_CHAT_FRAME:AddMessage("     /ragWarn reset", 0.988, 0.819, 0.086);
		DEFAULT_CHAT_FRAME:AddMessage("     /ragWarn lock", 0.988, 0.819, 0.086);
		DEFAULT_CHAT_FRAME:AddMessage("     /ragWarn unlock", 0.988, 0.819, 0.086);
		RagnarosWarner_Print("Command List.");
	elseif(command == "on") then
		RagnarosWarnerFrame:Show();
		RagnarosWarner_Print("|cFFFF9955Ragnaros Warner:|r |cFFFFFF00On|r.");
	elseif(command == "off") then
		RagnarosWarner_Off();
		RagnarosWarner_Print("|cFFFF9955Ragnaros Warner:|r |cFFFFFF00Off|r.");
	else
		RagnarosWarner_Print("Type /ragWarn help for a command list.");
	end
end

function RagnarosWarner_OnEvent(event)
	if(event == "VARIABLES_LOADED") then
		RagnarosWarnerFrame:SetScale(RagnarosWarnerStatus_Scale);
	end
end

function RagnarosWarner_OnUpdate(arg1)
	RagnarosWarnerStatus_CurrentTime = RagnarosWarnerStatus_CurrentTime + arg1;
	if(RagnarosWarnerStatus_CurrentTime > (RagnarosWarnerStatus_LastTimeCheck+0.1)) then
		local unitid;
		RagnarosWarnerStatus_Players = {};
		for i = 1, GetNumRaidMembers(), 1 do
			unitid = "raid"..i;
			if(not UnitIsDeadOrGhost(unitid)) then
				if(not UnitIsUnit(unitid, "player")) then
					if(CheckInteractDistance(unitid, 2)) then 
						tinsert(RagnarosWarnerStatus_Players, (UnitName(unitid)));
					end
				end
			end
		end
		if(getn(RagnarosWarnerStatus_Players) > 0) then
			RagnarosWarnerStatus_RangeStatus = 1;
			RagnarosWarnerStatusTexture:SetVertexColor(1,0,0);
		else
			RagnarosWarnerStatus_RangeStatus = 0;
			RagnarosWarnerStatusTexture:SetVertexColor(0,1,0);
		end
		RagnarosWarner_UpdateList();
		RagnarosWarnerStatus_LastTimeCheck = RagnarosWarnerStatus_CurrentTime;
	end
end

function RagnarosWarner_UpdateList()
	RagnarosWarnerTooltip:SetOwner(RagnarosWarnerFrame, "ANCHOR_BOTTOMRIGHT");
	RagnarosWarnerTooltip:SetFrameStrata("MEDIUM");
	if(RagnarosWarnerStatus_RangeStatus == 0 or RagnarosWarnerStatus_ShowList == 0) then
		RagnarosWarnerTooltip:Hide();
	else
		RagnarosWarnerTooltip:ClearLines();
		RagnarosWarnerTooltip:AddLine("Linking:",0.890,0.811,0.341,0);
		local index = 1;
		for key, player in RagnarosWarnerStatus_Players do
			for i=1,MAX_RAID_MEMBERS do
				local partyid = "raid"..i;
				if((player == (UnitName(partyid))) and UnitExists(partyid) and UnitInParty(partyid)) then
					RagnarosWarnerTooltip:AddLine("- "..player,0.666,0.666,1,0);
				else
					if((player == (UnitName(partyid))) and UnitExists(partyid) and not UnitInParty(partyid)) then
						RagnarosWarnerTooltip:AddLine("- "..player,1,0.498,0,0);
					end
				end
			end
			if(index >= RagnarosWarnerStatus_ShowList) then
				break;
			end
			index = index + 1;
		end
		RagnarosWarnerTooltip:Show();
	end
end

function RagnarosWarner_Off()
	RagnarosWarnerFrame:Hide();
	RagnarosWarnerTooltip:Hide();
	RagnarosWarnerStatusBar:Hide();
end

function RagnarosWarner_Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("<Ragnaros Warner> "..msg, 0.988, 0.819, 0.086);
end
