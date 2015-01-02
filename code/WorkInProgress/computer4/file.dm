
/*
	Files are datums that can be stored in digital storage devices
*/

/datum/file4
	var/name = "File"
	var/extension = "dat"
	var/volume = 10 // in KB
	var/image = 'icons/ntos/file.png' // determines the icon to use, found in icons/ntos
	var/obj/machinery/computer4/computer // the parent computer, if fixed
	var/holder	= null // location of the file (hdd, floppy, folder)
	var/root	// is the file in the drive's root, if yes, holder is a drive, else, holder is a folder
	var/obj/item/part/computer4/storage/drive	//reference TO the drive the file is on, different from holder if in a folder
	var/hidden_file = 0 // Prevents file from showing up on NTOS program list.
	var/drm	= 0			// Copy protection, called by copy() and move()
	var/readonly = 0	// Edit protection, called by edit(), which is just a failcheck proc

	proc/execute(var/datum/file/source)
		return

	//
	// Copy file to device.
	// If you overwrite this function, use the return value to make sure it succeeded
	//
	proc/copy(var/dest)
		if(!computer || computer.crit_fail) return null
		if((!istype(dest, /obj/item/part/computer4/storage))||(!istype(dest, /datum/file4/folder))) return 0//make sure w're actually copying TO a holder(folder/storage)
		if(drm)
			if(!computer.emagged)
				return null
		var/datum/file4/F = new type()
		if(!dest:addfile(F))
			return null // todo: arf here even though the player can't do a damn thing due to concurrency
		return F

	//
	// Move file to device
	// Returns null on failure even though the existing file doesn't go away
	//
	proc/move(var/dest, var/source)
		if(!computer || computer.crit_fail) return null
		if(drm)
			if(!computer.emagged)
				return null
		if((!istype(dest, /obj/item/part/computer4/storage))||(!istype(dest, /datum/file4/folder))) return 0
		if((!istype(source, /obj/item/part/computer4/storage))||(!istype(source, /datum/file4/folder))) return 0
		if(!dest:addfile(src))
			return null
		holder:removefile(src)
		return src

	//
	// Determines if the file is editable.  This does not use the DRM flag,
	// but instead the readonly flag.
	//

	proc/edit()
		if(!computer || computer.crit_fail)
			return 0
		if(readonly && !computer.emagged)
			return 0 //
		return 1

	//
	//gets the drive the file is located on, absolutely, and already places it in the drive var, but still returns a reference to the drive
	//use this anytime you're doing ANYTHING with KB if the file's in a folder, incase the drive's volume changes
	//takes note of floppies and actually sets drive to the floppy, if applicable
	//
	proc/get_drive()
		var/D = src.holder
		while(src && usr)
			if(istype(D, /obj/item/part/computer4/storage)) break//if true, we have the drive, stop the loop
			D = D:holder
		if(istype(D, /obj/item/part/computer4/storage/removable))//we have a floppy instead of a HDD, set it accordingly.
			drive = D:inserted
			return D:inserted
		else
			drive = D
			return D

	//
	//returns 1 if the src file has either drm, readonly, or both enabled, dependant on bitflags in setup.dm
	//

	proc/check_access_level(var/aclevel)
		if(!aclevel)
			return 1//well, every file has an empty access level, depends on your perspective I guess, not that this should matter but you never know when somebody fucks up code
		if(aclevel & READ_ONLY)
			if(src.readonly)
				return 1
		if(aclevel & DRM)
			if(src.drm)
				return 1
		else//okay, it can't be anything BUT both now
			if(src.drm && src.readonly)
				return 1
		return 0

	//
	//returns a list of all folders "above" this file, in the file directory
	//

	proc/list_holders()
		if(!istype(holder, /datum/file4/folder))
			return null//our holder is a storage device, if you want the storage device, use get_drive()
		var/list/holders = holder:list_holders()
		if(holders)//if our holder has any folder holders, return the holder's returned list + our holder, else, just return holder
			holders.Add(holder)
			return holders
		return holder

/*
	Centcom root authorization certificate

	Non-destructive, officially sanctioned.
	Has the same effect on computers as an emag.
*/
/datum/file4/centcom_auth
	name = "Centcom Root Access Token"
	extension = "auth"
	volume = 100
	copy()
		return null

/*
	A file that contains information
*/

/datum/file4/data

	var/content			= "content goes here"
	var/file_increment	= 1
	var/binary			= 0 // determines if the file can't be opened by editor

	// Set the content to a specific amount, increase filesize appropriately.
	proc/set_content(var/text)
		content = text
		if(file_increment > 1)
			volume = round(file_increment * length(text))

	copy(var/obj/O)
		var/datum/file/data/D = ..(O)
		if(D)
			D.content = content
			D.readonly = readonly

	New()
		if(content)
			if(file_increment > 1)
				volume = round(file_increment * length(content))

/*
	A generic file that contains text
*/

/datum/file4/data/text
	name = "Text File"
	extension = "txt"
	image = 'icons/ntos/file.png'
	content = ""
	file_increment = 0.002 // 0.002 kilobytes per character (1024 characters per KB)

/datum/file4/data/text/ClownProphecy
	name = "Clown Prophecy"
	content = "HONKhHONKeHONKlHONKpHONKHONmKHONKeHONKHONKpHONKlHONKeHONKaHONKsHONKe"


/*
	A file that contains research
*/

/datum/file4/data/research
	name = "Untitled Research"
	binary = 1
	content = "Untitled Tier X Research"
	var/datum/tech/stored // the actual tech contents
	volume = 1440

/*
	A file that contains genetic information
*/

/datum/file4/data/genome
	name = "Genetic Buffer"
	binary = 1
	var/real_name = "Poop"


/datum/file4/data/genome/SE
	name = "Structural Enzymes"
	var/mutantrace = null

/datum/file4/data/genome/UE
	name = "Unique Enzymes"

/*
the way genome computers now work, a subtype is the wrong way to do this;
it will no longer be picked up.  You can change this later if you need to.
for now put it on a disk

/datum/file4/data/genome/UE/GodEmperorOfMankind
	name = "G.E.M.K."
	content = "066000033000000000AF00330660FF4DB002690"
	label = "God Emperor of Mankind"
*/
/datum/file4/data/genome/UI
	name = "Unique Identifier"

/datum/file4/data/genome/UI/UE
	name = "Unique Identifier + Unique Enzymes"

/datum/file4/data/genome/cloning
	name = "Cloning Data"
	var/datum/data/record/record
