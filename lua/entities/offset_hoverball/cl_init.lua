include("shared.lua")

local gsModes = "offset_hoverball"
local gsClass = "offset_hoverball"
local ToolMode = GetConVar("gmod_toolmode")
local ShouldRenderLasers = GetConVar(gsModes.."_showlasers")
local AlwaysRenderLasers = GetConVar(gsModes.."_alwaysshowlasers")

local DecFormat = (GetConVar(gsModes.."_showdecimals"):GetBool() and "%.2f" or "%.0f")
cvars.AddChangeCallback( gsModes.."_showdecimals", function(_, _, value_new)
	if tobool(value_new) then DecFormat = "%.2f" else DecFormat = "%.0f" end
end )

-- Localize material as calling the function is expensive
local laser = Material("sprites/bluelaser1")
local light = Material("Sprites/light_glow02_add")

surface.CreateFont("OHBTipFont", {
	font = "Roboto Regular", 
	size = 24,
	weight = 13,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	extended = true
})

surface.CreateFont("OHBTipFontGlow", {
	font = "Roboto Regular",
	size = 24,
	weight = 13,
	scanlines = 0,
	antialias = true,
	extended = true,
	blursize = 5
})

surface.CreateFont("OHBTipFontSmall", {
	font = "Roboto Regular",
	size = 20,
	weight = 13,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	extended = true
})

local CoOHBName = Color(200, 200, 200)
local CoOHBValue = Color(80, 220, 80)
local CoOHBBack20 = Color(20, 20, 20)
local CoOHBBack60 = Color(60, 60, 60)
local CoOHBBack70 = Color(70, 70, 70)
local CoLaserBeam = Color(100, 100, 255)
local CoPulseMode = Color(0, 0, 0, 200)

local TableDrPoly = {
	{x = 0, y = 0},
	{x = 0, y = 0},
	{x = 0, y = 0}
}; TableDrPoly.Size = #TableDrPoly

local TableOHBInf = {
	{ID = 2, Name = language.GetPhrase("hoverui.header.hover_height")},
	{ID = 3, Name = language.GetPhrase("hoverui.header.hover_force")},
	{ID = 4, Name = language.GetPhrase("hoverui.header.air_resistance")},
	{ID = 5, Name = language.GetPhrase("hoverui.header.angular_damping")},
	{ID = 6, Name = language.GetPhrase("hoverui.header.hover_damping")},
	{ID = 7, Name = language.GetPhrase("hoverui.header.brake_resistance")}
}

local HeaderStr = {
	["1"] = language.GetPhrase("hoverui.header.brake_enabled"),
	["2"] = language.GetPhrase("hoverui.header.hover_disabled")
}

net.Receive(gsModes.."SendUpdateMask", function(len, ply)
	local ball, mask = net.ReadEntity(), net.ReadUInt(32)
	if(ball and ball:IsValid()) then ball.mask = mask end
end)

net.Receive(gsModes.."SendUpdateFilter", function(len, ply)
	local ball = net.ReadEntity()
	local eids = net.ReadString()
	if(ball and ball:IsValid()) then
		if(eids == "nil") then
			ball.props = nil
		else -- Something is exported
			local etab = (","):Explode(eids)
			for i = 1, #etab do
				etab[i] = Entity(tonumber(etab[i]))
			end; ball.props = etab
		end
	end
end)

local function GetTextSizeX(font, text)
	if(font) then surface.SetFont(font) end
	return select(1,surface.GetTextSize(text or "X"))
end

local function GetLongest( tab, idx )
	local mxn, mxv = 0, nil
	if idx ~= nil then
		for _, str in pairs(tab) do
			if #str[idx] > mxn then
				mxn = str[idx]:len(); mxv = str[idx]
			end
		end
	else
		for _, str in pairs(tab) do
			if #str > mxn then
				mxn = str:len(); mxv = str
			end
		end
	end
	return mxv
end

-- Grab textsize width of longest text on left of UI. (Will vary per language)
-- Also cache font height while here so we're not looking it up every frame. 
surface.SetFont("OHBTipFontSmall")
local LSWidth, CachedFH = surface.GetTextSize(GetLongest( TableOHBInf, "Name" ))
TableOHBInf.Size = #TableOHBInf

