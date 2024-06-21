local _, env, db = ...; db = env.db;
local Menu = CPAPI.EventHandler(ConsolePortMenu, {
	'ACTIVE_PLAYER_SPECIALIZATION_CHANGED';
	'PLAYER_LOGIN';
});

local GameMenu, MenuRing = GameMenuFrame, ConsolePortMenuRing;

Menu:SetFrameStrata(GameMenu:GetFrameStrata())
Menu:SetFrameLevel(GameMenu:GetFrameLevel() - 1)

---------------------------------------------------------------
-- Settings
---------------------------------------------------------------
function Menu:OnDataLoaded()
	self:OnSizingChanged()
end

function Menu:OnSizingChanged()
	self:SetScale(db('gameMenuScale'))
end

function Menu:OnFrameShown(visible, frame)
	self.Owners[frame].visible = visible;
	for _, config in pairs(self.Owners) do
		if config.visible then
			local isRing = config.isRing;
			self.InnerMask:SetShown(isRing)
			self:InterpolatePoints(config)
			self:UpdateMasks(isRing)
			if config.callback then
				config.callback(frame)
			end
			self:CheckVisible()
			return self:Show()
		end
	end
	self:CheckVisible()
	self:Hide()
end

Menu.CheckVisible = CPAPI.Debounce(function(self)
	MenuRing:ShowHints(self:IsVisible())
end, Menu)

---------------------------------------------------------------
-- Events
---------------------------------------------------------------
function Menu:ACTIVE_PLAYER_SPECIALIZATION_CHANGED()
	local visual, isAtlas = env:GetSpecializationVisual()
	self.Gradient:SetAlpha(isAtlas and 0.5 or 0.75)
	if isAtlas then
		self.Background:SetTexCoord(0, 1, 0, 1)
		self.Background:SetAtlas(visual, true)
	else
		self.Background:SetTexCoord(0, 1, 0, 0.703125)
		self.Background:SetTexture(visual)
	end
end

Menu.PLAYER_LOGIN = Menu.ACTIVE_PLAYER_SPECIALIZATION_CHANGED;


---------------------------------------------------------------
-- Callbacks
---------------------------------------------------------------
do -- Skinning
	local x, y, w, h = 4, 5, 1, 2;
	function Menu:InterpolatePoints(config)
		local p1 = { self.Gradient:GetPoint(1)  };
		local p2 = { self.Gradient:GetPoint(2)  };
		local lt = { self.TopLine:GetPoint()    };
		local lb = { self.BottomLine:GetPoint() };
		local duration, elapsed = 1.0, 0.0;

		self:SetScript("OnUpdate", function(self, dt)
			elapsed = elapsed + dt;
			local t = elapsed / duration;
			p1[x], p1[y] = Lerp(p1[x], config.tlX, t), Lerp(p1[y], config.tlY, t)
			p2[x], p2[y] = Lerp(p2[x], config.brX, t), Lerp(p2[y], config.brY, t)
			lt[y], lb[y] = Lerp(lt[y], config.ltY, t), Lerp(lb[y], config.lbY, t)
			self.Gradient:SetPoint(unpack(p1))
			self.Gradient:SetPoint(unpack(p2))
			self.TopLine:SetPoint(unpack(lt))
			self.BottomLine:SetPoint(unpack(lb))
			if t >= 1.0 then
				self:SetScript('OnUpdate', nil)
			end
		end)
	end

	function Menu:UpdateMasks(useSquareMask)
		if self.useSquareMask == useSquareMask then return end;
		if not useSquareMask then
			self.Gradient:AddMaskTexture(self.LineMask)
			self.Background:AddMaskTexture(self.LineMask)
		else
			self.Gradient:RemoveMaskTexture(self.LineMask)
			self.Background:RemoveMaskTexture(self.LineMask)
		end
		self.useSquareMask = useSquareMask;
	end

	local SkinGameMenu = CPAPI.IsRetailVersion and function()
			GameMenu.Border:SetShown(false)
			GameMenu.Header:SetShown(false)
			GameMenuFrameConsolePort:SetPoint('TOP', 0, 30)
		end or function()
			GameMenuFrameHeader:SetShown(false)
			NineSliceUtil.SetLayoutShown(GameMenu, false)
		end;

	Menu.Owners = {
		[GameMenu] = {
			tlX = -100, tlY =  250, brX =  100, brY = -250;
			ltY =  102, lbY = -112;
			isRing   = false;
			visible  = false;
			callback = SkinGameMenu;
		};
		[MenuRing] = {
			tlX = -425, tlY =  350, brX =  425, brY = -350;
			ltY =  164, lbY = -178;
			isRing  = true;
			visible = false;
		};
	};
end

do -- Hooks
	local OnShow = GenerateClosure(Menu.OnFrameShown, Menu, true)
	local OnHide = GenerateClosure(Menu.OnFrameShown, Menu, false)

	for owner in pairs(Menu.Owners) do
		owner:HookScript('OnShow', OnShow)
		owner:HookScript('OnHide', OnHide)
	end
end

db:RegisterSafeCallbacks(Menu.OnSizingChanged, Menu,
	'Settings/gameMenuScale'
);