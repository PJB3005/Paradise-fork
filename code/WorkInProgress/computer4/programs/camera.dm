/datum/file4/program/security
	name			= "camera monitor"
	desc			= "Connets to the Nanotrasen Camera Network"
	image			= 'icons/ntos/camera.png'
	active_state	= "camera-static"

	var/datum/file4/camnet_key/key = null
	var/last_pic = 1.0
	var/last_camera_refresh = 0
	var/camera_list = null

	var/obj/machinery/camera/current = null

	execute(var/datum/file4/program/caller)
		..(caller)
		if(computer && !key)
			var/list/fkeys = computer.list_files(/datum/file4/camnet_key)
			if(fkeys && fkeys.len)
				key = fkeys[1]
			update_icon()
			computer.update_icon()
			for(var/mob/living/L in viewers(1))
				if(!istype(L,/mob/living/silicon/ai) && L.machine == src)
					L.reset_view(null)


	Reset()
		..()
		current = null
		for(var/mob/living/L in viewers(1))
			if(!istype(L,/mob/living/silicon/ai) && L.machine == src)
				L.reset_view(null)

	interact()
		if(!interactable())
			return

		if(!computer.camnet)
			computer.Crash(MISSING_PERIPHERAL)
			return

		if(!key)
			var/list/fkeys = computer.list_files(/datum/file4/camnet_key)
			if(fkeys && fkeys.len)
				key = fkeys[1]
			update_icon()
			computer.update_icon()
			if(!key)
				return

		if(computer.camnet.verify_machine(current))
			usr.reset_view(current)

		if(world.time - last_camera_refresh > 50 || !camera_list)
			last_camera_refresh = world.time

			var/list/temp_list = computer.camnet.get_machines(key)

			camera_list = "Network Key: [key.title] [topic_link(src,"keyselect","\[ Select key \]")]<hr>"
			for(var/obj/machinery/camera/C in temp_list)
				if(C.status)
					camera_list += "[C.c_tag] - [topic_link(src,"show=\ref[C]","Show")]<br>"
				else
					camera_list += "[C.c_tag] - <b>DEACTIVATED</b><br>"
			//camera_list += "<br>" + topic_link(src,"close","Close")

		popup.set_content(camera_list)
		popup.open()


	update_icon()
		if(key)
			overlay.icon_state = key.screen
			name = key.title + " Camera Monitor"
		else
			overlay.icon_state = "camera-static"
			name = initial(name)



	Topic(var/href,var/list/href_list)
		if(!interactable() || !computer.camnet || ..(href,href_list))
			return

		if("show" in href_list)
			var/obj/machinery/camera/C = locate(href_list["show"])
			if(istype(C) && C.status)
				current = C
				usr.reset_view(C)
				interact()
				return

		if("keyselect" in href_list)
			current = null
			usr.reset_view(null)
			key = input(usr,"Select a camera network key:", "Key Select", null) as null|anything in computer.list_files(/datum/file4/camnet_key)
			camera_list = null
			update_icon()
			computer.update_icon()
			if(key)
				interact()
			else
				usr << "The screen turns to static."
			return