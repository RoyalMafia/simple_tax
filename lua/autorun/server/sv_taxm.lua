-- Net MSGs --
util.AddNetworkString("tax_info")
util.AddNetworkString("tax_request")
util.AddNetworkString("tax_notification")

local taxAmount = taxConfig.perct
local taxDelay = taxConfig.delay
local minAmount = taxConfig.min

-- Don't touch any of this stuff :)
local curTime   = CurTime()
local economy 	= {}
economy.ply 	= {}
economy.money 	= {}
economy.total   = {}
economy.prct    = {}
economy.canTax  = {}

function UpdateTable()
	TempTotal = 0
	table.Empty(economy.ply)
	table.Empty(economy.money)
	table.Empty(economy.total)
	table.Empty(economy.prct)
	table.Empty(economy.canTax)

	for x = 1, #player.GetAll() do
		ply = player.GetAll()[x]
		table.insert( economy.ply, ply )
		table.insert( economy.money, ply.DarkRPVars.money )

		if economy.money[x] > minAmount then
			table.insert( economy.canTax, true)
		else
			table.insert( economy.canTax, false)
		end

		TempTotal = TempTotal + ply.DarkRPVars.money
	end
	table.insert( economy.total, TempTotal )

	for x = 1, #economy.ply do
		table.insert( economy.prct, economy.money[x] / economy.total[1] * 100)
	end
end

hook.Add("PlayerConnect", "UpdateOnConnect", function( name, ip )
	UpdateTable()
end)

net.Receive("tax_request", function(len, pl)
	for x = 1, #economy.ply do
		if economy.ply[x] == pl then
			net.Start("tax_info")
				net.WriteInt(economy.money[x], 32)
				net.WriteInt(economy.total[1], 32)
				net.WriteFloat(economy.prct[x])
				if #economy.ply >= 2 then 
					net.WriteInt( math.Round( ( ( (taxAmount + economy.prct[x]/10) /100) * economy.money[x])/30), 32)
					net.WriteFloat((taxAmount/30) + economy.prct[x]/10) 
				else
					net.WriteInt( math.Round( ( ( economy.money[x] / taxAmount)/30)), 32)
					net.WriteFloat(taxAmount/30) 
				end
			net.Send(pl)
		end
	end
end)

function TaxPayDay()
	DeductAmount = 0
	TotalTax = 0
	CantTax = 0
	if CurTime() > curTime + taxDelay then
		for x = 1, #economy.ply do

			if #economy.ply >= 2 then DeductAmount = math.Round( ( ( (taxAmount + economy.prct[x]/10) /100) * economy.money[x])/30 ) else DeductAmount = math.Round( ( ( economy.money[x] / taxAmount)/30)) end

			if economy.canTax[x] then
				economy.ply[x]:addMoney(-DeductAmount)
				
				net.Start("tax_notification")
					net.WriteString(DarkRP.formatMoney(DeductAmount).." has been taxed from your account")
				net.Send(economy.ply[x])
				TotalTax = TotalTax + DeductAmount
			else
				CantTax = CantTax + 1
			end
		end

		for x = 1, #economy.ply do
			if !economy.canTax[x] then
				AddAmount = math.Round( (TotalTax / (taxAmount/2)) / CantTax)
				economy.ply[x]:addMoney( math.Round(AddAmount) )

				net.Start("tax_notification")
					net.WriteString(DarkRP.formatMoney(math.Round(AddAmount)).." has been added to your account")
				net.Send(economy.ply[x])
			end
		end

		curTime = CurTime()
	end
end

hook.Add("Think", "Main Hook", function()
	TaxPayDay()
	UpdateTable()
end)