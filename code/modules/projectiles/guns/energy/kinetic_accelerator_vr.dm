#define LAVALAND_EQUIPMENT_EFFECT_PRESSURE 50 //what pressure you have to be under to increase the effect of equipment meant for lavaland
#define HEATMODE_ATMOSPHERE		312.1 //kPa. basically virgo 2's
#define HEATMODE_TEMP			612 //kelvin. basically virgo 2's
/**
 * This is here for now
 */
/proc/lavaland_environment_check(turf/simulated/T)
	. = TRUE
	if(!istype(T))
		return
	var/datum/gas_mixture/environment = T.return_air()
	if(!istype(environment))
		return
	var/pressure = environment.return_pressure()
	if(pressure > LAVALAND_EQUIPMENT_EFFECT_PRESSURE)
		. = FALSE
	if(environment.temperature < (T20C - 30))
		. = TRUE

/proc/virgotwo_environment_check(turf/simulated/T)
	. = TRUE
	if(!istype(T))
		return
	var/datum/gas_mixture/environment = T.return_air()
	if(!istype(environment))
		return
	var/pressure = environment.return_pressure()
	if(pressure < HEATMODE_ATMOSPHERE - 20)
		. = FALSE
	if(environment.temperature > HEATMODE_TEMP - 30)
		. = TRUE

#undef LAVALAND_EQUIPMENT_EFFECT_PRESSURE
#undef HEATMODE_ATMOSPHERE
#undef HEATMODE_TEMP

/proc/offsite_environment_check(turf/simulated/T)
	. = TRUE
	if(!istype(T))
		return
	if(T.z in using_map.station_levels)
		. = FALSE

/obj/item/gun/energy/kinetic_accelerator
	name = "proto-kinetic accelerator"
	desc = "A self recharging, ranged mining tool that does increased damage in low pressure."
	icon = 'icons/obj/gun_vr.dmi'
	icon_state = "kineticgun"
	item_icons = list(
		slot_l_hand_str = 'icons/mob/items/lefthand_guns_vr.dmi',
		slot_r_hand_str = 'icons/mob/items/righthand_guns_vr.dmi',
		)
	item_state = "kineticgun"
	// ammo_type = list(/obj/item/ammo_casing/energy/kinetic)
	cell_type = /obj/item/cell/device/weapon/empproof
	item_flags = NONE
	charge_meter = FALSE
	// obj_flags = UNIQUE_RENAME
	// weapon_weight = WEAPON_LIGHT
	// can_flashlight = 1
	// flight_x_offset = 15
	// flight_y_offset = 9
	// automatic_charge_overlays = FALSE
	projectile_type = /obj/item/projectile/kinetic
	charge_cost = 1200
	battery_lock = TRUE
	fire_sound = 'sound/weapons/kenetic_accel.ogg'
	var/overheat_time = 16
	var/holds_charge = FALSE
	var/unique_frequency = FALSE // modified by KA modkits
	var/overheat = FALSE
	var/emptystate = "kineticgun_empty"
	shot_counter = FALSE
	// can_bayonet = TRUE
	// knife_x_offset = 20
	// knife_y_offset = 12

	var/max_mod_capacity = 100
	var/list/modkits = list()

	var/recharge_timerid

/obj/item/gun/energy/kinetic_accelerator/consume_next_projectile()
	if(overheat)
		return
	. = ..()
	if(.)
		var/obj/item/projectile/P = .
		modify_projectile(P)

/obj/item/gun/energy/kinetic_accelerator/handle_post_fire(mob/user, atom/target, pointblank, reflex)
	. = ..()
	attempt_reload()

/obj/item/gun/energy/kinetic_accelerator/premiumka
	name = "premium accelerator"
	desc = "A premium kinetic accelerator fitted with an extended barrel and increased pressure tank."
	icon_state = "premiumgun"
	item_state = "premiumgun"
	projectile_type = /obj/item/projectile/kinetic/premium

