//===================================================================================
//Overmap object representing zlevel(s)
//===================================================================================
/obj/effect/overmap/visitable
	name = "map object"
	scannable = TRUE
	scanner_desc = "!! No Data Available !!"

	icon_state = "generic"

	/// Shows up on nav computers automatically
	var/known = TRUE
	/// Name prior to being scanned if !known
	var/unknown_name = "unknown sector"
	var/real_name // Used for late-load overmap ship distress beacons and scan_data for lateload/vvar'd scannable overmap objects
	var/real_desc
	/// Icon_state prior to being scanned if !known
	var/unknown_state = "field"
	//Set to null. Exists only for admins/GMs when spawning overmap objects.
	//We need these as normal functionality relies on initial() which do not work at all with GM shenanigans.
	var/real_icon //Holds the .dmi file for icon_state to pick from. Leave null if using standard overmap.dmi
	var/real_icon_state //actual icon name to be used. Find examples inside 'icons/obj/overmap.dmi'
	var/real_color

	var/list/map_z = list()
	var/list/extra_z_levels //if you need to manually insist that these z-levels are part of this sector, for things like edge-of-map step trigger transitions rather than multi-z complexes

	var/list/initial_generic_waypoints //store landmark_tag of landmarks that should be added to the actual lists below on init.
	var/list/initial_restricted_waypoints //For use with non-automatic landmarks (automatic ones add themselves).

	var/list/generic_waypoints = list()    //waypoints that any shuttle can use
	var/list/restricted_waypoints = list() //waypoints for specific shuttles
	var/docking_codes

	var/start_x			//Coordinates for self placing
	var/start_y			//will use random values if unset

	var/base = 0		//starting sector, counts as station_levels
	var/in_space = 1	//can be accessed via lucky EVA

	var/hide_from_reports = FALSE

	var/has_distress_beacon
	var/list/levels_for_distress
	var/list/unowned_areas // areas we don't own despite them being present on our z

	var/list/possible_descriptors = list() //While only affects sectors for now, initialized here for proc definition convenience.
	var/visitable_renamed = FALSE //changed if non-default name is assigned.

	var/unique_identifier //Define this for objs that we want to be able to rename. Needed to avoid compiler errors if not included.

	var/mob_announce_cooldown = 0 //Define this to make it so when visited, the ATC will announce their arrival. Only used if you have a Crossed/Uncrossed that calls announce_atc w/ announce_atc being redefined.

/obj/effect/overmap/visitable/Initialize(mapload)
	. = ..()
	if(. == INITIALIZE_HINT_QDEL)
		return

	find_z_levels() // This populates map_z and assigns z levels to the ship.
	register_z_levels() // This makes external calls to update global z level information.

	if(!global.using_map.overmap_z)
		build_overmap()

	start_x = start_x || rand(OVERMAP_EDGE, global.using_map.overmap_size - OVERMAP_EDGE)
	start_y = start_y || rand(OVERMAP_EDGE, global.using_map.overmap_size - OVERMAP_EDGE)

	forceMove(locate(start_x, start_y, global.using_map.overmap_z))

	if(!docking_codes)
		docking_codes = "[ascii2text(rand(65,90))][ascii2text(rand(65,90))][ascii2text(rand(65,90))][ascii2text(rand(65,90))]"

	#ifdef TESTING
	testing("Located sector \"[name]\" at [start_x],[start_y], containing Z [english_list(map_z)]")
	#endif

	LAZYADD(SSshuttles.sectors_to_initialize, src) //Queued for further init. Will populate the waypoint lists; waypoints not spawned yet will be added in as they spawn.
	SSshuttles.process_init_queues()

	if(known)
		plane = PLANE_LIGHTING_ABOVE
		for(var/obj/machinery/computer/ship/helm/H in GLOB.machines)
			H.get_known_sectors()
	else
		real_appearance = image(icon, src, icon_state)
		real_appearance.override = TRUE
		real_name = name
		name = unknown_name
		icon_state = unknown_state
		color = null
		real_desc = desc
		desc = "Scan this to find out more information."
	//at the moment only used for the OM location renamer. Initializing here in case we want shuttles incl as well in future. Also proc definition convenience.
	GLOB.visitable_overmap_object_instances += src

	for(var/i in 1 to length(levels_for_distress))
		var/current = levels_for_distress[i]
		if(isnum(current))
			continue
		levels_for_distress[i] = GLOB.map_templates_loaded[current]
	if(!levels_for_distress)
		levels_for_distress = list(1)