local function GetPulseColor()
	local Tim = 2.5 * CurTime()
	local Frc = Tim - math.floor(Tim)
	local Mco = math.abs(2 * (Frc - 0.5))
	local Com = math.Clamp(Mco, 0.1, 1)
	CoPulseMode.r = Com * 255
	CoPulseMode.g = Com * 200
	return CoPulseMode
end

function ENT:DrawTablePolygon(co, x1, y1, x2, y2, x3, y3)
	TableDrPoly[1].x = x1; TableDrPoly[1].y = y1
	TableDrPoly[2].x = x2; TableDrPoly[2].y = y2
	TableDrPoly[3].x = x3; TableDrPoly[3].y = y3
	surface.SetDrawColor(co)
	draw.NoTexture()
	surface.DrawPoly(TableDrPoly)
end

function ENT:DrawInfoPointy(PosX, PosY, SizX, SizY)
	-- Base functionality for drawing the pointy arrow. Please adjust the API calls only
	local x1, y1 = PosX, PosY+SizY/2    -- Triangle pointy point
	local x2, y2 = PosX+SizX, PosY      -- Triangle top point
	local x3, y3 = PosX+SizX, PosY+SizY -- Triangle bottom point
	self:DrawTablePolygon(CoOHBBack20, x1  , y1, x2, y2  , x3, y3) 	 -- Outline
	self:DrawTablePolygon(CoOHBBack60, x1+3, y1, x2, y2+2, x3, y3-2) -- Background
end

function ENT:DrawInfoBox(PosX, PosY, SizX, SizY)
	-- Base functionality for drawing the box container. Please adjust the API calls only
	draw.RoundedBox(8, PosX  , PosY  , SizX  , SizY  , CoOHBBack20) -- Back box (black)
	draw.RoundedBox(8, PosX+1, PosY+1, SizX-2, SizY-2, CoOHBBack60) -- Data box (Grey)
end