/obj/item/gun/energy/kinetic_accelerator/examine(mob/user)
	. = ..()
	if(max_mod_capacity)
		. += span_bold("[get_remaining_mod_capacity()]%") + " mod capacity remaining."
		for(var/A in get_modkits())
			var/obj/item/borg/upgrade/modkit/M = A
			. += span_notice("There is \a [M] installed, using <b>[M.cost]%</b> capacity.")

/obj/item/gun/energy/kinetic_accelerator/Exited(atom/movable/AM)
	. = ..()
	if((AM in modkits) && istype(AM, /obj/item/borg/upgrade/modkit))
		var/obj/item/borg/upgrade/modkit/M = AM
		M.uninstall(src, FALSE)

/obj/item/gun/energy/kinetic_accelerator/attackby(obj/item/I, mob/user)
	if(I.has_tool_quality(TOOL_CROWBAR))
		if(modkits.len)
			to_chat(user, span_notice("You pry the modifications out."))
			playsound(loc, I.usesound, 100, 1)
			for(var/obj/item/borg/upgrade/modkit/M in modkits)
				M.uninstall(src)
		else
			to_chat(user, span_notice("There are no modifications currently installed."))
	if(istype(I, /obj/item/borg/upgrade/modkit))
		var/obj/item/borg/upgrade/modkit/MK = I
		MK.install(src, user)
	else
		..()

/obj/item/gun/energy/kinetic_accelerator/proc/get_remaining_mod_capacity()
	var/current_capacity_used = 0
	for(var/A in get_modkits())
		var/obj/item/borg/upgrade/modkit/M = A
		current_capacity_used += M.cost
	return max_mod_capacity - current_capacity_used

/obj/item/gun/energy/kinetic_accelerator/proc/get_modkits()
	. = list()
	for(var/A in modkits)
		. += A

/obj/item/gun/energy/kinetic_accelerator/proc/modify_projectile(obj/item/projectile/kinetic/K)
	K.kinetic_gun = src //do something special on-hit, easy!
	for(var/A in get_modkits())
		var/obj/item/borg/upgrade/modkit/M = A
		M.modify_projectile(K)

/obj/item/gun/energy/kinetic_accelerator/cyborg
	holds_charge = TRUE
	unique_frequency = TRUE

/obj/item/gun/energy/kinetic_accelerator/cyborg/Destroy()
	for(var/obj/item/borg/upgrade/modkit/M in modkits)
		M.uninstall(src)
	return ..()

/obj/item/gun/energy/kinetic_accelerator/premiumka/cyborg
	holds_charge = TRUE
	unique_frequency = TRUE

/obj/item/gun/energy/kinetic_accelerator/premiumka/cyborg/Destroy()
	for(var/obj/item/borg/upgrade/modkit/M in modkits)
		M.uninstall(src)
	return ..()

/obj/item/gun/energy/kinetic_accelerator/minebot
	// trigger_guard = TRIGGER_GUARD_ALLOW_ALL
	overheat_time = 20
	holds_charge = TRUE
	unique_frequency = TRUE

/obj/item/gun/energy/kinetic_accelerator/Initialize(mapload)
	. = ..()
	if(!holds_charge)
		empty()
	AddElement(/datum/element/conflict_checking, CONFLICT_ELEMENT_KA)

/obj/item/gun/energy/kinetic_accelerator/equipped(mob/user)
	. = ..()
	if(power_supply.charge < charge_cost)
		attempt_reload()

/obj/item/gun/energy/kinetic_accelerator/dropped(mob/user)
	. = ..()
	if(!QDELING(src) && !holds_charge)
		// Put it on a delay because moving item from slot to hand
		// calls dropped().
		addtimer(CALLBACK(src, PROC_REF(empty_if_not_held)), 2)

/obj/item/gun/energy/kinetic_accelerator/proc/empty_if_not_held()
	if(!ismob(loc) && !istype(loc, /obj/item/integrated_circuit))
		empty()

/obj/item/gun/energy/kinetic_accelerator/proc/empty()
	if(power_supply)
		power_supply.use(power_supply.charge)
		update_icon()

