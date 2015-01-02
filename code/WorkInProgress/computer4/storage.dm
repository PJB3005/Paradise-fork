/*
	Computer devices that can store programs, files, etc.
*/

/obj/item/part/computer4/storage
	name			= "Storage Device"
	desc			= "A device used for storing and retrieving digital information."

	// storage capacity, kb
	var/volume		= 0
	var/max_volume	= 64		// should be enough for anyone

	var/driveletter	= null		// drive letter according to the computer

	var/list/files	= list()	// a list of files in the memory (ALL files)
	var/removeable	= 0			// determinse if the storage device is a removable hard drive (ie floppy)


	var/writeprotect = 0		// determines if the drive forbids writing.
								// note that write-protect is hardware and does not respect emagging.

	var/list/spawnfiles = list()// For mappers, special drives, and data disks

	New()
		..()
		if(islist(spawnfiles))
			if(removeable && spawnfiles.len)
				var/obj/item/part/computer/storage/removable/R = src
				R.inserted = new(src)
				if(writeprotect)
					R.inserted.writeprotect = 1
			for(var/typekey in spawnfiles)
				addfile(new typekey(),1)

	// Add a file to the hard drive, returns 0 if failed
	// forced is used when spawning files on a write-protect drive
	proc/addfile(var/datum/file4/F,var/forced = 0)
		if(!F || crit_fail || (F in files))
			return 1
		if(writeprotect && !forced)
			return 0
		for(var/datum/file4/N in files)
			if((N.name == F.name) && (N.extension == F.extension))//somebody's trying to add files with the same name and extension, no.
				return 0
		if(istype(F, /datum/file4/folder) && F.holder == src)//if the holder isn't the src, the folder was in the process of moval, don't delete sub-files in that case
			if(F:delete_sub_files(forced)) // only thing actually deleting here is BYOND's garbage collection, but that's not gonna work for folders, as files in a folder are gonna reference to the folder and back, calling this here so nothing's gonna get deleted if there's a read only for example
				return 0//we can't delete all files sub src folder, or something went horribly wrong, cancel the delete, if the latter, something might still be salvageable

		if(volume + F.volume > max_volume)
			if(!forced)
				return 0
			max_volume = volume + F.volume

		files.Add(F)
		volume += F.volume
		F.computer = computer
		F.holder = src
		F.root = 1
		return 1
	proc/removefile(var/datum/file4/F,var/forced = 0)
		if(!F || !(F in files))
			return 1
		if(writeprotect && !forced)
			return 0

		files -= F
		volume -= F.volume
		if(F.holder == src)
			F.holder = null
			F.computer = null
		return 1


	//
	//recalculates the drive's volume, by checking every file's volume and adding that together
	//if the drive's volume exceeds the max, and it's NOT forced, crash the computer, and wipe the storage device to prevent a proc crash in the future
	//if it is forced though, increase the storage device's size to accomodate
	//not that this proc should EVER be called with forced in a situation in which it matters
	//(seriously, don't let THIS proc of all things take care of drive size increases, it's here to for safety ONLY)
	//
	proc/update_volume(var/forced = 0)
		volume = 0	//empty the disk, this'll take care of possible fuckups on another coder's part too
		for(var/datum/file4/F in files)
			volume += F.volume
		if(volume > max_volume)//we have a problem, something fucked up somewhere down the line, and now I gotta fix it, yay
			if(!forced)
				testing("Computer [src.computer]'s drive [src] exceeded max volume in update_volume(), this should NOT be happening!")
				Wipe()//let's just assume the drive had a fatal error because of what just happened, and that's how NT brand storage devices react to this kind of stuff, alternatively I could add drive formatting later on and make it corrupt the drive, instead, that works too, probably
				computer.Crash(BUSTED_ASS_COMPUTER)//computer should've just crashed because of the OS getting wiped, if it wasn't on floppy, not that it's that big of a deal though
				return 0//Highly doubt this is still gonna matter since the computer reset since, not that this should happen in the first place though
			max_volume += (volume - max_volume)
			testing("Computer [src.computer]'s drive [src] exceeded max volume in update_volume(), drive size forced increased to [max_volume], this should NOT be happening!")
			return 1
		return 1

	//
	//Wipes the storage device, sets volume to 0, USES FORCED
	//DO NOT USE THIS PROC LIGHTLY, IMAGINE THIS AS THE DRIVE CORRUPTING
	//
	proc/Wipe()
		for(var/datum/file4/F in files)
			removefile(F, 1)
		volume = 0

	init(var/obj/machinery/computer/target)
		computer = target
		for(var/datum/file/F in files)
			F.computer = computer

/*
	Standard hard drives for computers. Used in computer construction
*/

/obj/item/part/computer4/storage/hdd
	name = "Hard Drive"
	max_volume = 25000
	icon_state = "hdd1"


/obj/item/part/computer4/storage/hdd/big
	name = "Big Hard Drive"
	max_volume = 50000
	icon_state = "hdd2"

/obj/item/part/computer4/storage/hdd/gigantic
	name = "Gigantic Hard Drive"
	max_volume = 75000
	icon_state = "hdd3"

/*
	Removeable hard drives for portable storage
*/

/obj/item/part/computer4/storage/removable
	name = "Disk Drive"
	max_volume = 3000
	removeable = 1

	attackby_types = list(/obj/item/weapon/disk/file4, /obj/item/weapon/pen)
	var/obj/item/weapon/disk/file4/inserted = null

	proc/eject_disk(var/forced = 0)
		if(!forced)
			return
		files = list()
		inserted.loc = computer.loc
		if(usr)
			if(!usr.get_active_hand())
				usr.put_in_active_hand(inserted)
			else if(forced && !usr.get_inactive_hand())
				usr.put_in_inactive_hand(inserted)
		for(var/datum/file/F in inserted.files)
			F.computer = null
		inserted = null


	attackby(obj/O as obj, mob/user as mob)
		if(inserted && istype(O,/obj/item/weapon/pen))
			usr << "You use [O] to carefully pry [inserted] out of [src]."
			eject_disk(forced = 1)
			return

		if(istype(O,/obj/item/weapon/disk/file4))
			if(inserted)
				usr << "There's already a disk in [src]!"
				return

			usr << "You insert [O] into [src]."
			usr.drop_item()
			O.loc = src
			inserted = O
			writeprotect = inserted.writeprotect

			files = inserted.files
			for(var/datum/file4/F in inserted.files)
				F.computer = computer

			return

		..()

	addfile(var/datum/file4/F)
		if(!F || !inserted)
			return 0

		if(F in inserted.files)
			return 1

		if(inserted.volume + F.volume > inserted.max_volume)
			return 0

		inserted.files.Add(F)
		F.computer = computer
		F.holder = inserted
		F.root = 1
		return 1

/*
	Removable hard drive presents...
	removeable disk!
*/

/obj/item/weapon/disk/file4
	//parent_type = /obj/item/part4/computer/storage // todon't: do this
	name = "Data Disk"
	desc = "A device that can be inserted and removed into computers easily as a form of portable data storage. This one stores 1 Megabyte"
	var/list/files
	var/list/spawn_files = list()
	var/writeprotect = 0
	var/volume = 0
	var/max_volume = 1028


	New()
		..()
		icon_state = "datadisk[rand(0,6)]"
		src.pixel_x = rand(-5, 5)
		src.pixel_y = rand(-5, 5)
		files = list()
		if(istype(spawn_files))
			for(var/typekey in spawn_files)
				var/datum/file/F = new typekey()
				F.device = src
				files += F
				volume += F.volume
