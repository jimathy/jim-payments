# jim-payments
QBCore based payment system

If you think I did a good job here, consider donating as it keeps by lights on and my cat fat:
https://ko-fi.com/jixelpatterns
--------------

If you use a different phone/invoice system let me know and I will add support for it as best I can!

Enchanced QB-Input payment system from my other scripts now free on its own

![General](https://i.imgur.com/37d2mE3.jpeg) ![General](https://i.imgur.com/AIdXzxX.jpeg)
![General](https://i.imgur.com/RYADcI2.jpeg) ![General](https://i.imgur.com/ICbQyeQ.jpeg)

# Installation

To make use of this payment system in a job that wasn't created by me

All you need to do is pick the job, grab a vector4 and confirm if you need a prop or not

For example:
```lua
    CustomCashRegisters = { -- Located in the config.lua
      ["burgershot"] = { -- Player job role restriction
        { coords = vector4(-1185.5, -878.54, 13.91, 305.53), prop = true, }, -- vector4 to place the till and the way it faces
        { coords = vector4(-1184.34, -880.51, 13.93, 302.04), prop = true, }, -- "prop = true" spawns a prop at the coords
      },
    },
```

This does not need to be done for **MY** job scripts, they already have built in support

--------------

To make use of the ticket reward system for workers you need to add the ticket item to your shared items lua:
```lua
["payticket"] 					 = {["name"] = "payticket", 				["label"] = "Receipt", 	     			["weight"] = 150, 		["type"] = "item", 		["image"] = "ticket.png", 				["unique"] = false,   	["useable"] = false,    ["shouldClose"] = false,    ["combinable"] = nil,   ["description"] = "Cash these in at the bank!"},	
```

Add the ticket image to your inventory script

[qb] > qb-inventory > html > images

--------------
To get tickets from phone invoices you NEED to add it to the event when a payment is accepted:

For QB-Phone:
Go to [qb] > qb-phone > client > main.lua
- Around line 645 there should be the PayInvoice NUICallBack
- Directly *above* this line:
```lua
TriggerServerEvent('qb-phone:server:BillingEmail', data, true)
```

- Add this line:
```lua
TriggerServerEvent('jim-payments:Tickets:Give', data)
```

For GKSPhone:
Go to gks-phone > server > serverapi.lua

- Search for the event: ```gksphone:faturapayBill```
- Under this line:
```lua
  Ply.Functions.RemoveMoney('bank', amount, "paid-invoice")
```

- Add these lines:
```lua
TriggerEvent('jim-payments:Tickets:Give', { sender = Ply.PlayerData.charinfo.firstname, senderCitizenId = data[1].sendercitizenid, society = data[1].society, amount = data[1].amount })
```

--------------

The latest banking systems are very simple to use and add,
simply look in the atms.lua and change the config options at the top

Choose wether to use atm's, choose wether to use banking locations
Choose wether to add bank blips (if you want to disable qb-banking)
Choose wether to add ATM blips (if you like $ signs)

--------------

New Commission system added

This brings more config options to find tune the script

Choose wether people get commission from every sale
Choose if EVERY worker gets Commission that is on duty
Choose if Commission is limited by MinAmountForTicket
Choose if the worker charging the customer gets double commission