/obj/item/gun/energy/kinetic_accelerator/proc/attempt_reload(recharge_time)
	if(!power_supply)
		return
	if(overheat)
		return
	if(!recharge_time)
		recharge_time = overheat_time
	overheat = TRUE
	update_icon()

	var/carried = max(1, loc.ConflictElementCount(CONFLICT_ELEMENT_KA))

	deltimer(recharge_timerid)
	recharge_timerid = addtimer(CALLBACK(src, PROC_REF(reload)), recharge_time * carried, TIMER_STOPPABLE)

/obj/item/gun/energy/kinetic_accelerator/emp_act(severity)
	return

/obj/item/gun/energy/kinetic_accelerator/proc/reload()
	power_supply.give(power_supply.maxcharge)
	// process_chamber()
	// if(!suppressed)
	playsound(src, 'sound/weapons/kenetic_reload.ogg', 60, 1)
	// else
		// to_chat(loc, span_warning("[src] silently charges up."))
	overheat = FALSE
	update_icon()

/obj/item/gun/energy/kinetic_accelerator/update_icon()
	cut_overlays()
	if(overheat || !power_supply || (power_supply.charge == 0))
		add_overlay(emptystate)

#define KA_ENVIRO_TYPE_COLD 0
#define KA_ENVIRO_TYPE_HOT 1
#define KA_ENVIRO_TYPE_OFFSITE 2

//Projectiles
/obj/item/projectile/kinetic
	name = "kinetic force"
	icon_state = null
	damage = 30
	damage_type = BRUTE
	check_armour = "bomb"
	range = 4
	// log_override = TRUE

	var/pressure_decrease_active = FALSE
	var/pressure_decrease = 1/3
	var/environment = KA_ENVIRO_TYPE_COLD
	var/obj/item/gun/energy/kinetic_accelerator/kinetic_gun

/obj/item/projectile/kinetic/premium
	damage = 40
	damage_type = BRUTE
	range = 5

/obj/item/projectile/kinetic/Destroy()
	kinetic_gun = null
	return ..()

/obj/item/projectile/kinetic/Bump(atom/target)
	if(kinetic_gun)
		var/list/mods = kinetic_gun.get_modkits()
		for(var/obj/item/borg/upgrade/modkit/M in mods)
			M.projectile_prehit(src, target, kinetic_gun)
	if(!pressure_decrease_active)
		if(environment == KA_ENVIRO_TYPE_COLD)
			if(!lavaland_environment_check(get_turf(src)))
				name = "weakened [name]"
				damage = damage * pressure_decrease
				pressure_decrease_active = TRUE
		else if(environment == KA_ENVIRO_TYPE_HOT)
			if(!virgotwo_environment_check(get_turf(src)))
				name = "weakened [name]"
				damage = damage * pressure_decrease
				pressure_decrease_active = TRUE
		else if(environment == KA_ENVIRO_TYPE_OFFSITE)
			if(!offsite_environment_check(get_turf(src)))
				name = "nullified [name]"
				nodamage = TRUE
				damage = 0
				pressure_decrease_active = TRUE
	return ..()

/obj/item/projectile/kinetic/attack_mob(mob/living/target_mob, distance, miss_modifier)
	if(!pressure_decrease_active)
		if(environment == KA_ENVIRO_TYPE_COLD)
			if(!lavaland_environment_check(get_turf(src)))
				name = "weakened [name]"
				damage = damage * pressure_decrease
				pressure_decrease_active = TRUE
		else if(environment == KA_ENVIRO_TYPE_HOT)
			if(!virgotwo_environment_check(get_turf(src)))
				name = "weakened [name]"
				damage = damage * pressure_decrease
				pressure_decrease_active = TRUE
		else if(environment == KA_ENVIRO_TYPE_OFFSITE)
			if(!offsite_environment_check(get_turf(src)))
				name = "nullified [name]"
				nodamage = TRUE
				damage = 0
				pressure_decrease_active = TRUE
	return ..()

/obj/item/projectile/kinetic/on_range()
	strike_thing()
	..()

/obj/item/projectile/kinetic/on_hit(atom/target)
	strike_thing(target)
	. = ..()

/obj/item/projectile/kinetic/on_impact(atom/A)
	. = ..()
	strike_thing(A)

