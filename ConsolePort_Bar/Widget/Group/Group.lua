local _, env, db = ...; db = env.db;
---------------------------------------------------------------
local GROUP, GROUP_BUTTON = 'Group', 'GroupButton';

---------------------------------------------------------------
local Button = CreateFromMixins(env.ProxyButton, env.ConfigurableWidgetMixin);
---------------------------------------------------------------
do  -- Alpha update closures
	Button.AlphaState = env.CreateFlagClosures({
		OnCooldown    = 0x02;
		OverlayActive = 0x04;
		MouseOver     = 0x08;
		ShowGrid      = 0x10;
	});
end

function Button:OnMouseMotionFocus()
	self:UpdateAlpha(self.AlphaState.MouseOver, true)
end

function Button:OnMouseMotionClear()
	self:UpdateAlpha(self.AlphaState.MouseOver, false)
end

function Button:OnOverlayGlow(state)
	self:UpdateAlpha(self.AlphaState.OverlayActive, state)
end

function Button:OnCooldownSet(cooldown, _, duration)
	local onCooldown = (cooldown and duration and duration > 2);
	self:UpdateAlpha(self.AlphaState.OnCooldown, onCooldown)
end

function Button:OnCooldownClear()
	self:UpdateAlpha(self.AlphaState.OnCooldown, false)
end

function Button:ForceIgnoreParentAlpha(state)
	self.forceIgnore = state;
	self:UpdateAlpha()
end

function Button:UpdateAlpha(closure, state)
	if closure then
		self.alpha = closure(self.alpha or 0, state);
	end
	local ignoreParentAlpha = self.alpha ~= 0;
	if ( self.forceIgnore ~= nil  ) then
		ignoreParentAlpha = self.forceIgnore;
	end
	self:SetIgnoreParentAlpha(ignoreParentAlpha)
end

function Button:OnLoad()
	env.ProxyButton.OnLoad(self)
	Mixin(self.cooldown, env.ProxyCooldown):OnLoad()

	self:SetAttribute('id', self.id)
	self:SetAttribute('flyoutDirection', 'DOWN')
	self:SetAttribute(CPAPI.SkipHotkeyRender, true)

	self:HookScript('OnEnter', self.OnMouseMotionFocus)
	self:HookScript('OnLeave', self.OnMouseMotionClear)

	if CPAPI.IsClassicVersion then
		-- Assert assets on all client flavors
		local skinner = env.LIB.SkinUtility;
		skinner.GetIconMask(self)
		skinner.GetHighlightTexture(self)
		skinner.GetCheckedTexture(self)
		skinner.GetPushedTexture(self)
		skinner.GetCheckedTexture(self)
		skinner.GetSlotBackground(self)
		self:SetSize(45, 45)
		self.IconMask:SetPoint('CENTER', self.icon, 'CENTER', 0, 0)
		self.IconMask:SetSize(46, 46)
		self.IconMask:SetTexture(
			CPAPI.GetAsset([[Textures\Button\EmptyIcon]]),
			'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE'
		);
	end

	self:UpdateLocal(true)
end

function Button:SetProps(props)
	self:SetDynamicProps(props)
	self:OnPropsUpdated()
end

function Button:OnPropsUpdated()
	local props = self.props;
	local pos = props.pos;
	self:ClearAllPoints()
	self:SetPoint(pos.point, pos.x, pos.y)
end

function Button:SetBindings(set)
	local emulation = db.Gamepad.Index.Modifier.Owner[self.id];
	for modifier, binding in pairs(set) do
		if self:IsModifierActive(modifier) then
			if not emulation then
				self:RefreshBinding(modifier, binding)
			else
				self:RefreshBinding(modifier, set[env.ModComplement(modifier, emulation)])
			end
		end
	end
end

function Button:IsModifierActive(modifier)
	return self:GetParent():IsModifierActive(modifier)
end

function Button:ShouldOverrideActionBarBinding()
    return true; -- just return true here, since we already filter by modifier in SetBindings
end

function Button:GetOverrideBinding(modifier)
	return modifier..self.id;
end

function Button:GetSnapSize()
	return 5;
end

if CPAPI.IsClassicVersion then
	local TextureInfo = {
		NormalTexture = {
			atlas = 'UI-HUD-ActionBar-IconFrame-AddRow';
			size  = {52, 51};
		};
		PushedTexture = {
			atlas = 'UI-HUD-ActionBar-IconFrame-AddRow-Down';
			size  = {52, 51};
		};
		HighlightTexture = {
			atlas = 'UI-HUD-ActionBar-IconFrame-Mouseover';
			size  = {46, 45};
		};
		CheckedTexture = {
			atlas = 'UI-HUD-ActionBar-IconFrame-Mouseover';
			size  = {46, 45};
		};
	};
	function Button:UpdateLocal()
		if self.MasqueSkinned then return end;
		if self.config.hideElements.border then
			self.NormalTexture:SetTexture()
			self.PushedTexture:SetTexture()
			self.icon:RemoveMaskTexture(self.IconMask)
			self.HighlightTexture:SetSize(52, 51)
			self.HighlightTexture:SetPoint('TOPLEFT', self, 'TOPLEFT', -2.5, 2.5)
			self.CheckedTexture:SetSize(52, 51)
			self.CheckedTexture:SetPoint('TOPLEFT', self, 'TOPLEFT', -2.5, 2.5)
			self.cooldown:ClearAllPoints()
			self.cooldown:SetAllPoints()
		else
			for key, info in pairs(TextureInfo) do
				local texture = self[key];
				CPAPI.SetAtlas(texture, info.atlas)
				texture:SetSize(unpack(info.size))
				texture:ClearAllPoints()
				texture:SetPoint('TOPLEFT', 0, 0)
			end
			self.icon:SetAllPoints()
			self.cooldown:ClearAllPoints()
			self.cooldown:SetPoint('TOPLEFT', self, 'TOPLEFT', 3, -2)
			self.cooldown:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -3, 3)
		end
	end
