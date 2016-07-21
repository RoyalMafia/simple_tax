-- Vars -- 
local economy 		= {}
	economy.money 	= 0
	economy.total   = 0
	economy.prct    = 0
	economy.tax     = 0
menuOpen = false

hook.Add("Think", "GetInfo", function()
	if menuOpen then
		net.Start("tax_request")
		net.SendToServer()
	end
end)

net.Receive("tax_info", function(len, pl) 
	economy.money = net.ReadInt(32)
	economy.total = net.ReadInt(32)
	economy.prct  = net.ReadFloat()
	economy.tax   = net.ReadInt(32)
	taxAmount     = net.ReadFloat()
end)

surface.CreateFont( "F1", {font = "DermaLarge",size = 18,weight = 100,blursize = 0,scanlines = 0,})

function DrawTaxInfo()
	menuOpen = true
	cMoney = 0
	cPrct  = 0
	cTax   = 0
	local TaxMenu = vgui.Create( "DFrame" )
	TaxMenu:SetSize(500, 152)
	TaxMenu:Center()
	TaxMenu:MakePopup()
	TaxMenu:SetTitle( "" )
	TaxMenu:SetDraggable( false )
	TaxMenu:ShowCloseButton( false )

	function TaxMenu:Paint(w, h)

		--[[ Background & Header ]]--
		draw.RoundedBox( 8, 0, 0, w, h, Color(64,59,51,255))
		draw.RoundedBoxEx( 8, 0, 0, w, 25, Color(0,0,0,50), true, true, false, false)
		draw.RoundedBox( 0, 0, 25, w, 1, Color(255,255,255,10))
		draw.RoundedBox( 0, 0, 126, w, 1, Color(255,255,255,10))
		draw.RoundedBoxEx( 8, 0, 127, w, h, Color(0,0,0,50), false, false, true, true)
		draw.SimpleText( "Tax Info", "F1", w / 2, 12, Color(255,255,255,80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		--[[ Info Bars ]]--
		draw.RoundedBox( 0, 10, 37, w - 20, 35, Color(211,100,59, 100))
		draw.RoundedBox( 0, 10, 35, w - 20, 35, Color(211,100,59))

		draw.RoundedBox( 0, 10, 35, math.Clamp(economy.prct*4.80, 0, 480), 37, Color(0,0,0, 100))
		draw.SimpleText( "You make up for "..string.sub(tostring(economy.prct), 0, 4).."% of the Economy", "F1", w / 2, 52, Color(255,255,255,110), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		--[[ Tax Bar ]]--
		draw.RoundedBox( 0, 10, 82, w - 20, 35, Color(148,199,182, 100))
		draw.RoundedBox( 0, 10, 80, w - 20, 35, Color(148,199,182))

		if economy.money > 10000 then
			draw.RoundedBox( 0, 10, 80, math.Clamp(( (economy.tax*30) / economy.total * 100)*4.80, 0, 480), 37, Color(0,0,0, 100))
			draw.SimpleText( "You pay "..DarkRP.formatMoney(economy.tax).." ("..string.sub(tostring(taxAmount), 0, 4).."%) towards Tax", "F1", w / 2, 97, Color(255,255,255,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		else
			draw.SimpleText( "You don't have enough money to pay Tax", "F1", w / 2, 97, Color(255,255,255,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end


		--[[ Economy Balance ]]--
		cMoney = cMoney + math.Round(((economy.total) - cMoney)/30)
		draw.SimpleText( "Current Economy - "..DarkRP.formatMoney(cMoney), "F1", w / 2, 139, Color(255,255,255,80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	local CloseButton = vgui.Create( "DButton", TaxMenu)
	CloseButton:SetText( "" )
	CloseButton:SetPos( TaxMenu:GetWide() - 30, 4 )
	CloseButton:SetSize( 30, 16 )

	function CloseButton:Paint(w, h)
		draw.SimpleText( "X", "F1", w/2, h/2, Color(255,255,255,80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	function CloseButton:DoClick()
		menuOpen = false
		TaxMenu:Close()
	end
end

function DrawTaxNotification( string )
	local curTime = CurTime()
	local menuClose = false
	local xPos = ScrH() - 50

	local TaxN = vgui.Create( "DFrame" )
	TaxN:SetSize(320, 50)
	TaxN:SetPos( ScrW() / 2 - 160, xPos )
	TaxN:SetTitle( "" )
	TaxN:SetDraggable( false )
	TaxN:ShowCloseButton( false )

	function TaxN:Paint( w, h)
		draw.RoundedBoxEx( 8, 0, 0, w, h, Color(64,59,51,255), true, true, false, false)
		draw.RoundedBoxEx( 8, 0, 0, w, 25, Color(0,0,0,50), true, true, false, false)
		draw.RoundedBox( 0, 0, 25, w, 1, Color(255,255,255,10))
		draw.RoundedBox( 0, 0, 126, w, 1, Color(255,255,255,10))
		draw.RoundedBoxEx( 8, 0, 127, w, h, Color(0,0,0,50), false, false, true, true)
		draw.SimpleText( "Tax Notification", "F1", w / 2, 12, Color(255,255,255,80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

		draw.SimpleText( string, "F1", w / 2, 36, Color(255,255,255,80), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	function TaxN:Think()
		if menuClose then
			xPos = xPos + 1
			TaxN:SetPos( ScrW() / 2 - 160, xPos )
			if xPos >= ScrH() then
				TaxN:Close()
			end
		end

		if CurTime() >= curTime + 5 then
			menuClose = true
		end
	end
end

net.Receive("tax_notification", function(len, pl)
	DrawTaxNotification( net.ReadString() )
end)

hook.Add( "OnPlayerChat", "DrawTax", function( ply, strText, bTeam, bDead )

	strText = string.lower( strText )

	if strText == "!tax" and ply == LocalPlayer() then
		DrawTaxInfo()
		return true
	end

end)