/obj/item/projectile/kinetic/proc/strike_thing(atom/target)
	if(!pressure_decrease_active)
		if(environment == KA_ENVIRO_TYPE_COLD)
			if(!lavaland_environment_check(get_turf(src)))
				name = "weakened [name]"
				damage = damage * pressure_decrease
				pressure_decrease_active = TRUE
		else if(environment == KA_ENVIRO_TYPE_HOT)
			if(!virgotwo_environment_check(get_turf(src)))
				name = "weakened [name]"
				damage = damage * pressure_decrease
				pressure_decrease_active = TRUE
		else if(environment == KA_ENVIRO_TYPE_OFFSITE)
			if(!offsite_environment_check(get_turf(src)))
				name = "nullified [name]"
				nodamage = TRUE
				damage = 0
				pressure_decrease_active = TRUE
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		target_turf = get_turf(src)
	if(kinetic_gun) //hopefully whoever shot this was not very, very unfortunate.
		var/list/mods = kinetic_gun.get_modkits()
		for(var/obj/item/borg/upgrade/modkit/M in mods)
			M.projectile_strike_predamage(src, target_turf, target, kinetic_gun)
		for(var/obj/item/borg/upgrade/modkit/M in mods)
			M.projectile_strike(src, target_turf, target, kinetic_gun)
	if(ismineralturf(target_turf))
		var/turf/simulated/mineral/M = target_turf
		M.GetDrilled(TRUE)
	var/obj/effect/temp_visual/kinetic_blast/K = new /obj/effect/temp_visual/kinetic_blast(target_turf)
	K.color = color

//Modkits
/obj/item/borg/upgrade/modkit
	name = "kinetic accelerator modification kit"
	desc = "An upgrade for kinetic accelerators."
	icon = 'icons/obj/objects_vr.dmi'
	icon_state = "modkit"
	w_class = ITEMSIZE_SMALL
	require_module = 1
	// module_type = list(/obj/item/robot_module/miner)
	var/denied_type = null
	var/maximum_of_type = 1
	var/cost = 30
	var/modifier = 1 //For use in any mod kit that has numerical modifiers
	var/minebot_upgrade = TRUE
	var/minebot_exclusive = FALSE

/obj/item/borg/upgrade/modkit/examine(mob/user)
	. = ..()
	. += span_notice("Occupies <b>[cost]%</b> of mod capacity.")

/obj/item/borg/upgrade/modkit/attackby(obj/item/A, mob/user)
	if(istype(A, /obj/item/gun/energy/kinetic_accelerator))
		install(A, user)
	else
		..()

/*
/obj/item/borg/upgrade/modkit/afterInstall(mob/living/silicon/robot/R)
	for(var/obj/item/gun/energy/kinetic_accelerator/H in R.module.modules)
		if(install(H, R)) //It worked
			return
	to_chat(R, span_warning("Upgrade error - Aborting Kinetic Accelerator linking.")) //No applicable KA found, insufficient capacity, or some other problem.
*/

/obj/item/borg/upgrade/modkit/proc/install(obj/item/gun/energy/kinetic_accelerator/KA, mob/user)
	. = TRUE
	if(src in KA.modkits) // Sanity check to prevent installing the same modkit twice thanks to occasional click/lag delays.
		return FALSE
	if(denied_type)
		var/number_of_denied = 0
		for(var/A in KA.get_modkits())
			var/obj/item/borg/upgrade/modkit/M = A
			if(istype(M, denied_type))
				number_of_denied++
			if(number_of_denied >= maximum_of_type)
				. = FALSE
				break
	if(KA.get_remaining_mod_capacity() >= cost)
		if(.)
			user.drop_from_inventory(src, KA)
			// if(!user.transferItemToLoc(src, KA))
				// return FALSE
			to_chat(user, span_notice("You install the modkit."))
			playsound(loc, 'sound/items/screwdriver.ogg', 100, 1)
			KA.modkits += src
		else
			to_chat(user, span_notice("The modkit you're trying to install would conflict with an already installed modkit. Use a crowbar to remove existing modkits."))
	else
		to_chat(user, span_notice("You don't have room(<b>[KA.get_remaining_mod_capacity()]%</b> remaining, [cost]% needed) to install this modkit. Use a crowbar to remove existing modkits."))
		. = FALSE

