-- GetActionID: Returns the correct ID for an action slot
-- GetActionInfo: Returns information about an action slot
-- GetActionSpellSlot: Returns spell information about an action slot
-- IsHarmfulAction: Returns whether the action slot is harmful or not
-- IsHelpfulAction: Returns whether the action slot is helpful or not
-- IsNeutralAction: Returns whether the action slot has no particular target implication

function ConsolePort:RegisterSpellHeader(header)
	if not InCombatLockdown() then
		local driver, current = self:GetActionPageDriver()
		
		header:SetAttribute("actionpage", current)
		RegisterStateDriver(header, "actionpage", driver)

		header:SetFrameRef("actionBar", MainMenuBarArtFrame)
		header:SetFrameRef("overrideBar", OverrideActionBar)

		header:SetAttribute("_onstate-actionpage", [[      
			if HasVehicleActionBar() then
				newstate = GetVehicleBarIndex()
			elseif HasOverrideActionBar() then
				newstate = GetOverrideBarIndex()
			elseif HasTempShapeshiftActionBar() then
				newstate = GetTempShapeshiftBarIndex()
			elseif GetBonusBarOffset() > 0 then
				newstate = GetBonusBarOffset()+6
			else
				newstate = GetActionBarPage()
			end
			self:SetAttribute("actionpage", newstate)
		]])

		header:SetAttribute("GetActionID", [[
			local id = ...
			if id then
				local page = self:GetAttribute("actionpage")
				if id >= 1 and id <= 12 then
					return ( ( page - 1) * 12 ) + id
				else
					return id
				end
			end
		]])
		header:SetAttribute("GetActionInfo", [[
			local id = self:RunAttribute("GetActionID", ...)
			return GetActionInfo(id)
		]])
		header:SetAttribute("GetActionSpellSlot", [[
			local type, spellID, subType = self:RunAttribute("GetActionInfo", ...)
			if type == "spell" and subType == "spell" then
				return FindSpellBookSlotBySpellID(spellID)
			end
		]])
		header:SetAttribute("IsHarmfulAction", [[
			local type, id = self:RunAttribute("GetActionInfo", ...)
			if type == "spell" then
				local slot = self:RunAttribute("GetActionSpellSlot", ...)
				if slot then
					return IsHarmfulSpell(slot, "spell")
				end
			elseif type == "item" then
				return IsHarmfulItem(id)
			end
		]])
		header:SetAttribute("IsHelpfulAction", [[
			local type, id = self:RunAttribute("GetActionInfo", ...)
			if type == "spell" then
				local slot = self:RunAttribute("GetActionSpellSlot", ...)
				if slot then
					return IsHelpfulSpell(slot, "spell")
				end
			elseif type == "item" then
				return IsHelpfulItem(id)
			end
		]])
		header:SetAttribute("IsNeutralAction", [[
			return self:RunAttribute("IsHelpfulAction", ...) == self:RunAttribute("IsHarmfulAction", ...)
		]])
	end
end

function ConsolePort:UnegisterSpellHeader(header)
	if not InCombatLockdown() then
		UnregisterStateDriver(header, "actionpage")

		header:SetFrameRef("actionBar", nil)
		header:SetFrameRef("overrideBar", nil)

		header:SetAttribute("actionpage", nil)
		header:SetAttribute("GetActionInfo", nil)
		header:SetAttribute("GetActionSpellSlot", nil)
		header:SetAttribute("IsHarmfulAction", nil)
		header:SetAttribute("IsHelpfulAction", nil)
		header:SetAttribute("IsNeutralAction", nil)
	end
end