function ENT:DrawInfoTitle(StrT, PosX, PosY, SizX, SizY)
	local TxtX, TxtY = (PosX + (SizX / 2)), (PosY + 17)
	local CoDyn, StrT = GetPulseColor(), tostring(StrT)
	-- Base functionality for drawing the title. Please adjust the API calls only
	draw.RoundedBoxEx(8, PosX, PosY, SizX, SizY, CoOHBBack20, true, true, false, false) -- Header Outline
	draw.RoundedBoxEx(8, PosX+1, PosY+1, SizX-2, SizY, CoOHBBack70, true, true, false, false) -- Header BG
	draw.SimpleText(StrT, "OHBTipFontGlow", TxtX, TxtY, CoDyn, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(StrT, "OHBTipFont", TxtX, TxtY, CoOHBName, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function ENT:DrawInfoContent(TData, PosX, PosY, SizX, PadX, PadY)
	local Font = "OHBTipFontSmall" 	-- Localize font name
	local TxtY = CachedFH + PadY 	-- Use cached font width here

	-- Loop through TableOHBInf for labels and draw values from TData:
	for di = 1, TableOHBInf.Size do
		local inf = TableOHBInf[di]
		local idx, txt = inf.ID, inf.Name
		
		local hby = PosY + ((di - 1) * TxtY)
		local hbx, hvx = (PosX + PadX), (PosX + (SizX - PadX))
		
		draw.SimpleText(txt, Font, hbx, hby, CoOHBName, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(TData[idx], Font, hvx, hby, CoOHBValue, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end
end

function ENT:DrawLaser()
	if not IsValid(self) then return end
	local OwnPlayer = LocalPlayer()
	if AlwaysRenderLasers:GetBool() or
		(ToolMode:GetString() == gsModes and
		 OwnPlayer:GetActiveWeapon():GetClass() == "gmod_tool")
	then -- Draw the hoverball lasers
		local hbpos = self:WorldSpaceCenter()
		local tr = self:GetTrace(hbpos, -500)
		-- When the trace hits make 3D rendering contest and draw laser
		if tr.Hit then
			cam.Start3D()
				render.SetMaterial(laser)
				render.DrawBeam(hbpos, tr.HitPos, 5, 0, 0, CoLaserBeam)
				render.SetMaterial(light); tr.HitPos.z = tr.HitPos.z + 1
				render.DrawQuadEasy(tr.HitPos, tr.HitNormal, 30, 30, CoLaserBeam)
				render.DrawQuadEasy(hbpos, OwnPlayer:GetAimVector(), 30, 30, CoLaserBeam)
			cam.End3D()
		end
	end
end

hook.Add("HUDPaint", "OffsetHoverballs_MouseoverUI", function()
	local OwnPlayer = LocalPlayer()
	local LookingAt = OwnPlayer:GetEyeTrace().Entity

	-- Validate whenever we have to draw something.
	if not IsValid(LookingAt) then return end
	if LookingAt:GetClass() ~= gsClass then return end
	local HBPos = LookingAt:GetPos()
	local ASPos = OwnPlayer:GetShootPos()
	if (HBPos:DistToSqr(ASPos) > 90000) then return end

	-- When the HB tip is empty do nothing.
	local TipNW = LookingAt:GetNWString("OHB-BetterTip")
	if not TipNW or TipNW == "" then return end

	local HBData = TipNW:Split(",")
	local SW, SH, CN = ScrW(), ScrH(), TableOHBInf.Size

	-- Vars that control how we draw the mouseover UI:

	-- Adjusts position of the UI, including all components. (Polygon, text, etc)
	local BoxX = (SW / 2) + 60
	local BoxY = (SH / 2) - 80

	-- Text padding:
	local PadX = 10	-- Moves text inwards, away from walls.
	local PadY = 2	-- Spacing above/below each text line.

	-- Box width, must be wide enough to fit everything.
	local SizeX = 200
	-- Box height, scales with 'PadY' text padding.
	local SizeY = CN * CachedFH + (CN - 1) * PadY + PadX
	-- Height of header background. Can just leave at 30.
	local SizeT = 30
	-- Scaling multiplier for the little pointer arrow thing.
	local SizeP = 25
	-- X draw coordinate for the pointy triangle.
	local PoinX = HBPos:ToScreen().y - SizeP * 0.5
	
	-- Not sure why this was reverted, the code that replaced it still had the exact same error that I fixed in a previous PR. 
	-- Regardless, This code should support sizing the box to any value, as well as any language for the left labels.
	local RSWidth = ""
	for I=2,TableOHBInf.Size do
		HBData[I] = DecFormat:format(HBData[I]) -- Format decimals.
		if #HBData[I] > #RSWidth then RSWidth = HBData[I] end -- Get longest value in same loop.
	end
	RSWidth = GetTextSizeX("OHBTipFontSmall", RSWidth)
	
	-- Width of box is longest left + right line width, plus a little padding.
	SizeX = LSWidth + 30 + RSWidth

	if HBData[1] ~= "" then
		-- Overlay first argument is present, draw with header:
		LookingAt:DrawInfoBox(BoxX, BoxY+22, SizeX, SizeY+10)
		LookingAt:DrawInfoPointy(BoxX-SizeP+1, math.Clamp(PoinX, BoxY+30, BoxY+SizeY), SizeP, SizeP)
		LookingAt:DrawInfoTitle(HeaderStr[HBData[1]], BoxX, BoxY, SizeX, SizeT)
		LookingAt:DrawInfoContent(HBData, BoxX, BoxY+45, SizeX, PadX, PadY)
	else
		-- Draw contents without header.
		LookingAt:DrawInfoBox(BoxX, BoxY, SizeX, SizeY)
		LookingAt:DrawInfoPointy(BoxX-SizeP+1, math.Clamp(PoinX, BoxY+10, BoxY+SizeY-32), SizeP, SizeP)
		LookingAt:DrawInfoContent(HBData, BoxX, BoxY+15, SizeX, PadX, PadY)
	end
end)

function ENT:Draw()
	self:DrawModel()
	if ShouldRenderLasers:GetBool() or AlwaysRenderLasers:GetBool() then self:DrawLaser() end
end