/obj/item/borg/upgrade/modkit/proc/uninstall(obj/item/gun/energy/kinetic_accelerator/KA, forcemove = TRUE)
	KA.modkits -= src
	if(forcemove)
		forceMove(get_turf(KA))

//use this one to modify the projectile itself
/obj/item/borg/upgrade/modkit/proc/modify_projectile(obj/item/projectile/kinetic/K)
//use this one for effects you want to trigger before any damage is done at all and before damage is decreased by pressure
/obj/item/borg/upgrade/modkit/proc/projectile_prehit(obj/item/projectile/kinetic/K, atom/target, obj/item/gun/energy/kinetic_accelerator/KA)
//use this one for effects you want to trigger before mods that do damage
/obj/item/borg/upgrade/modkit/proc/projectile_strike_predamage(obj/item/projectile/kinetic/K, turf/target_turf, atom/target, obj/item/gun/energy/kinetic_accelerator/KA)
//and this one for things that don't need to trigger before other damage-dealing mods
/obj/item/borg/upgrade/modkit/proc/projectile_strike(obj/item/projectile/kinetic/K, turf/target_turf, atom/target, obj/item/gun/energy/kinetic_accelerator/KA)

//Range
/obj/item/borg/upgrade/modkit/range
	name = "range increase"
	desc = "Increases the range of a kinetic accelerator when installed."
	modifier = 1
	cost = 25

/obj/item/borg/upgrade/modkit/range/modify_projectile(obj/item/projectile/kinetic/K)
	K.range += modifier


//Damage
/obj/item/borg/upgrade/modkit/damage
	name = "damage increase"
	desc = "Increases the damage of kinetic accelerator when installed."
	modifier = 10

/obj/item/borg/upgrade/modkit/damage/modify_projectile(obj/item/projectile/kinetic/K)
	K.damage += modifier


//Cooldown
/obj/item/borg/upgrade/modkit/cooldown
	name = "cooldown decrease"
	desc = "Decreases the cooldown of a kinetic accelerator. Not rated for minebot use."
	modifier = 2.5
	minebot_upgrade = FALSE
	var/decreased

/obj/item/borg/upgrade/modkit/cooldown/install(obj/item/gun/energy/kinetic_accelerator/KA, mob/user)
	. = ..()
	if(.)
		var/old = KA.overheat_time
		KA.overheat_time = max(0, KA.overheat_time - modifier)
		decreased = old - KA.overheat_time


/obj/item/borg/upgrade/modkit/cooldown/uninstall(obj/item/gun/energy/kinetic_accelerator/KA)
	KA.overheat_time += decreased
	..()

/obj/item/borg/upgrade/modkit/cooldown/minebot
	name = "minebot cooldown decrease"
	desc = "Decreases the cooldown of a kinetic accelerator. Only rated for minebot use."
	icon_state = "door_electronics"
	icon = 'icons/obj/module.dmi'
	denied_type = /obj/item/borg/upgrade/modkit/cooldown/minebot
	modifier = 10
	cost = 0
	minebot_upgrade = TRUE
	minebot_exclusive = TRUE


//AoE blasts
/obj/item/borg/upgrade/modkit/aoe
	modifier = 0
	var/turf_aoe = FALSE
	var/stats_stolen = FALSE

/obj/item/borg/upgrade/modkit/aoe/install(obj/item/gun/energy/kinetic_accelerator/KA, mob/user)
	. = ..()
	if(.)
		for(var/obj/item/borg/upgrade/modkit/aoe/AOE in KA.modkits) //make sure only one of the aoe modules has values if somebody has multiple
			if(AOE.stats_stolen || AOE == src)
				continue
			modifier += AOE.modifier //take its modifiers
			AOE.modifier = 0
			turf_aoe += AOE.turf_aoe
			AOE.turf_aoe = FALSE
			AOE.stats_stolen = TRUE

