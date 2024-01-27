print("^2Jim^7-^2Payments ^7v^4"..GetResourceMetadata(GetCurrentResourceName(), 'version', nil):gsub("%.", "^7.^4").."^7 - ^2Payments Script by ^1Jimathy^7")

-- If you need support I now have a discord available, it helps me keep track of issues and give better support.

-- https://discord.gg/xKgQZ6wZvS

Config = {
	Lan = "en",
	System = {
		Debug = true,

		Menu = "qb",  			-- "qb", "ox", "gta"
		Notify = "gta",			-- "qb", "ox", "gta", "esx"
		ProgressBar = "gta", 	-- "qb", "ox", "gta", "esx"
	},

	General = {
		Banking = "qb-banking",
								-- "qb-management" 	-- This is for the older version of QBCore
								-- "qb-banking" 	-- This is for the latest QBCore updates
								-- "renewed"
								-- "fd" 			-- currently default supported
								-- "okok"			-- make sure to add societies to Config.Societies in okokBanking, This is for the latest QBCore updates

		ApGov = false, 			-- Toggle support for AP-Goverment Tax

		List = true, 			-- "true" to use nearby player list feature in the cash registers, "false" for manual id entry
		PaymentRadius = 15, 	-- This is how far the playerlist will check for nearby players (based on the person charging)

		Usebzzz = false, 		-- enable if you're using the prop from bzzz

		Enablecommand = true, 	-- Enables the /cashregister command

		PhoneBank = false, 		-- Set this to false to use the popup payment system FOR CARD/BANK PAYMENTS instead of using phone invoices
								-- This doesn't affect Cash payments as they by default use a confirmation window
								-- This is helpful for phones that don't support invoices well

		Peds = true, 			-- "true" to enable peds spawning in banks
		PedPool = { 			-- If Peds is true, use this pool of ped models to pick from
			"IG_Bankman",
			"U_M_M_BankMan",
			"S_F_M_Shop_HIGH",
			"S_M_M_HighSec_02",
			"S_M_M_HighSec_03",
			"S_M_M_HighSec_04",
			"A_F_Y_Business_01",
			"A_F_Y_Business_02",
			"A_F_Y_Business_03",
			"A_F_Y_Business_04",
			"A_M_M_Business_01",
			"A_M_Y_Business_02",
			"A_M_Y_Business_03",
			"U_F_M_CasinoShop_01",
		},

		PhoneType = "qb", 		-- Change this setting to make invoices work with your phone script [still testing this currently]
								-- "qb" for qb-phone
								-- "gks" for GKSPhone

		useBanks = false, -- Enable this to use my banking stuff

		BankBlips = false, -- Enable this if you disabled qb-banking and need bank locations

		Gabz = true, 	-- "true" to enable Gabz Bank locations
						-- this corrects the ATM/Bank Cashier + Ticket Cash in locations

		menuLogo = "https://static.wikia.nocookie.net/gtawiki/images/b/bd/Fleeca-GTAV-Logo.png",

	},

	ATMs = {
		enable = true,
		showBlips = true,

		ATMModels = { `prop_atm_01`, `prop_atm_02`, `prop_atm_03`, `prop_fleeca_atm`, `gabz_sm_pb_atmframe` },

	},

	Banks = {
		enable = true,
		showBlips = true,

	},

	CustomCashRegisters = {
		--	["jobname"] = { -- Player job role restriction
		--		{ coords = vector4(0, 0, 0, 0), }, -- vector4 to place the till and the way it faces
		--		{ coords = vector4(0, 0, 0, 0), prop = true, }, -- "prop = true" spawns a prop at the coords
		--	},
	},

	Receipts = {
		TicketSystem = true, 		-- Enable this if you want to use the ticket system false
		TicketSystemAll = true, 	-- Enable this to give tickets to all workers clocked in

		Commission = true, 			-- Set this to true to enable Commissions and give the person charging a percentage of the total
		CommissionAll = false, 		-- Set this to true to give commission to workers clocked in
		CommissionDouble = false, 	-- Set this to true if you want the person charging to get double Commission
		CommissionLimit = false,	-- If true, this limits the Commission to only be given if over the "MinAmountForTicket".
									-- If false, Commission will be given for any amount

		CashInLocations = {
			vec4(252.23, 223.11, 106.29, 159.2), -- Default Third Window along in Pacific Bank
		},

		CashInAnywhere = true,

		-- MinAmountforTicket should be your cheapest item
		-- PayPerTicket should never be higher than MinAmountforTicket
		-- Commission is a percentage eg "0.10" becomes 10%
		Jobs = {
			-- Jim Businesses | https://jimathy666.tebex.io/
			['bakery'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
			['beanmachine'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
			['burgershot'] = { MinAmountforTicket = 50, PayPerTicket = 50 , Commission = 0.10, },
			['catcafe'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
			['henhouse'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
			['pizzathis'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
			['popsdiner'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
			['tequilala'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
			['vanilla'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
			['upnatom'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
			['hornys'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },

			-- JixelTay Businesses | https://jixeltay.tebex.io/
			['cigarbar'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
			['cluckinbell'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
			['smokeshop'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
			['pearls'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
			['kois'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
			['whitewidow'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },
			['bestbuds'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, },

			-- Jim Mechanic | https://jimathy666.tebex.io/
			['mechanic'] = { MinAmountforTicket = 1000, PayPerTicket = 500, Commission = 0.10, },
			['tuners'] = { MinAmountforTicket = 1000, PayPerTicket = 500, Commission = 0.10, },
			['ottos'] = { MinAmountforTicket = 1000, PayPerTicket = 500, Commission = 0.10, },
			['lscustoms'] = { MinAmountforTicket = 1000, PayPerTicket = 500, Commission = 0.10, },
			['bennys'] = { MinAmountforTicket = 1000, PayPerTicket = 500, Commission = 0.10, },

			-- Gangs | Example of a gang being supported
			['lostmc'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, gang = true, },
		},

	},
	PolCharge = {
		-- The /polcharge command requires specific jobs to be set
		-- No tickets for these, it's just commission (0.25 = 25%)
		FineJobs = {
			['police'] = { Commission = 0.25, },
			['ambulance'] = { Commission = 0.25, },
		},
		FineJobConfirmation = false, --"true" makes it so fines need confirmation, "false" skips this ands just removes the money
		FineJobList = true, -- "true" to use nearby player list feature in the cash registers, "false" for manual id entry
	},
}

PlayerGang, PlayerJob, onDuty = {}, {}, nil