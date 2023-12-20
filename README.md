# jim-payments
- QBCore based payment system
- Enchanced QB-Input payment system from my other scripts now free on its own

### If you need support I have a discord server available, it helps me keep track of issues and give better support.
## https://discord.gg/xKgQZ6wZvS

### We also have Documentation over on Gitbook, feel free to check it out
## https://jixelpatterns.gitbook.io/jixelpatterns-script-guide/overview/who-we-are

### If you think I did a good job here, consider donating as it keeps by lights on and my cat fat/floofy:
## https://ko-fi.com/jixelpatterns

---

- If you use a different phone/invoice system let me know and I will add support for it as best I can!
  - Currently supported are:
    - qb-phone
    - gks-phone
    - qs-smartphone - Leave the setting as "qb"

---
# Installation
---
- I always recommend starting my scripts AFTER `[qb]` not inside it as it can mess with any dependancies on server load
- I have a separate folder called `[jim]` (that is also in the resources folder) that starts WAY after everything else.
- This ensure's it has everything it requires before trying to load
- Example of my load order:
```CSS
# QBCore & Extra stuff
ensure qb-core
ensure [qb]
ensure [standalone]
ensure [voice]
ensure [defaultmaps]
ensure [vehicles]
#Extra Jim Stuff
ensure [jim]
```

--- 
## BZZ Terminal Instructions 
Free Package https://bzzz.tebex.io/package/5551076

Stream the prop and add the emote that is provided to rpemotes or dpemotes
```lua
	['terminal'] 			 = {['name'] = 'terminal', 				['label'] = 'Wireless Terminal', 				['weight'] = 5000, 		["type"] = "item", 		["image"] = 'terminal.png', 		['unique'] = true, 		['useable'] = true, 	["shouldClose"] = true,	   ["combinable"] = nil,   ['description'] = ''},
```

---
## Item installation
- To make use of the ticket reward system for workers you need to add the ticket item to your shared items lua
- Naviage to `[qb] > qb-core / shared / items.lua` and add this line
```lua
["payticket"] 					 = {["name"] = "payticket", 				["label"] = "Receipt", 	     			["weight"] = 150, 		["type"] = "item", 		["image"] = "ticket.png", 				["unique"] = false,   	["useable"] = false,    ["shouldClose"] = false,    ["combinable"] = nil,   ["description"] = "Cash these in at the bank!"},
```

- Add the ticket image to your inventory script:
- Naviage to `[qb] > qb-inventory > html > images` and add this line