/obj/item/borg/upgrade/modkit/aoe/uninstall(obj/item/gun/energy/kinetic_accelerator/KA)
	..()
	modifier = initial(modifier) //get our modifiers back
	turf_aoe = initial(turf_aoe)
	stats_stolen = FALSE

/obj/item/borg/upgrade/modkit/aoe/modify_projectile(obj/item/projectile/kinetic/K)
	K.name = "kinetic explosion"

/obj/item/borg/upgrade/modkit/aoe/projectile_strike(obj/item/projectile/kinetic/K, turf/target_turf, atom/target, obj/item/gun/energy/kinetic_accelerator/KA)
	if(stats_stolen)
		return
	new /obj/effect/temp_visual/explosion/fast(target_turf)
	if(turf_aoe)
		for(var/T in RANGE_TURFS(1, target_turf) - target_turf)
			if(ismineralturf(T))
				var/turf/simulated/mineral/M = T
				M.GetDrilled(TRUE)
	if(modifier)
		for(var/mob/living/L in range(1, target_turf) - K.firer - target)
			var/armor = L.run_armor_check(K.def_zone, K.check_armour)
			// var/armor = L.run_armor_check(K.def_zone, K.flag, null, null, K.armour_penetration)
			L.apply_damage(K.damage*modifier, K.damage_type, K.def_zone, armor)
			// L.apply_damage(K.damage*modifier, K.damage_type, K.def_zone, armor)
			to_chat(L, span_userdanger("You're struck by a [K.name]!"))

/obj/item/borg/upgrade/modkit/aoe/turfs
	name = "mining explosion"
	desc = "Causes the kinetic accelerator to destroy rock in an AoE."
	denied_type = /obj/item/borg/upgrade/modkit/aoe/turfs
	turf_aoe = TRUE

/obj/item/borg/upgrade/modkit/aoe/turfs/andmobs
	name = "offensive mining explosion"
	desc = "Causes the kinetic accelerator to destroy rock and damage mobs in an AoE."
	maximum_of_type = 3
	modifier = 0.25

/obj/item/borg/upgrade/modkit/aoe/mobs
	name = "offensive explosion"
	desc = "Causes the kinetic accelerator to damage mobs in an AoE."
	modifier = 0.2

//Minebot passthrough
/obj/item/borg/upgrade/modkit/minebot_passthrough
	name = "minebot passthrough"
	desc = "Causes kinetic accelerator shots to pass through minebots."
	cost = 0

//Tendril-unique modules
/obj/item/borg/upgrade/modkit/cooldown/repeater
	name = "rapid repeater"
	desc = "Quarters the kinetic accelerator's cooldown on striking a living or mineral target, but greatly increases the base cooldown."
	denied_type = /obj/item/borg/upgrade/modkit/cooldown/repeater
	modifier = -14 //Makes the cooldown 3 seconds(with no cooldown mods) if you miss. Don't miss.
	cost = 50

/obj/item/borg/upgrade/modkit/cooldown/repeater/projectile_strike_predamage(obj/item/projectile/kinetic/K, turf/target_turf, atom/target, obj/item/gun/energy/kinetic_accelerator/KA)
	var/valid_repeat = FALSE
	if(isliving(target))
		var/mob/living/L = target
		if(L.stat != DEAD)
			valid_repeat = TRUE
	if(ismineralturf(target_turf))
		valid_repeat = TRUE
	if(valid_repeat)
		KA.overheat = FALSE
		KA.attempt_reload(KA.overheat_time * 0.25) //If you hit, the cooldown drops to 0.75 seconds.

/*
/obj/item/borg/upgrade/modkit/lifesteal
	name = "lifesteal crystal"
	desc = "Causes kinetic accelerator shots to slightly heal the firer on striking a living target."
	icon_state = "modkit_crystal"
	modifier = 2.5 //Not a very effective method of healing.
	cost = 20
	var/static/list/damage_heal_order = list(BRUTE, BURN, OXY)

/obj/item/borg/upgrade/modkit/lifesteal/projectile_prehit(obj/item/projectile/kinetic/K, atom/target, obj/item/gun/energy/kinetic_accelerator/KA)
	if(isliving(target) && isliving(K.firer))
		var/mob/living/L = target
		if(L.stat == DEAD)
			return
		L = K.firer
		L.heal_ordered_damage(modifier, damage_heal_order)
*/

