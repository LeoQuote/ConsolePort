local _, env = ...; env.LootButtonMixin = CreateFromMixins(CPActionButtonMixin);
local FocusTooltip = CreateFrame('GameTooltip', 'ConsolePortLootButtonTooltip', ConsolePortLootFrame, 'GameTooltipTemplate')

---------------------------------------------------------------
-- Loot button scripts
---------------------------------------------------------------
local LootButton = env.LootButtonMixin;

function LootButton:OnLoad()
	CPAPI.Start(self)
	self:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
	self:RegisterForDrag('LeftButton')
end

function LootButton:OnDragStart()
	self:GetParent():StartMoving()
end

function LootButton:OnDragStop()
	self:GetParent():StopMovingOrSizing()
end

function LootButton:OnClick()
	LootSlot(self:GetID())
end

function LootButton:OnEnter()
	local slot = self:GetID()
	local slotType = GetLootSlotType(slot)

	for sibling in self:GetParent():EnumerateActive() do
		sibling:OnLeave()
	end

	if ( slotType == LOOT_SLOT_ITEM ) then
		FocusTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 0, 50)
		FocusTooltip:SetLootItem(slot)
		FocusTooltip:Show()
		CursorUpdate(self)
	end
	if ( slotType == LOOT_SLOT_CURRENCY ) then
		FocusTooltip:SetOwner(self, 'ANCHOR_BOTTOMRIGHT', 0, 50)
		FocusTooltip:SetLootCurrency(slot)
		FocusTooltip:Show()
		CursorUpdate(self)
	end

	if FocusTooltip:IsOwned(self) then
		FocusTooltip:SetBackdrop(nil)
		local width, height = (FocusTooltip:GetWidth() or 330) + 50, (FocusTooltip:GetHeight() or 50)
		self.NameFrame:SetSize(width < 330 and 330 or width, height < 50 and 50 or height)
		self.Text:SetAlpha(0)
	end

	self:LockHighlight()
	self.QuestTexture:SetDrawLayer('HIGHLIGHT', 7)
end

function LootButton:OnLeave()
	if FocusTooltip:IsOwned(self) then
		FocusTooltip:Hide()
	end
	self.hasTooltipFocus = false;
	self.NameFrame:SetSize(300, 50)
	self.Text:SetAlpha(1)
	self:UnlockHighlight()
	self.QuestTexture:SetDrawLayer('OVERLAY')
end

function LootButton:OnHide()
	self:OnLeave()
end

---------------------------------------------------------------
-- Content handling
---------------------------------------------------------------
function LootButton:SetQuality(itemQuality)
	local colors = ITEM_QUALITY_COLORS[itemQuality];
	if colors then
		self.Text:SetTextColor(colors.r, colors.g, colors.b)
	else
		self.Text:SetTextColor(1, 1, 1)
	end
end

function LootButton:SetText(text)
	self.Text:SetText(text)
end

function LootButton:SetQuestItem(isQuestItem)
	self.QuestTexture:SetShown(isQuestItem)
end

function LootButton:Update()
	local texture, name, quantity, currencyID, quality, locked, isQuestItem, questId, isActive = GetLootSlotInfo(self:GetID())
	self:SetIcon(texture)
	self:SetCount(quantity)
	self:SetQuality(quality)
	self:SetText(name)
	self:SetQuestItem(isQuestItem)
end