/*
	The Big Bad NT Operating System
*/

/datum/file4/program/ntos
	name = "Nanotrasen Operating System"
	extension = "prog"
	active_state = "ntos"
	var/current // the drive being viewed, null for desktop/computer
	var/fileop = "runfile"
	var/datum/file4/buffer//used fot example to copy files
	var/list/alertmsgs = list()//alert message displayed at the bottom of the window, list for proper trackkeeping incase there's multiple errors
/*
	Generate a basic list of files in the selected scope
*/

/datum/file4/program/ntos/proc/list_files()
	if(!computer || !current) return null
	return current:files


/datum/file4/program/ntos/proc/filegrid(var/list/filelist)
	var/dat = "<table border='0' align='left'>"
	var/i = 0
	for(var/datum/file4/F in filelist)
		if(!F.hidden_file)
			i++
			if(i==1)
				dat += "<tr>"
			if(i>= 6)
				i = 0
				dat += "</tr>"
				continue
			dat += {"
			<td>
				<center><a href='?src=\ref[src];[fileop]=\ref[F]'>
					<img src=\ref[F.image]><br>
					<span>[F.name]</span>
				</a></center>
			</td>"}

	dat += "</tr></table>"
	return dat

//
// I am separating this from filegrid so that I don't have to
// make metadata peripheral files
//
/datum/file4/program/ntos/proc/desktop(var/peripheralop = "viewperipheral")
	var/dat = "<table border='0' align='left'>"
	var/i = 0
	var/list/peripherals = list(computer.hdd,computer.floppy,computer.cardslot)
	for(var/obj/item/part/computer4/C in peripherals)
		if(!istype(C)) continue
		i++
		if(i==1)
			dat += "<tr>"
		if(i>= 6)
			i = 0
			dat += "</tr>"
			continue
		dat += {"
		<td>
			<a href='?src=\ref[src];[peripheralop]=\ref[C]'>
				\icon[C]<br>
				<span>[C.name]</span>
			</a>
		</td>"}

	dat += "</tr></table>"
	return dat


/datum/file4/program/ntos/proc/window(var/title,var/buttonbar,var/content)
	return {"
	<div class='filewin'>
		<div class='titlebar'>[title] <a href='?src=\ref[src];winclose'><img src=\ref['icons/ntos/tb_close.png']></a></div>
		<div class='buttonbar'>[buttonbar]</div>
		<div class='contentpane'>[content]</div>
	</div>"}

/datum/file4/program/ntos/proc/buttonbar()
	var/dat = ""
	if(fileop == "runfile")//no operation is in progress
		if(istype(current, /datum/file4/folder))
			dat += "<a href='?src=\ref[src];folderup'>UP</a> "
		dat += "<a href='?src=\ref[src];changefileop=copyfile'>Copy file</a> "
	//	dat += "<a href='?src=\ref[src];changefileop=cutfile'>Cut file</a> "
		dat += (buffer ? "<a href='?src=\ref[src];pastefile'>Paste file</a> " : "")
		dat += "<a href='?src=\ref[src];changefileop=renamefile'>rename</a> "
		dat += "<a href='?src=\ref[src];newfolder'>New folder</a> "
		dat += "<a href='?src=\ref[src];changefileop=delfile'>Delete file</a> "
	else
		dat += "Select file for "
		switch(fileop)
			if("delfile")
				dat += "deleting"
			if("cutfile")
				dat += "cutting"
			if("copyfile")
				dat += "copying"
			if("renamefile")
				dat += "renaming"

		dat += "  <a href='?src=\ref[src];changefileop=runfile'>\[CANCEL\]</a>"
	if(buffer)
		dat += "<br>File in buffer: [buffer.name].[buffer.extension] <a href='?src=\ref[src];emptybuffer'><span class='alert'>\[EMPTY BUFFER\]</span></a>"
	return dat


/datum/file4/program/ntos/interact()
	if(!interactable())
		return
	var/dat = {"
	<html>
	<head>
	<title>Nanotrasen Operating System</title>
	<style>
		div.filewin {
			position:absolute;
			left:80px;
			top:74px;
			width:480px;
			height:360px;
			border:2px inset black;
			background-color:#F0F0F0;
			overflow:auto
		}
		div.titlebar {
			position:fixed;
			left:80px;
			top:60px;
			width:480px;
			height:18px;
			padding:1px;
			padding-left:8px;
			border:none;
			background-color:#2020a0;
			color:#FFFFFF;
			z-index:5
		}
		.titlebar a {
			position:absolute;
			right:4px;
			display: block;
			width:16px;
			height:100%;
			background-color:#000000;
			color:#808080;
		}
		div.buttonbar {
			position:fixed;
			left:80px;
			top:78px;
			width:480px;
			height:36px;
			padding:2px;
			background-color:#f0d0d0;
		}
		div.contentpane {
			padding:4px;
			width:100%;
			height:100%
		}
		table a {
		    display: block;
		    height: 100%;
		    width: 100%;
		    text-decoration: none;
			color: black;
			text-align:center;
		}
		table span {
			background-color: #E0E0E0;
			font-family: verdana;
			font-size: 12px;
		}
		td {
			width: 64;
			height: 64;
			overflow: hidden;
			valign: "top";
		}
		a img {
			border: none;
		}
		div.msgbar {
			position:absolute;
			left:80px;
			top:434px;
			width:480px;
			height:[16*alertmsgs.len]px;
			border:2px inset black;
			background-color:#252525;
			color:#cc4040;
		}

	</style>
	</head>

	<body><div style='width:640px;height:480px;	border:2px solid black;padding:8px;background-position:center;background-image:url(\ref['nano/images/uiBackground.png'])'>"}


	dat += generate_status_bar()
	var/list/files = list_files()
	if(current)
		dat +=window(current:name,buttonbar(),filegrid(files))
	else
		dat += desktop()

	dat += msgbar()

	dat += "</div></body></html>"

	usr << browse(dat, "window=\ref[computer];size=670x510")
	onclose(usr, "\ref[computer]")

 	// STATUS BAR
 	// Small 16x16 icons representing status of components, etc.
 	// Currently only used by battery icon
 	// TODO: Add more icons!
/datum/file4/program/ntos/proc/generate_status_bar()
	var/dat = ""

	// Battery level icon
	switch(computer.check_battery_status())
		if(-1)
			dat += "<img src=\ref['icons/ntos/battery_icons/batt_none.gif']>"
		if(0 to 5)
			dat += "<img src=\ref['icons/ntos/battery_icons/batt_5.gif']>"
		if(6 to 20)
			dat += "<img src=\ref['icons/ntos/battery_icons/batt_20.gif']>"
		if(21 to 40)
			dat += "<img src=\ref['icons/ntos/battery_icons/batt_40.gif']>"
		if(41 to 60)
			dat += "<img src=\ref['icons/ntos/battery_icons/batt_60.gif']>"
		if(61 to 80)
			dat += "<img src=\ref['icons/ntos/battery_icons/batt_80.gif']>"
		if(81 to 100)
			dat += "<img src=\ref['icons/ntos/battery_icons/batt_100.gif']>"
	dat += "<br>"
	return dat

/datum/file4/program/ntos/proc/msgbar()
	var/index = 0
	var/dat = "<div class='msgbar'><span class='warning'>"
	for(var/msg in alertmsgs)
		msg = alertmsgs[msg]
		dat += msg
		dat += "<a href='?src=\ref[src];dismissalert=[index]'>\[DISMISS\]</a><br>"
		index++
	dat += "</span></div>"
	return dat

/datum/file4/program/ntos/proc/addalertmsg(var/cont)
	var/list/dat = list((alertmsgs.len + 1) = cont)
	alertmsgs.Add(dat)
	return alertmsgs.len

/datum/file4/program/ntos/proc/removealertmsg(var/num)
	alertmsgs.Remove(num)
	return 1

/datum/file4/program/ntos/Topic(href, list/href_list)
	if(!interactable() || ..(href,href_list))
		return

	if("viewperipheral" in href_list) // open drive, show status of peripheral
		var/obj/item/part/computer4/C = locate(href_list["viewperipheral"])
		if(!istype(C) || (C.loc != src.computer))
			return

		if(istype(C,/obj/item/part/computer4/storage))
			current = C
			interact()
			return
		// else ???
		if(istype(C,/obj/item/part/computer4/cardslot))
			if(computer.cardslot.reader != null)
				computer.cardslot.remove()
		if(istype(C,/obj/item/part/computer4/cardslot/dual))
			if(computer.cardslot.writer != null)
				computer.cardslot.remove(computer.cardslot.writer)
			if(computer.cardslot.reader != null)
				computer.cardslot.remove(computer.cardslot.reader)
		interact()
		return

	// distinct from close, this is the file dialog window
	if("winclose" in href_list)
		current = null
		interact()
		return

	if("runfile" in href_list)//NTOS handles folder opening on its own
		var/datum/file4/F = locate(href_list["runfile"])
		if(istype(F, /datum/file4/folder))
			current = F
			interact()
			return
		return

	if("newfolder" in href_list)
		var/datum/file4/folder/F = new()
		current:addfile(F)
		interact()
		return

	if("folderup" in href_list)
		if(!istype(current, /datum/file4/folder))//safety check
			return
		current = current:holder
		interact()
		return

	if("renamefile" in href_list)
		var/datum/file4/F = locate(href_list["renamefile"])
		F.name = input("Choose a new file name", "File name", F.name) as text
		fileop = "runfile"
		interact()
		return

	if("changefileop" in href_list)
		var/op = href_list["changefileop"]
		fileop = op
		interact()
		return

	if("dismissalert" in href_list)
		var/num = href_list["dismissalert"]
		removealertmsg(num)
		interact()
		return

	if("copyfile" in href_list)
		var/datum/file4/F = locate(href_list["copyfile"])
		buffer = F
		fileop = "runfile"
		interact()
		return

	if("emptybuffer" in href_list)
		buffer = null
		interact()
		return

	if("pastefile" in href_list)
		if(!buffer)
			return 0
		buffer.copy(current)
		interact()
		return

	if("delfile" in href_list)
		var/datum/file4/F = locate(href_list["delfile"])
		F.holder:removefile(F)
		fileop = "runfile"
		interact()
		return

#undef MAX_ROWS
#undef MAX_COLUMNS