/obj/item/borg/upgrade/modkit/resonator_blasts
	name = "resonator blast"
	desc = "Causes kinetic accelerator shots to leave and detonate resonator blasts."
	denied_type = /obj/item/borg/upgrade/modkit/resonator_blasts
	cost = 30
	modifier = 0.25 //A bonus 15 damage if you burst the field on a target, 60 if you lure them into it.

/obj/item/borg/upgrade/modkit/resonator_blasts/projectile_strike(obj/item/projectile/kinetic/K, turf/target_turf, atom/target, obj/item/gun/energy/kinetic_accelerator/KA)
	if(target_turf && !ismineralturf(target_turf)) //Don't make fields on mineral turfs.
		var/obj/effect/resonance/R = locate(/obj/effect/resonance) in target_turf
		if(R)
			R.resonance_damage *= modifier
			R.burst()
			return
		new /obj/effect/resonance(target_turf, K.firer, 30)

/*
/obj/item/borg/upgrade/modkit/bounty
	name = "death syphon"
	desc = "Killing or assisting in killing a creature permanently increases your damage against that type of creature."
	denied_type = /obj/item/borg/upgrade/modkit/bounty
	modifier = 1.25
	cost = 30
	var/maximum_bounty = 25
	var/list/bounties_reaped = list()

/obj/item/borg/upgrade/modkit/bounty/projectile_prehit(obj/item/projectile/kinetic/K, atom/target, obj/item/gun/energy/kinetic_accelerator/KA)
	if(isliving(target))
		var/mob/living/L = target
		var/list/existing_marks = L.has_status_effect_list(STATUS_EFFECT_SYPHONMARK)
		for(var/i in existing_marks)
			var/datum/status_effect/syphon_mark/SM = i
			if(SM.reward_target == src) //we want to allow multiple people with bounty modkits to use them, but we need to replace our own marks so we don't multi-reward
				SM.reward_target = null
				qdel(SM)
		L.apply_status_effect(STATUS_EFFECT_SYPHONMARK, src)

/obj/item/borg/upgrade/modkit/bounty/projectile_strike(obj/item/projectile/kinetic/K, turf/target_turf, atom/target, obj/item/gun/energy/kinetic_accelerator/KA)
	if(isliving(target))
		var/mob/living/L = target
		if(bounties_reaped[L.type])
			var/kill_modifier = 1
			if(K.pressure_decrease_active)
				kill_modifier *= K.pressure_decrease
			var/armor = L.run_armor_check(K.def_zone, K.flag, null, null, K.armour_penetration)
			L.apply_damage(bounties_reaped[L.type]*kill_modifier, K.damage_type, K.def_zone, armor)

/obj/item/borg/upgrade/modkit/bounty/proc/get_kill(mob/living/L)
	var/bonus_mod = 1
	if(ismegafauna(L)) //megafauna reward
		bonus_mod = 4
	if(!bounties_reaped[L.type])
		bounties_reaped[L.type] = min(modifier * bonus_mod, maximum_bounty)
	else
		bounties_reaped[L.type] = min(bounties_reaped[L.type] + (modifier * bonus_mod), maximum_bounty)
*/

//Indoors
/obj/item/borg/upgrade/modkit/indoors
	name = "hacked pressure modulator"
	desc = "A remarkably illegal modification kit that increases the damage a kinetic accelerator does in pressurized environments."
	modifier = 2
	denied_type = /obj/item/borg/upgrade/modkit/indoors
	maximum_of_type = 2
	cost = 35

/obj/item/borg/upgrade/modkit/indoors/modify_projectile(obj/item/projectile/kinetic/K)
	K.pressure_decrease *= modifier