//To be used by GMs and calling through var edits for the overmap object
//It causes the overmap object to "reinitialize" its real_appearance for known = FALSE objects
//Includes an argument that allows GMs/Admins to set a previously known sector to unknown. Set to any value except 0/False/Null to activate
/obj/effect/overmap/visitable/proc/gmtools_update_omobject_vars(var/setToHidden)
	real_appearance = image(real_icon, src, real_icon_state)
	real_appearance.override = TRUE
	if(setToHidden && known) //
		name = unknown_name
		icon = 'icons/obj/overmap.dmi'
		icon_state = unknown_state
		color = null
		desc = "Scan this to find out more information."
		known = FALSE


// You generally shouldn't destroy these.
/obj/effect/overmap/visitable/Destroy()
	testing("Deleting [src] overmap sector at [x],[y]")
	unregister_z_levels()
	return ..()

//This is called later in the init order by SSshuttles to populate sector objects. Importantly for subtypes, shuttles will be created by then.
/obj/effect/overmap/visitable/proc/populate_sector_objects()

/obj/effect/overmap/visitable/proc/get_areas()
	. = list()
	for(var/area/A)
		if (A.z in map_z)
			. += A

/obj/effect/overmap/visitable/proc/find_z_levels()
	if(!LAZYLEN(map_z)) // If map_z is already populated use it as-is, otherwise start with connected z-levels.
		map_z = GetConnectedZlevels(z)

	// extra_z_levels may need to be resolved
	for(var/extra_z in extra_z_levels)
		if(isnum(extra_z))
			map_z |= extra_z
			continue
		var/resolved_z = GLOB.map_templates_loaded[extra_z]
		if(resolved_z)
			map_z |= resolved_z
		else
			admin_notice(span_danger("[src] could not find z_level [extra_z]!"), R_DEBUG)

/obj/effect/overmap/visitable/proc/register_z_levels()
	for(var/zlevel in map_z)
		GLOB.map_sectors["[zlevel]"] = src

	global.using_map.player_levels |= map_z
	if(!in_space)
		global.using_map.sealed_levels |= map_z
	/* VOREStation Removal - We have a map system that does this already.
	if(base)
		global.using_map.station_levels |= map_z
		global.using_map.contact_levels |= map_z
		global.using_map.map_levels |= map_z
	*/

/obj/effect/overmap/visitable/proc/unregister_z_levels()
	GLOB.map_sectors -= map_z

	global.using_map.player_levels -= map_z
	if(!in_space)
		global.using_map.sealed_levels -= map_z
	/* VOREStation Removal - We have a map system that does this already.
	if(base)
		global.using_map.station_levels -= map_z
		global.using_map.contact_levels -= map_z
		global.using_map.map_levels -= map_z
	*/

/obj/effect/overmap/visitable/get_scan_data()
	if(!known)
		known = TRUE
		name = (real_name ? real_name : initial(name))
		color = (real_color ? real_color : initial(color))
		desc = (real_desc ? real_desc : initial(desc))
		if(real_icon)  //Only true if GMs/Admins want a non-standard icon from outside 'icons/obj/overmap.dmi'
			icon = real_icon
		icon_state = (real_icon_state ? real_icon_state : initial(icon_state))
	return ..()

/obj/effect/overmap/visitable/proc/get_space_zlevels()
	if(in_space)
		return map_z
	else
		return list()

//Helper for init.
/obj/effect/overmap/visitable/proc/check_ownership(obj/object)
	var/area/A = get_area(object)
	if(A in SSshuttles.shuttle_areas)
		return 0
	if(is_type_in_list(A, unowned_areas))
		return 0
	if(get_z(object) in map_z)
		return 1

//If shuttle_name is false, will add to generic waypoints; otherwise will add to restricted. Does not do checks.
/obj/effect/overmap/visitable/proc/add_landmark(obj/effect/shuttle_landmark/landmark, shuttle_name)
	landmark.sector_set(src, shuttle_name)
	if(shuttle_name)
		LAZYADD(restricted_waypoints[shuttle_name], landmark)
	else
		generic_waypoints += landmark

/obj/effect/overmap/visitable/proc/remove_landmark(obj/effect/shuttle_landmark/landmark, shuttle_name)
	if(shuttle_name)
		var/list/shuttles = restricted_waypoints[shuttle_name]
		LAZYREMOVE(shuttles, landmark)
	else
		generic_waypoints -= landmark