![](https://github.com/jimathy/jim-payments/blob/main/images/ticket.png?raw=true)

---
## Phone Setup
- There are two modes in the script, one that uses the phone for invoices/bank charges
- The script supports many features like pay tickets, commission payments etc.
- If you want to use phone systems for these then you need to add the event for when a payment is accepted:
- REMINDER: IF using phone invoices, the money being added to the society accounts is handled `BY THE PHONE`, not by my script. If money isn't going to the account its the phone system or bossmenu script.

#### QB-Phone:
- Go to `[qb] > qb-phone > client > main.lua`
 - Search for the event `RegisterNUICallback('PayInvoice', function(data, cb)` and look for the line:
```lua
TriggerServerEvent('qb-phone:server:BillingEmail', data, true)
```

- Directly *above* this line add:
```lua
TriggerServerEvent('jim-payments:Tickets:Give', data)
```
- The phone should now be integrated with jim-payments

#### GKS-Phone:
- Go to `gks-phone > server > serverapi.lua`
- Search for the event: `gksphone:faturapayBill` and search for this line:
```lua
  Ply.Functions.RemoveMoney('bank', data[1].amount, "paid-invoice")
```

- Directly under this line add this event:
```lua
TriggerEvent('jim-payments:Tickets:Give', { sender = Ply.PlayerData.charinfo.firstname, senderCitizenId = data[1].sendercitizenid, society = data[1].society, amount = data[1].amount })
```
- The phone should now be integrated with jim-payments

#### Renewed QB-Phone:
- Go to `qb-phone > server > invoices.lua`
- Search for the event: `qb-phone:server:PayMyInvoice` and search for this line:
```lua
TriggerEvent("qb-phone:server:InvoiceHandler", true, amount, src, resource)
```

- Directly under this line add this event:
```lua
TriggerEvent('jim-payments:Tickets:Give', { amount = amount, senderCitizenId = sendercitizenid, sender = SenderPly.PlayerData.charinfo.firstname, society = society }, SenderPly)
```
- When invoices are paid, they should now be integrated with jim-payments

# Setup/Config

## Custom Locations

- You can make of this payment system for a job script that wasn't created by me
- All you need to do is add the job, grab a `vector4` (vector3 + heading) and set if you need a to spawn prop or not
- For example:
```lua
CustomCashRegisters = { -- Located in the config.lua
  ["burgershot"] = { -- Player job role restriction
    { coords = vector4(-1185.5, -878.54, 13.91, 305.53), prop = true, }, -- vector4 to place the till and the way it faces
    { coords = vector4(-1184.34, -880.51, 13.93, 302.04), prop = true, }, -- "prop = true" spawns a prop at the coords
  },
},
```
### This does not need to be done for MY job scripts, they already have built in support
---
## PayTickets
![](https://i.imgur.com/ICbQyeQ.jpeg)
- This script has a built in ticket reward system
- On successful sale, the employees will be handed a ticket if they are clocked in
  - This can then be handed in to the bank to receive payment
  - Works as a reward and incentive for turning up to do work
  - The values are set per job in `Config.Jobs`
- `TicketSystem` Enable this if you want to use the ticket system false
- `TicketSystemAll` Enable this to give tickets to all workers clocked in
---
## Commission System
- Support for commission to be paid as a reward for each successful payment
- Very customisable with the config.lua
  - `Commission` Choose wether people get commission from every sale
  - `CommissionAll` Choose if **EVERY** worker gets Commission that is on duty
  - `CommissionDouble` Choose if Commission is limited by `MinAmountForTicket`
  - `CommissionLimit` Choose if the worker charging the customer gets double commission

---
## Multiple Job and Gang Role support
- The script supports adding job roles to the config so they can get rewards for successful payments
- This includes Gang roles for stores/bars owned by a gang allowing them to get ticket rewards and commission
- Examples of adding jobs / gangs to config.lua:
```lua
Jobs = {
	['mechanic'] = { MinAmountforTicket = 1000, PayPerTicket = 500, Commission = 0.10, },
	['lostmc'] = { MinAmountforTicket = 50, PayPerTicket = 50, Commission = 0.10, gang = true, },
},
```
- `MinAmountforTicket` is the amount required in a charge before they can get a ticket
- `PayPerTicket` is the amount paid per ticket at the bank for the job role
  - I personally recommend this being lower than `MinAmountforTicket`, being too high makes it exploitable
- `Commission` is the amount of commission given to players on successful payments (0.10 = 10%)
- `gang = true` add this if the added role is a gang role
---
## /cashgive
![](https://i.imgur.com/AIdXzxX.jpeg)
- Alternative to /givecash
- A simple command built in to send cash to a `nearby player`
- Shows a list of names and id's of people nearby to select from rather
- Better experience than trying to figure out their ID and entering it manually
---
## /cashregister
![](https://i.imgur.com/37d2mE3.jpeg)
- This command is mean't as a portable cash register alternative
- For example:
  - When a person is devliering food they can do `/cashregister` and the payment will still be sent to the society account
- Doesn't utilize the ticket reward system unfortunately
---
## /polcharge
- This script supports a customisable "police billing"
- This is the ability for selected jobroles to charge a nearby player
- Depending on how you've set it up, this can take money directly from the players bank to the job's society account
- This is by default enabled for `police` and `ambulance`
- This also supports giving the player a cut of the payment as `commission`
  - Default Config:
```lua
FineJobs = {
  ['police'] = { Commission = 0.25, },
  ['ambulance'] = { Commission = 0.25, },
},
FineJobConfirmation = false, -- "true" makes it so fines need confirmation, "false" skips this ands just removes the money
FineJobList = true, -- "true" to use nearby player list feature in the cash registers, "false" for manual id entry
```
---
## Banking
![](https://i.imgur.com/RYADcI2.jpeg)
- This script has simple banking systems built in
  - Works as a basic replacement for qb-banking and qb-atms
- Adjust the options in config.lua:
  - `useATM` Choose wether to make atm's usable
  - `useBanks` Choose wether to make bank desks/teller's usable
  - `BankBlips` Enable this if you disabled qb-banking and need bank locations
  - `ATMBlips` Enable this if you are a pyscho and need every ATM to be on the map too
  - `Gabz` Enable to change to Gabz Bank locations, this corrects the ATM/Bank Cashier + Ticket Cash in
---
## Support for other scripts
### Renewed-Banking
  - Support for renewed banking added
  - Toggle `RenewedBanking` in the config.lua to enable this

### Renewed's qb-phone
  - Simply leave the Config.PhoneType as `"qb"`

### AP-Goverment
- Support for AP-Goverment Tax on payments
- Toggle `ApGov` in the config.lua to enable this