end

---------------------------------------------------------------
CPGroupBar = Mixin({
---------------------------------------------------------------
	FadeIn = db.Alpha.FadeIn;
	snapToPixels = 5;
	AlphaEvents = {
		ACTIONBAR_SHOWGRID = { Button.AlphaState.ShowGrid, true  };
		ACTIONBAR_HIDEGRID = { Button.AlphaState.ShowGrid, false };
	};
---------------------------------------------------------------
}, CPActionBar, env.MovableWidgetMixin);
---------------------------------------------------------------

function CPGroupBar:OnLoad()
	CPActionBar.OnLoad(self)
	self.buttons   = {};
	self.modifiers = {};

	env:RegisterCallback('OnNewBindings', self.OnNewBindings, self)
	env:RegisterCallback('OnOverlayGlow', self.OnOverlayGlow, self)
	db:RegisterCallback('OnHintsFocus', self.OnHints, self, false)
	db:RegisterCallback('OnHintsClear', self.OnHints, self, nil)

	self:RegisterPageResponse([[
		local newstate = ...;
		self:ChildUpdate('actionpage', newstate)
	]])
	self:HookScript('OnEvent', self.OnAlphaEvent)
	for event in pairs(self.AlphaEvents) do
		self:RegisterEvent(event)
	end
end

function CPGroupBar:SetProps(props)
	self:SetDynamicProps(props)
	self:OnDriverChanged()
	self:UpdateButtons(props.children or {})
	self:RegisterVisibilityDriver(props.visibility)
end

function CPGroupBar:OnPropsUpdated()
	self:SetProps(self.props)
end

function CPGroupBar:OnRelease()
	env:Map(GROUP_BUTTON, nil, function(button)
		if ( button:GetParent() == self ) then
			env:Release(button)
		end
	end)
end

function CPGroupBar:UpdateButtons(buttons)
	self:OnRelease()
	wipe(self.buttons)
	for buttonID, props in pairs(buttons) do
		local button = env:Acquire(GROUP_BUTTON, env.MakeID('%s_%s', self:GetName(), buttonID), buttonID, self)
		button:Show()
		button:SetProps(props)
		self.buttons[buttonID] = button;
	end
end

function CPGroupBar:OnNewBindings(bindings)
	if not env:IsActive(self) then return end;
	for buttonID, set in pairs(bindings) do
		local button = self.buttons[buttonID];
		if button then
			button:SetBindings(set)
		end
	end
	self:RunAttribute(env.Attributes.OnPage, self:GetAttribute('actionpage'))
	self:RunDriver('modifier')
end

function CPGroupBar:OnDriverChanged()
	local driver = env.ConvertDriver(self.props.modifier);
	wipe(self.modifiers)
	for condition, prefix in driver:gmatch('(%b[])([^;]+)') do
		condition, prefix = condition:sub(2, -2), prefix:trim();
		self.modifiers[prefix] = condition;
	end
	self:RegisterModifierDriver(driver, [[
		self:SetAttribute('state', newstate)
		control:ChildUpdate('state', newstate)
	]])

	driver = self.props.rescale;
	self:RegisterDriver('rescale', driver, [[
		newstate = (tonumber(newstate) or 100) * 0.01;
		if newstate > 0 then
			self:SetScale(newstate)
		end
	]])

	driver = self.props.opacity;
	self:RegisterDriver('opacity', driver, [[
		newstate = (tonumber(newstate) or 100) * 0.01;
		if newstate < 0 then newstate = 0 end;
		if newstate > 1 then newstate = 1 end;
		self:CallMethod('FadeIn', 0.05, ALPHA or 0, newstate)
		ALPHA = newstate;
	]])
end

function CPGroupBar:IsModifierActive(modifier)
	return not not self.modifiers[modifier];
end

function CPGroupBar:OnOverlayGlow(state, button)
	local ownedButton = self.buttons[button.id];
	if ownedButton and ( ownedButton == button ) then
		ownedButton:OnOverlayGlow(state)
	end
end

function CPGroupBar:OnHints(state)
	for _, button in pairs(self.buttons) do
		button:ForceIgnoreParentAlpha(state)
	end
end

function CPGroupBar:OnAlphaEvent(event)
	local eventClosure = self.AlphaEvents[event];
	if eventClosure then
		local closure, state = unpack(eventClosure);
		for _, button in pairs(self.buttons) do
			button:UpdateAlpha(closure, state)
		end
	end
end

---------------------------------------------------------------
do -- Group bar factory
---------------------------------------------------------------

env:AddFactory(GROUP, function(id)
	local frame = CreateFrame('Frame', env.MakeID('ConsolePortGroup%s', id), env.Manager, 'CPGroupBar')
	frame.id = id;
	frame:OnLoad()
	return frame;
end, env.Interface.Group)

env:AddFactory(GROUP_BUTTON, function(id, buttonID, parent)
	local button = Mixin(env.LAB:CreateButton(buttonID, id, parent, env.Const.Cluster.LABConfig), Button) -- TODO: LABConfig?
	button.Hotkey = Mixin(CreateFrame('Frame', nil, button), env.ProxyHotkey)
	button.Hotkey.icon = button.Hotkey:CreateTexture(nil, 'OVERLAY', nil, 7)
	button.Hotkey.icon:SetAllPoints()
	button.Hotkey:OnLoad(buttonID, 16, 12, {'CENTER', button, 'TOP', 0, -2})
	button:OnLoad()
	return button;
end)

end -- Group bar factory