/obj/item/borg/upgrade/modkit/offsite
	name = "offsite pressure modulator"
	desc = "A non-standard modification kit that increases the damage a kinetic accelerator does in pressurized environments, \
	in exchange for nullifying any projected forces while on or in an associated facility."
	denied_type = /obj/item/borg/upgrade/modkit/heater
	maximum_of_type = 1
	cost = 35

/obj/item/borg/upgrade/modkit/offsite/modify_projectile(obj/item/projectile/kinetic/K)
	K.environment = KA_ENVIRO_TYPE_OFFSITE

// Atmospheric
/obj/item/borg/upgrade/modkit/heater
	name = "temperature modulator"
	desc = "A remarkably unusual modification kit that makes kinetic accelerators more usable in hot, overpressurized environments, \
	in exchange for making them weak elsewhere, like the cold or in space."
	denied_type = /obj/item/borg/upgrade/modkit/offsite
	maximum_of_type = 1
	cost = 10

/obj/item/borg/upgrade/modkit/heater/modify_projectile(obj/item/projectile/kinetic/K)
	K.environment = KA_ENVIRO_TYPE_HOT

//Trigger Guard

/*
/obj/item/borg/upgrade/modkit/trigger_guard
	name = "modified trigger guard"
	desc = "Allows creatures normally incapable of firing guns to operate the weapon when installed."
	cost = 20
	denied_type = /obj/item/borg/upgrade/modkit/trigger_guard

/obj/item/borg/upgrade/modkit/trigger_guard/install(obj/item/gun/energy/kinetic_accelerator/KA, mob/user)
	. = ..()
	if(.)
		KA.trigger_guard = TRIGGER_GUARD_ALLOW_ALL

/obj/item/borg/upgrade/modkit/trigger_guard/uninstall(obj/item/gun/energy/kinetic_accelerator/KA)
	KA.trigger_guard = TRIGGER_GUARD_NORMAL
	..()
*/

//Cosmetic

/obj/item/borg/upgrade/modkit/chassis_mod
	name = "super chassis"
	desc = "Makes your KA yellow. All the fun of having a more powerful KA without actually having a more powerful KA."
	cost = 0
	denied_type = /obj/item/borg/upgrade/modkit/chassis_mod
	var/chassis_icon = "kineticgun_u"
	var/chassis_name = "super-kinetic accelerator"

/obj/item/borg/upgrade/modkit/chassis_mod/install(obj/item/gun/energy/kinetic_accelerator/KA, mob/user)
	. = ..()
	if(.)
		KA.icon_state = chassis_icon
		KA.name = chassis_name

/obj/item/borg/upgrade/modkit/chassis_mod/uninstall(obj/item/gun/energy/kinetic_accelerator/KA)
	KA.icon_state = initial(KA.icon_state)
	KA.name = initial(KA.name)
	..()

/obj/item/borg/upgrade/modkit/chassis_mod/orange
	name = "hyper chassis"
	desc = "Makes your KA orange. All the fun of having explosive blasts without actually having explosive blasts."
	chassis_icon = "kineticgun_h"
	chassis_name = "hyper-kinetic accelerator"

/obj/item/borg/upgrade/modkit/tracer
	name = "white tracer bolts"
	desc = "Causes kinetic accelerator bolts to have a white tracer trail and explosion."
	cost = 0
	denied_type = /obj/item/borg/upgrade/modkit/tracer
	var/bolt_color = "#FFFFFF"

/obj/item/borg/upgrade/modkit/tracer/modify_projectile(obj/item/projectile/kinetic/K)
	K.icon_state = "ka_tracer"
	K.color = bolt_color

/obj/item/borg/upgrade/modkit/tracer/adjustable
	name = "adjustable tracer bolts"
	desc = "Causes kinetic accelerator bolts to have an adjustable-colored tracer trail and explosion. Use in-hand to change color."

/obj/item/borg/upgrade/modkit/tracer/adjustable/attack_self(mob/user)
	bolt_color = tgui_color_picker(user,"","Choose Color",bolt_color)

#undef KA_ENVIRO_TYPE_COLD
#undef KA_ENVIRO_TYPE_HOT
#undef KA_ENVIRO_TYPE_OFFSITE
