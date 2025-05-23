//Procedures in this file: Facial reconstruction surgery
//////////////////////////////////////////////////////////////////
//						FACE SURGERY							//
//////////////////////////////////////////////////////////////////

/datum/surgery_step/face
	surgery_name = "Facial Surgery"
	priority = 2
	req_open = 0
	can_infect = 0

/datum/surgery_step/face/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	if (!hasorgans(target))
		return 0
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	if (!affected || (affected.robotic >= ORGAN_ROBOT))
		return 0
	if(coverage_check(user, target, affected, tool))
		return 0
	return target_zone == O_MOUTH

///////////////////////////////////////////////////////////////
// Face Opening Surgery
///////////////////////////////////////////////////////////////

/datum/surgery_step/generic/cut_face
	surgery_name = "Cut Face"
	allowed_tools = list(
	/obj/item/surgical/scalpel = 100,		\
	/obj/item/material/knife = 75,	\
	/obj/item/material/shard = 50, 		\
	)

	min_duration = 90
	max_duration = 110

/datum/surgery_step/generic/cut_face/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	return ..() && target_zone == O_MOUTH && target.op_stage.face == 0

/datum/surgery_step/generic/cut_face/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(span_filter_notice("[user] starts to cut open [target]'s face and neck with \the [tool]."), \
	span_filter_notice("You start to cut open [target]'s face and neck with \the [tool]."))
	user.balloon_alert_visible("begins to cut open [target]'s face and neck.", "cutting open face and neck.")
	..()

/datum/surgery_step/generic/cut_face/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(span_notice("[user] has cut open [target]'s face and neck with \the [tool].") , \
	span_notice(" You have cut open[target]'s face and neck with \the [tool]."),)
	user.balloon_alert_visible("cuts up [target]'s face and neck.", "face and neck cut open.")
	target.op_stage.face = 1

/datum/surgery_step/generic/cut_face/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_danger("[user]'s hand slips, slicing [target]'s throat with \the [tool]!") , \
	span_danger("Your hand slips, slicing [target]'s throat wth \the [tool]!") )
	user.balloon_alert_visible("slips, slicing [target]'s throat.", "your hand slips, slicing [target]'s throat.")
	affected.createwound(CUT, 60)
	target.AdjustLosebreath(10)

///////////////////////////////////////////////////////////////
// Vocal Cord/Face Repair Surgery
///////////////////////////////////////////////////////////////

/datum/surgery_step/face/mend_vocal
	surgery_name = "Mend Vocal Cords"
	allowed_tools = list(
	/obj/item/surgical/hemostat = 100, 	\
	/obj/item/stack/cable_coil = 75, 	\
	/obj/item/assembly/mousetrap = 10	//I don't know. Don't ask me. But I'm leaving it because hilarity.
	)

	min_duration = 70
	max_duration = 90

/datum/surgery_step/face/mend_vocal/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	return ..() && target.op_stage.face == 1

/datum/surgery_step/face/mend_vocal/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(span_filter_notice("[user] starts mending [target]'s vocal cords with \the [tool]."), \
	span_filter_notice("You start mending [target]'s vocal cords with \the [tool]."))
	user.balloon_alert_visible("starts mending [target]'s vocal cords.", "mending vocal cords.")
	..()

/datum/surgery_step/face/mend_vocal/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(span_notice("[user] mends [target]'s vocal cords with \the [tool]."), \
	span_notice("You mend [target]'s vocal cords with \the [tool]."))
	user.balloon_alert_visible("[target]'s vocal cords mended", "vocal cords mended")
	target.op_stage.face = 2

/datum/surgery_step/face/mend_vocal/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(span_danger("[user]'s hand slips, clamping [target]'s trachea shut for a moment with \the [tool]!"), \
	span_danger("Your hand slips, clamping [target]'s trachea shut for a moment with \the [tool]!"))
	user.balloon_alert_visible("slips, clamping [target]'s trachea", "your hand slips, clamping [target]'s trachea.")
	target.AdjustLosebreath(10)

