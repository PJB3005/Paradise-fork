/*
FOLDERS:
folder do exactly what you'd expect, but not how you'd expect
A file in a folder isn't on the drive, it's in a folder, with the folder adjusting size accordingly

*/

/datum/file4/folder
	name = "Unnamed folder"
	extension = "fol"
	volume = 1//1 for balancing, know it isn't realistic
	var/list/files = list()

//
//checks if adding V amount of volume to the drive will work
//folder's addfile calls this, but doesn't bother if it's a forced write, just remember to have other procs inherit the force, in that case
//if returnKB is true, return the amount of Kbytes that were over the limit, instead of a simple 1/0
//
/datum/file4/folder/proc/write_possible(var/V, var/returnKB = 0)
	var/obj/item/part/computer4/storage/D = get_drive()
	var/total = D.volume + V
	if(D.max_volume < total)
		if(returnKB)
			return (total - D.max_volume)
		return 0
	return 1

//updates the holder(hdd, disk, folder)'s volume, if the holder is a folder, do the same for the holder's holder, and so on
//not simply using the drive var so all folder in between are updated correctly

/datum/file4/folder/proc/update_volume(var/forced = 0)
	volume = 1//empty folder
	for(var/datum/file4/F in files)
		volume += F.volume
	if(holder:update_volume(forced))//this updating's gonna stop on a storage obj eventually; storage objs have different procs
		return 1


//adds files, name exactly like storage devices to make code easier

/datum/file4/folder/proc/addfile(var/datum/file4/F, var/forced = 0)
	if(!F || (F in files))
		return 1
	if(readonly && !forced)
		return 0
	for(var/datum/file4/N in files)
		if((N.name == F.name) && (N.extension == F.extension))//somebody's trying to add files with the same name and extension, no.
			return 0
	if(!write_possible(F.volume))//make SURE it's possible, except if forced
		if(!forced)
			return 0
		drive.volume += write_possible(F.volume, 1)//using write_possible's returnKB function, we get the exact amount overdoing it

	files.Add(F)
	volume += F.volume
	update_volume(forced)//yes, I could make it less "hard", but files aren't gonna be added and removed enough for me to bother
	F.computer = computer
	F.holder = src
	F.root = 0
	return 1


//removes files
/datum/file4/folder/proc/removefile(var/datum/file4/F, var/forced = 0)
	if(!F || (F in files))
		return 1
	if(readonly && !forced)
		return 0

	if(istype(F, /datum/file4/folder) && F.holder == src)//if the holder isn't the src, the folder was in the process of moval, don't delete sub-files in that case
		if(F:delete_sub_files(forced)) // only thing actually deleting here is BYOND's garbage collection, but that's not gonna work for folders, as files in a folder are gonna reference to the folder and back, calling this here so nothing's gonna get deleted if there's a read only for example
			return 0//we can't delete all files sub src folder, or something went horribly wrong, cancel the delete, if the latter, something might still be salvageable
	files -= F
	volume -= F.volume
	update_volume(forced)
	if(F.holder == src)
		F.holder = null
		F.computer = null
	return 1//yes, deleting the src folder should have removed the sub-files and sub-folders from the drive, so the operation succeeded, for the computer, only doing 1 here to prevent errors, keep in mind though that if delete_sub_folder failed there's gonna be a slight memory leak on the dream daemon server, as the datums are gonna live along somewhere useless

//
//deletes all files and sub-files and folders of folders(until it's all gone!) of the folder, use this to allow BYOND's garbage collection to correctly take care of deleting folders, so there's no memory leak
//returns 1 if all files and folders *SHOULD* have been deleted, even though the return value isn't currently used in removefile()
//

/datum/file4/folder/proc/delete_sub_files(var/forced = 0)
	//first we'll check if every file sub src is NOT readonly
	if(!forced && !check_not_sub_access_level(READ_ONLY))
		return 0//a file is readonly, not forced, abort
	for(var/F in files)
		if(!removefile(F, forced))//remove the files, they should be accesible, folders are handled by their override
			return 0// something went wrong whilst deleting the files, abort





//
//gets access level of all files and folders sub the src folder, returns 0 if the access level set in the params is present on any of the files sub src
//used in delet_sub_files, can't delete if we don't know if we're able to delete!(well, actually, you can, but let's not get into how computers work IRL, shall we?)
//

/datum/file4/folder/proc/check_not_sub_access_level(var/aclevel)
	for(var/datum/file4/F in files)
		if(F.check_access_level(aclevel))//regular files first, incase a folder ITSELF is readonly
			return 1
		if(istype(F, /datum/file4/folder))//we got a folder, call check_not_sub_access_level() on it
			if(F:check_not_sub_access_level(aclevel))
				return 1


/datum/file4/folder/copy(var/dest)
	if(!computer || computer.crit_fail) return null
	if(!istype(dest, /obj/item/part/computer4/storage)||!istype(dest, /datum/file4/folder)) return 0//make sure w're actually copying TO a holder(folder/storage)
	if(drm && !computer.emagged)
		return null

	var/datum/file4/folder/F = new type()
	if(!dest:addfile(F))
		return null
	for(var/datum/file4/C in files)//copy sub-files, if the user doesn't want this, why isn't he just making a second folder from scratch?
		if(C.copy(F))
			continue//I guess I can slap an error in here at some point, maybe confirmation from the user? at this point we can't stop anymore, and it'd just be tedious anyways, windows doesn't completely stop a copy operation because there's only 1 file that's uncompy-able, it asks you what to do
	return F

/datum/file4/folder/move(var/dest, var/source)
	if(!computer || computer.crit_fail) return null
	if(src in list_holders())//make sure we're not moving a folder into itself, it would be pretty bad, and probably start an infinite loop and shit
		return 0
	..()