/obj/effect/overmap/visitable/proc/get_waypoints(var/shuttle_name)
	. = list()
	for(var/obj/effect/overmap/visitable/contained in src)
		. += contained.get_waypoints(shuttle_name)
	for(var/thing in generic_waypoints)
		.[thing] = name
	if(shuttle_name in restricted_waypoints)
		for(var/thing in restricted_waypoints[shuttle_name])
			.[thing] = name

/obj/effect/overmap/visitable/proc/generate_skybox(zlevel)
	return

/obj/effect/overmap/visitable/proc/cleanup()
	return FALSE

/obj/effect/overmap/visitable/MouseEntered(location, control, params)
	openToolTip(user = usr, tip_src = src, params = params, title = name)

	..()

/obj/effect/overmap/visitable/MouseDown()
	closeToolTip(usr) //No reason not to, really

	..()

/obj/effect/overmap/visitable/MouseExited()
	closeToolTip(usr) //No reason not to, really

	..()

/obj/effect/overmap/visitable/sector
	name = "generic sector"
	desc = "Sector with some stuff in it."
	icon_state = "sector"
	anchored = TRUE

/obj/effect/overmap/visitable/sector/proc/announce_atc(var/atom/movable/AM, var/going = FALSE) //Base proc. Used for virgo3b at this time.
	return
// Because of the way these are spawned, they will potentially have their invisibility adjusted by the turfs they are mapped on
// prior to being moved to the overmap. This blocks that. Use set_invisibility to adjust invisibility as needed instead.
/obj/effect/overmap/visitable/sector/hide()

/obj/effect/overmap/visitable/proc/distress(mob/user)
	if(has_distress_beacon)
		return FALSE
	has_distress_beacon = TRUE

	admin_chat_message(message = "Overmap panic button hit on z[z] ([name]) by '[user?.ckey || "Unknown"]'", color = "#FF2222") //VOREStation Add
	var/message = "This is an automated distress signal from a MIL-DTL-93352-compliant beacon transmitting on [PUB_FREQ*0.1]kHz. \
	This beacon was launched from '[real_name ? real_name : initial(name)]'. I can provide this additional information to rescuers: [get_distress_info()]. \
	Per the Interplanetary Convention on Space SAR, those receiving this message must attempt rescue, \
	or relay the message to those who can. This message will repeat one time in 5 minutes. Thank you for your urgent assistance."

	for(var/zlevel in levels_for_distress)
		priority_announcement.Announce(message, new_title = "Automated Distress Signal", new_sound = 'sound/AI/sos.ogg', zlevel = zlevel)

	var/image/I = image(icon, icon_state = "distress")
	I.plane = PLANE_LIGHTING_ABOVE
	I.appearance_flags = KEEP_APART|RESET_TRANSFORM|RESET_COLOR
	add_overlay(I)

	addtimer(CALLBACK(src, PROC_REF(distress_update)), 5 MINUTES)
	return TRUE

/obj/effect/overmap/visitable/proc/get_distress_info()
	return "\[X:[x], Y:[y]\]"

/obj/effect/overmap/visitable/proc/distress_update()
	var/message = "This is the final message from the distress beacon launched from '[real_name ? real_name : initial(name)]'. I can provide this additional information to rescuers: [get_distress_info()]. \
	Please render assistance under your obligations per the Interplanetary Convention on Space SAR, or relay this message to a party who can. Thank you for your urgent assistance."

	for(var/zlevel in levels_for_distress)
		priority_announcement.Announce(message, new_title = "Automated Distress Signal", new_sound = 'sound/AI/sos.ogg', zlevel = zlevel)

/proc/build_overmap()
	if(!global.using_map.use_overmap)
		return 1

	testing("Building overmap...")
	world.increment_max_z()
	global.using_map.overmap_z = world.maxz

	testing("Putting overmap on [global.using_map.overmap_z]")
	var/area/overmap/A = new
	for(var/turf/T as anything in block(locate(1,1,global.using_map.overmap_z), locate(global.using_map.overmap_size,global.using_map.overmap_size,global.using_map.overmap_z)))
		if(T.x == 1 || T.y == 1 || T.x == global.using_map.overmap_size || T.y == global.using_map.overmap_size)
			T = T.ChangeTurf(/turf/unsimulated/map/edge)
		else
			T = T.ChangeTurf(/turf/unsimulated/map)
		ChangeArea(T, A)

	global.using_map.sealed_levels |= global.using_map.overmap_z

	testing("Overmap build complete.")
	return 1
