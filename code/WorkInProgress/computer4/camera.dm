/datum/file4/camnet_key
	name = "Security Camera Network Main Key"
	var/title = "Station"
	var/desc = "Connects to station security cameras."
	var/list/networks = list("SS13")
	var/screen = "cameras"

	execute(var/datum/file/source)
		if(istype(source,/datum/file4/program/security))
			var/datum/file/program/security/prog = source
			prog.key = src
			prog.camera_list = null
			return
		if(istype(source,/datum/file4/program/ntos))
			for(var/obj/item/part/computer4/storage/S in list(computer.hdd,computer.floppy))
				for(var/datum/file/F in S.files)
					if(istype(F,/datum/file4/program/security))
						var/datum/file/program/security/Sec = F
						Sec.key = src
						Sec.camera_list = null
						Sec.execute(source)
						return
		computer.Crash(MISSING_PROGRAM)

/datum/file4/camnet_key/telecomms
	name = "Telecomms Network Key"
	title = "telecommunications satellite"
	desc = "Connects to telecommunications satellite security cameras."
	networks = list("Telecomms")

/datum/file4/camnet_key/researchoutpost
	name = "Research Outpost Network Key"
	title = "research outpost"
	desc = "Connects to research outpost security cameras."
	networks = list("Research Outpost")

/datum/file4/camnet_key/miningoutpost
	name = "Mining Outpost Network Key"
	title = "mining outpost"
	desc = "Connects to mining outpost security cameras."
	networks = list("Mining Outpost")
	screen = "miningcameras"

/datum/file4/camnet_key/research
	name = "Research Network Key"
	title = "research"
	desc = "Connects to research security cameras."
	networks = list("Research")

/datum/file4/camnet_key/prison
	name = "Prison Network Key"
	title = "prison"
	desc = "Connects to prison security cameras."
	networks = list("Prison")

/datum/file4/camnet_key/interrogation
	name = "Interrogation Network Key"
	title = "interrogation"
	desc = "Connects to interrogation security cameras."
	networks = list("Interrogation")

/datum/file4/camnet_key/supermatter
	name = "Supermatter Network Key"
	title = "supermatter"
	desc = "Connects to supermatter security cameras."
	networks = list("Supermatter")

/datum/file4/camnet_key/singularity
	name = "Singularity Network Key"
	title = "singularity"
	desc = "Connects to singularity security cameras."
	networks = list("Singularity")

/datum/file4/camnet_key/anomalyisolation
	name = "Anomaly Isolation Network Key"
	title = "anomalyisolation"
	desc = "Connects to interrogation security cameras."
	networks = list("Anomaly Isolation")

/datum/file4/camnet_key/toxins
	name = "Toxins Network Key"
	title = "toxins"
	desc = "Connects to toxins security cameras."
	networks = list("Toxins")

/datum/file4/camnet_key/telepad
	name = "Telepad Network Key"
	title = "telepad"
	desc = "Connects to telepad security cameras."
	networks = list("Telepad")

/datum/file4/camnet_key/ert
	name = "Emergency Response Team Network Key"
	title = "emergency response team"
	desc = "Connects to emergency response team security cameras."
	networks = list("ERT")

/datum/file4/camnet_key/centcom
	name = "Central Command Network Key"
	title = "central command"
	desc = "Connects to central command security cameras."
	networks = list("CentCom")

/datum/file4/camnet_key/thunderdome
	name = "Thunderdome Network Key"
	title = "thunderdome"
	desc = "Connects to thunderdome security cameras."
	networks = list("Thunderdome")

/datum/file4/camnet_key/entertainment
	name = "Entertainment Network Key"
	title = "entertainment"
	desc = "Connects to entertainment security cameras."
	networks = list("news")


/*
	Computer part needed to connect to cameras
*/

/obj/item/part/computer4/networking/cameras
	name = "camera network access module"
	desc = "Connects a computer to the camera network."

	// I have no idea what the following does
	var/mapping = 0//For the overview file, interesting bit of code.

	//proc/camera_list(var/datum/file/camnet_key/key)
	get_machines(var/datum/file4/camnet_key/key)
		if (!computer || computer.z > 6)
			return null

		var/list/L = list()
		for(var/obj/machinery/camera/C in cameranet.viewpoints)
			var/list/temp = C.network & key.networks
			if(temp.len)
				L.Add(C)

		camera_sort(L)

		return L
	verify_machine(var/obj/machinery/camera/C,var/datum/file/camnet_key/key = null)
		if(!istype(C) || !C.can_use())
			return 0

		if(key)
			var/list/temp = C.network & key.networks
			if(!temp.len)
				return 0
		return 1