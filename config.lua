print("Jim-Payments v2.3 - Payments Script by Jimathy")

-- If you need support I now have a discord available, it helps me keep track of issues and give better support.

-- https://discord.gg/xKgQZ6wZvS

Config = {}

Config.Debug = false

Config.Manage = true -- "true" if using qb-management
					 -- "false" if using qb-bossmenu
					
Config.TicketSystem = true -- Enable this if you want to use the ticket system false

Config.List = true -- "true" to use nearby player list feature in the cash registers, "false" for manual id entry
Config.PaymentRadius = 30 -- This is how far the playerlist will check for nearby players (based on the person charging)

Config.useATM = true -- Enable this to use my ATM's
Config.useBanks = true -- Enable this to use my banking stuff
Config.BankBlips = true -- Enable this if you disabled qb-banking and need bank locations
Config.ATMBlips = false -- Enable this if you are a pyscho and need every ATM to be on the map too

Config.PhoneBank = true -- Set this to false to use the popup payment system FOR CARD/BANK PAYMENTS instead of using phone invoices
						-- This doesn't affect Cash payments as they by default use confirmation now
						-- This is helpful for phones that don't support invoices well

Config.Commission = false -- Set this to true to enable Commissions and give the person charging a percentage of the total
Config.CommissionAll = false -- Set this to true to give commission to workers clocked in
Config.CommissionDouble = false -- Set this to true if you want the person charging to get double Commission
Config.CommissionLimit = false -- If true, this limits the Commission to only be given if over the "MinAmountForTicket". If false, Commission will be given for any amount

-- MinAmountforTicket should be your cheapest item
-- PayPerTicket should never be higher than MinAmountforTicket
-- Commission is a percentage eg "0.10" becomes 10%

Config.CashInLocation = vector3(251.75, 222.17, 106.2) -- Default Third Window along in Pacific Bank
--Config.CashInLocation = vector3(269.28, 217.24, 106.28) -- Default Third Window along in Pacific Bank (Gabz)

Config.Jobs = {
	['beanmachine'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
	['burgershot'] = { MinAmountforTicket = 50, PayPerTicket = 50 , Commission = 0.10,},
	['catcafe'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
	['henhouse'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
	['pizzathis'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
	['popsdiner'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
	['tequilala'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
	['vanilla'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
	['mechanic'] = { MinAmountforTicket = 1000, PayPerTicket = 500, Commission = 0.10, },
}
