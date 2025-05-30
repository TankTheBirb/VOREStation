//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31

/obj/machinery/computer/prisoner
	name = "prisoner management console"
	desc = "Used to keep those sneaky prisoners in line, if they have an implant."
	icon_keyboard = "security_key"
	icon_screen = "explosive"
	light_color = "#a91515"
	req_access = list(access_armory)
	circuit = /obj/item/circuitboard/prisoner
	var/id = 0.0
	var/temp = null
	var/status = 0
	var/timeleft = 60
	var/stop = 0.0
	var/screen = 0 // 0 - No Access Denied, 1 - Access allowed

/obj/machinery/computer/prisoner/attack_ai(var/mob/user as mob)
	return src.attack_hand(user)

/obj/machinery/computer/prisoner/attack_hand(mob/user)
	if(..())
		return
	tgui_interact(user)

/obj/machinery/computer/prisoner/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PrisonerManagement", name)
		ui.open()

/obj/machinery/computer/prisoner/tgui_data(mob/user)
	var/list/chemImplants = list()
	var/list/trackImplants = list()
	if(screen)
		for(var/obj/item/implant/chem/C in GLOB.all_chem_implants)
			var/turf/T = get_turf(C)
			if(!T)
				continue
			if(!C.implanted)
				continue
			chemImplants.Add(list(list(
				"host" = C.imp_in,
				"units" = C.reagents.total_volume,
				"ref" = "\ref[C]"
			)))
		for(var/obj/item/implant/tracking/track in GLOB.all_tracking_implants)
			var/turf/T = get_turf(track)
			if(!T)
				continue
			if(!track.implanted)
				continue
			var/loc_display = "Unknown"
			var/mob/living/L = track.imp_in
			if((get_z(L) in using_map.station_levels) && !istype(L.loc, /turf/space))
				loc_display = T.loc
			if(track.malfunction)
				loc_display = pick(GLOB.teleportlocs)
			trackImplants.Add(list(list(
				"host" = L,
				"ref" = "\ref[track]",
				"id" = "[track.id]",
				"loc" = "[loc_display]",
			)))

	return list("locked" = !screen, "chemImplants" = chemImplants, "trackImplants" = trackImplants)


/obj/machinery/computer/prisoner/tgui_act(action, list/params, datum/tgui/ui)
	if(..())
		return TRUE
	switch(action)
		if("inject")
			var/obj/item/implant/I = locate(params["imp"])
			if(I)
				I.activate(clamp(params["val"], 0, 10))
			. = TRUE
		if("lock")
			if(allowed(ui.user))
				screen = !screen
			else
				to_chat(ui.user, "Unauthorized Access.")
			. = TRUE
		if("warn")
			var/warning = sanitize(tgui_input_text(ui.user, "Message:", "Enter your message here!", ""))
			if(!warning)
				return
			var/obj/item/implant/I = locate(params["imp"])
			if(I && I.imp_in)
				to_chat(I.imp_in, span_notice("You hear a voice in your head saying: '[warning]'"))
			. = TRUE
	add_fingerprint(ui.user)
