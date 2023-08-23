
include("shared.lua")

local laser = Material("sprites/bluelaser1")
local light = Material("Sprites/light_glow02_add")
local ShouldRenderLasers = GetConVar("offset_hoverball_showlasers")
local ShouldAlwaysRenderLasers = GetConVar("offset_hoverball_alwaysshowlasers")
local ToolMode = GetConVar("gmod_toolmode")

--[[
 Based on garrysmod/lua/derma/init.lua
 It looks like the game comes with the Roboto font,
 so it should be safe to use on all platforms?
]]
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

local BoxOffsetX = (ScrW() / 2) + 60
local BoxOffsetY = (ScrH() / 2) - 50

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
	{2, "Hover height:    "},
	{3, "Hover force:     "},
	{4, "Air resistance:  "},
	{5, "Angular damping: "},
	{6, "Hover damping:   "},
	{7, "Brake resistance:"}
}; TableOHBInf.Size = #TableOHBInf

function ENT:GetPulseColor()
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

function ENT:DrawInfoPointy(PosX)
	local PosY = ScrH()/2-75 -- Draws at same height regardless of the box size. (Pointing at hoverball)
	self:DrawTablePolygon(CoOHBBack20, PosX - 17, PosY + 80, PosX    , PosY + 64, PosX    , PosY + 96)
	self:DrawTablePolygon(CoOHBBack60, PosX - 15, PosY + 80, PosX + 1, PosY + 65, PosX + 1, PosY + 95)
end

function ENT:DrawInfoBox(PosX, PosY, SizX, SizY)
	draw.RoundedBox(8, PosX    , PosY + 22, SizX    , SizY + 2, CoOHBBack20)
	draw.RoundedBox(8, PosX + 1, PosY + 23, SizX - 2, SizY    , CoOHBBack60)
end

function ENT:DrawInfoTitle(StrT, PosX, PosY, SizX, SizY)
	local CoDyn, StrT = self:GetPulseColor(), tostring(StrT)
	
	draw.RoundedBoxEx(8, PosX, PosY-5, SizX, 30, CoOHBBack20, true, true, false, false)				-- Header Outline
	draw.RoundedBoxEx(8, PosX + 1, PosY-4, SizX - 2, 30, CoOHBBack70, true, true, false, false) 	-- Header BG
	draw.SimpleText(StrT, "OHBTipFontGlow", PosX + (SizX / 2), PosY + 24, CoDyn, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(StrT, "OHBTipFont", PosX + (SizX / 2), PosY + 24, CoOHBName, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function ENT:DrawLaser()
	if not IsValid(self) then return end
	local OwnPlayer = LocalPlayer()
	if ShouldAlwaysRenderLasers:GetBool() or
		(ToolMode:GetString() == "offset_hoverball" and
		 OwnPlayer:GetActiveWeapon():GetClass() == "gmod_tool")
	then -- Draw the hoverball lasers
		local hbpos = self:WorldSpaceCenter()
		local tr = self:GetTrace(hbpos, -500)

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
	local OwnPlayer, SizeX = LocalPlayer(), 160
	local LookingAt = OwnPlayer:GetEyeTrace().Entity

	if not IsValid(LookingAt) then return end
	if LookingAt:GetClass() ~= "offset_hoverball" then return end
	if (LookingAt:GetPos():DistToSqr(OwnPlayer:GetShootPos()) > 90000) then return end

	local TipNW = LookingAt:GetNWString("OHB-BetterTip")
	if not TipNW or TipNW == "" then return end
	local HBData, TextX, TextY = TipNW:Split(","), 0, 0

	surface.SetFont("OHBTipFontSmall")

	for oi = 1, #HBData do
		local dat = HBData[oi]
		if surface.GetTextSize(dat) > TextX then
			TextX, TextY = surface.GetTextSize(dat)
		end
	end

	SizeX = SizeX + TextX

	-- Overlay first argument is present
	if HBData[1] ~= "" then
		local SizeY = (TableOHBInf.Size * (select(2,surface.GetTextSize(HBData[2])) + 2))
		BoxOffsetY = ScrH() / 2 - 80,

		LookingAt:DrawInfoBox(BoxOffsetX, BoxOffsetY-10, SizeX, SizeY+10)
		LookingAt:DrawInfoPointy(BoxOffsetX)
		LookingAt:DrawInfoTitle(HBData[1], BoxOffsetX, BoxOffsetY, SizeX, SizeY)
	else
		local SizeY = (TableOHBInf.Size * (select(2,surface.GetTextSize(HBData[1])) + 2))
		BoxOffsetY = ScrH() / 2 - 80

		LookingAt:DrawInfoBox(BoxOffsetX, BoxOffsetY, SizeX, SizeY)
		LookingAt:DrawInfoPointy(BoxOffsetX, BoxOffsetY)
	end

	for di = 1, TableOHBInf.Size do
		local inf = TableOHBInf[di]
		local hbx = BoxOffsetX + 10
		local hvx = BoxOffsetX + (SizeX - 10)
		local hby = BoxOffsetY + 40 + ((di - 1) * 20)
		draw.SimpleText(inf[2], "OHBTipFontSmall", hbx, hby, CoOHBName, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText(HBData[inf[1]], "OHBTipFontSmall", hvx, hby, CoOHBValue, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

end)

function ENT:Draw()
	self:DrawModel() -- Draws Model Client Side
	if ShouldRenderLasers:GetBool() or ShouldAlwaysRenderLasers:GetBool() then self:DrawLaser() end
end
