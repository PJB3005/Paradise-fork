
/*
	Objects used to construct computers, and objects that can be inserted into them, etc.

	TODO:
	* Synthesizer part (toybox, injectors, etc)
*/



/obj/item/part/computer4
	name = "computer part"
	desc = "You are officially a wizard."
	gender = PLURAL
	icon = 'icons/obj/stock_parts.dmi'
	icon_state = "hdd1"
	w_class = 2.0

	var/emagged = 0
	crit_fail = 0

	// the computer that this device is attached to
	var/obj/machinery/computer4/computer

	// If the computer is attacked by an item it will reference this to decide which peripheral(s) are affected.
	var/list/attackby_types	= list()
	proc/allow_attackby(var/obj/item/I as obj,var/mob/user as mob)

		for(var/typekey in attackby_types)
			if(istype(I,typekey))
				return 1
		return 0

	proc/init(var/obj/machinery/computer/target)
		computer = target
		// continue to handle all other type-specific procedures

/*
	Below are all the miscellaneous components
	For storage drives, see storage.dm
	For networking parts, see networking.dm
*/

/obj/item/part/computer4/ai_holder
	name = "intelliCard computer module"
	desc = "Contains a specialized nacelle for dealing with highly sensitive equipment without interference."

	attackby_types = list(/obj/item/device/aicard)

	var/mob/living/silicon/ai/occupant	= null
	var/busy = 0

	// Ninja gloves check
	attack_hand(mob/user as mob)
		if(ishuman(user) && istype(user:gloves, /obj/item/clothing/gloves/space_ninja) && user:gloves:candrain && !user:gloves:draining)
			if(user:wear_suit:s_control)
				user:wear_suit.transfer_ai("AIFIXER","NINJASUIT",src,user)
			else
				user << "\red <b>ERROR</b>: \black Remote access channel disabled."
			return
		..()

	attackby(obj/I as obj,mob/user as mob)
		if(computer && !computer.stat)
			if(istype(I, /obj/item/device/aicard))
				I:transfer_ai("AIFIXER","AICARD",src,user)
				if(computer.program)
					computer.program.update_icon()
				computer.update_icon()
				computer.occupant = occupant
		..()
		return

/*
	ID computer cardslot - reading and writing slots
*/

