/obj/item/uv_light
	name = "\improper UV light"
	desc = "A small handheld black light."
	icon = 'icons/obj/device.dmi'
	icon_state = "uv_off"
	slot_flags = SLOT_BELT
	w_class = ITEMSIZE_SMALL
	item_state = "electronic"
	actions_types = list(/datum/action/item_action/toggle_uv_light)
	matter = list(MAT_STEEL = 150)
	origin_tech = list(TECH_MAGNET = 1, TECH_ENGINEERING = 1)

	var/list/scanned = list()
	var/list/stored_alpha = list()
	var/list/reset_objects = list()

	var/range = 3
	var/on = 0
	var/step_alpha = 50
	pickup_sound = 'sound/items/pickup/device.ogg'
	drop_sound = 'sound/items/drop/device.ogg'

/obj/item/uv_light/attack_self(var/mob/user)
	on = !on
	if(on)
		set_light(range, 2, "#007fff")
		START_PROCESSING(SSobj, src)
		icon_state = "uv_on"
	else
		set_light(0)
		clear_last_scan()
		STOP_PROCESSING(SSobj, src)
		icon_state = "uv_off"

/obj/item/uv_light/proc/clear_last_scan()
	if(scanned.len)
		for(var/atom/O in scanned)
			O.invisibility = scanned[O]
			if(O.fluorescent == 2) O.fluorescent = 1
		scanned.Cut()
	if(stored_alpha.len)
		for(var/atom/O in stored_alpha)
			O.alpha = stored_alpha[O]
			if(O.fluorescent == 2) O.fluorescent = 1
		stored_alpha.Cut()
	if(reset_objects.len)
		for(var/obj/item/I in reset_objects)
			I.cut_overlay(I.blood_overlay)
			if(I.fluorescent == 2) I.fluorescent = 1
		reset_objects.Cut()

/obj/item/uv_light/process()
	clear_last_scan()
	if(on)
		step_alpha = round(255/range)
		var/turf/origin = get_turf(src)
		if(!origin)
			return
		for(var/turf/T in range(range, origin))
			var/use_alpha = 255 - (step_alpha * get_dist(origin, T))
			for(var/atom/A in T.contents)
				if(A.fluorescent == 1)
					A.fluorescent = 2 //To prevent light crosstalk.
					if(A.invisibility)
						scanned[A] = A.invisibility
						A.invisibility = INVISIBILITY_NONE
						stored_alpha[A] = A.alpha
						A.alpha = use_alpha
					if(istype(A, /obj/item))
						var/obj/item/O = A
						if(O.was_bloodied && !(O.blood_overlay in O.overlays))
							O.add_overlay(O.blood_overlay)
							reset_objects |= O