///////////////////////////////////////////////////////////////
// Face Fixing Surgery
///////////////////////////////////////////////////////////////

/datum/surgery_step/face/fix_face
	surgery_name = "Fix Face"
	allowed_tools = list(
		/obj/item/surgical/retractor = 100, 	\
		/obj/item/material/kitchen/utensil/fork = 75
	)

	allowed_procs = list(IS_CROWBAR = 55)

	min_duration = 80
	max_duration = 100

/datum/surgery_step/face/fix_face/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	return ..() && target.op_stage.face == 2

/datum/surgery_step/face/fix_face/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(span_filter_notice("[user] starts pulling the skin on [target]'s face back in place with \the [tool]."), \
	span_filter_notice("You start pulling the skin on [target]'s face back in place with \the [tool]."))
	user.balloon_alert_visible("starts pulling the skin on [target]'s face back in place.", "pulling the skin back in place.")
	..()

/datum/surgery_step/face/fix_face/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(span_notice("[user] pulls the skin on [target]'s face back in place with \the [tool]."),	\
	span_notice("You pull the skin on [target]'s face back in place with \the [tool]."))
	user.balloon_alert_visible("pulls the skin on [target]'s face back in place", "skin pulled back in place.")
	target.op_stage.face = 3

/datum/surgery_step/face/fix_face/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_danger("[user]'s hand slips, tearing skin on [target]'s face with \the [tool]!"), \
	span_danger("Your hand slips, tearing skin on [target]'s face with \the [tool]!"))
	user.balloon_alert_visible("slips, tearing skin on [target]'s face.", "your hand slips, tearing skin on the face.")
	target.apply_damage(10, BRUTE, affected, sharp = TRUE, sharp = TRUE)

///////////////////////////////////////////////////////////////
// Face Cauterizing Surgery
///////////////////////////////////////////////////////////////

/datum/surgery_step/face/cauterize
	surgery_name = "Cauterize Face"
	allowed_tools = list(
	/obj/item/surgical/cautery = 100,			\
	/obj/item/clothing/mask/smokable/cigarette = 75,	\
	/obj/item/flame/lighter = 50,			\
	/obj/item/weldingtool = 25
	)

	min_duration = 70
	max_duration = 100

/datum/surgery_step/face/cauterize/can_use(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	return ..() && target.op_stage.face > 0

/datum/surgery_step/face/cauterize/begin_step(mob/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	user.visible_message(span_notice("[user] is beginning to cauterize the incision on [target]'s face and neck with \the [tool].") , \
	span_notice("You are beginning to cauterize the incision on [target]'s face and neck with \the [tool]."))
	user.balloon_alert_visible("begins to cauterize the incision on [target]'s face and neck", "cauterizing the incision on face and neck.")
	..()

/datum/surgery_step/face/cauterize/end_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_notice("[user] cauterizes the incision on [target]'s face and neck with \the [tool]."), \
	span_notice("You cauterize the incision on [target]'s face and neck with \the [tool]."))
	user.balloon_alert_visible("cauterizes the incision on [target]'s face and neck", "cauterized the incision on the face and neck.")
	affected.open = 0
	affected.status &= ~ORGAN_BLEEDING
	if (target.op_stage.face == 3)
		var/obj/item/organ/external/head/h = affected
		h.disfigured = 0
	target.op_stage.face = 0

/datum/surgery_step/face/cauterize/fail_step(mob/living/user, mob/living/carbon/human/target, target_zone, obj/item/tool)
	var/obj/item/organ/external/affected = target.get_organ(target_zone)
	user.visible_message(span_danger("[user]'s hand slips, leaving a small burn on [target]'s face with \the [tool]!"), \
	span_danger("Your hand slips, leaving a small burn on [target]'s face with \the [tool]!"))
	user.balloon_alert_visible("slips, leaving a small burn on the face.", "your hand slips, leaving a small burn on the face.")
	target.apply_damage(4, BURN, affected)