/obj/item/part/computer4/cardslot
	name = "magnetic card slot"
	desc = "Contains a slot for reading magnetic swipe cards."

	var/obj/item/weapon/card/reader	= null
	var/obj/item/weapon/card/writer	= null	// so that you don't need to typecast dual cardslots, but pretend it's not here
											// alternately pretend they did it to save money on manufacturing somehow
	var/dualslot = 0 // faster than typechecking
	attackby_types = list(/obj/item/weapon/card)

	attackby(var/obj/item/I as obj, var/mob/user as mob)
		if(istype(I,/obj/item/weapon/card))
			insert(I)
			return
		..(I,user)

	// cardslot.insert(card, slot)
	// card: The card obj you want to insert (usually your ID)
	// slot: Which slot to insert into (1: reader, 2: writer, 3: auto), 3 default
	proc/insert(var/obj/item/weapon/card/card, var/slot = 3)
		if(!computer)
			return 0
		// This shouldn't happen, just in case..
		if(slot == 2 && !dualslot)
			usr << "This device has only one card slot"
			return 0

		if(istype(card,/obj/item/weapon/card/emag)) // emag reader slot
			if(!writer)
				usr << "You insert \the [card], and the computer grinds, sparks, and beeps.  After a moment, the card ejects itself."
				computer.emagged = 1
				return 1
			else
				usr << "You are unable to insert \the [card], as the reader slot is occupied"

		var/mob/living/L = usr
		switch(slot)
			if(1)
				if(equip_to_reader(card, L))
					usr << "You insert the card into reader slot"
				else
					usr << "There is already something in the reader slot."
			if(2)
				if(equip_to_writer(card, L))
					usr << "You insert the card into writer slot"
				else
					usr << "There is already something in the reader slot."
			if(3)
				if(equip_to_reader(card, L))
					usr << "You insert the card into reader slot"
				else if (equip_to_writer(card, L) && dualslot)
					usr << "You insert the card into writer slot"
				else if (dualslot)
					usr << "There is already something in both slots."
				else
					usr << "There is already something in the reader slot."


	// Usage of insert() preferred, as it also tells result to the user.
	proc/equip_to_reader(var/obj/item/weapon/card/card, var/mob/living/L)
		if(!reader)
			L.drop_item()
			card.loc = src
			reader = card
			return 1
		return 0

	proc/equip_to_writer(var/obj/item/weapon/card/card, var/mob/living/L)
		if(!writer && dualslot)
			L.drop_item()
			card.loc = src
			writer = card
			return 1
		return 0

	// cardslot.remove(slot)
	// slot: Which slot to remove card(s) from (1: reader only, 2: writer only, 3: both [works even with one card], 4: reader and if empty then writer ), 3 default
	proc/remove(var/slot = 3)
		var/mob/living/L = usr
		switch(slot)
			if(1)
				if (remove_reader(L))
					L << "You remove the card from reader slot"
				else
					L << "There is no card in the reader slot"
			if(2)
				if (remove_writer(L))
					L << "You remove the card from writer slot"
				else
					L << "There is no card in the writer slot"
			if(3)
				if (remove_reader(L))
					if (remove_writer(L))
						L << "You remove cards from both slots"
					else
						L << "You remove the card from reader slot"
				else
					if(remove_writer(L))
						L << "You remove the card from writer slot"
					else
						L << "There are no cards in both slots"
			if(4)
				if (!remove_reader(L))
					if (remove_writer(L))
						L << "You remove the card from writer slot"
					else if (!dualslot)
						L << "There is no card in the reader slot"
					else
						L << "There are no cards in both slots"
				else
					L << "You remove the card from reader slot"


	proc/remove_reader(var/mob/living/L)
		if(reader)
			reader.loc = loc
			if(istype(L) && !L.get_active_hand())
				L.put_in_hands(reader)
			else
				reader.loc = computer.loc
			reader = null
			return 1
		return 0

	proc/remove_writer(var/mob/living/L)
		if(writer && dualslot)
			writer.loc = loc
			if(istype(L) && !L.get_active_hand())
				L.put_in_hands(writer)
			else
				writer.loc = computer.loc
			writer = null
			return 1
		return 0




	// Authorizes the user based on the computer's requirements
	proc/authenticate()
		return computer.check_access(reader)

	proc/addfile(var/datum/file/F)
		if(!dualslot || !istype(writer,/obj/item/weapon/card/data))
			return 0
		var/obj/item/weapon/card/data/D = writer
		if(D.files.len > 3)
			return 0
		D.files += F
		return 1

/obj/item/part/computer4/cardslot/dual
	name	= "magnetic card reader"
	desc	= "Contains slots for inserting magnetic swipe cards for reading and writing."
	dualslot = 1

/obj/item/part/computer4/toybox
	var/list/prizes = list(	/obj/item/weapon/storage/box/snappops			= 2,
							/obj/item/toy/blink								= 2,
							/obj/item/clothing/under/syndicate/tacticool	= 2,
							/obj/item/toy/sword								= 2,
							/obj/item/toy/gun								= 2,
							/obj/item/toy/crossbow							= 2,
							/obj/item/clothing/suit/syndicatefake			= 2,
							/obj/item/weapon/storage/fancy/crayons			= 2,
							/obj/item/toy/spinningtoy						= 2,
							/obj/item/toy/prize/ripley						= 1,
							/obj/item/toy/prize/fireripley					= 1,
							/obj/item/toy/prize/deathripley					= 1,
							/obj/item/toy/prize/gygax						= 1,
							/obj/item/toy/prize/durand						= 1,
							/obj/item/toy/prize/honk						= 1,
							/obj/item/toy/prize/marauder					= 1,
							/obj/item/toy/prize/seraph						= 1,
							/obj/item/toy/prize/mauler						= 1,
							/obj/item/toy/prize/odysseus					= 1,
							/obj/item/toy/prize/phazon						= 1
							)
	proc/dispense()
		if(computer && !computer.stat)
			var/prizeselect = pickweight(prizes)
			new prizeselect(computer.loc)
			if(istype(prizeselect, /obj/item/toy/gun)) //Ammo comes with the gun
				new /obj/item/toy/ammo/gun(computer.loc)
			else if(istype(prizeselect, /obj/item/clothing/suit/syndicatefake)) //Helmet is part of the suit
				new	/obj/item/clothing/head/syndicatefake(computer.loc)
			feedback_inc("arcade_win_normal")
			computer.use_power(500)