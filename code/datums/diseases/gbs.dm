/datum/disease/gbs
	name = "GBS"
	medical_name = "Guillain-Barré Syndrome"
	desc = "If left untreated death will occur."
	max_stages = 5
	spread_text = "On contact"
	spread_flags = DISEASE_SPREAD_CONTACT | DISEASE_SPREAD_BLOOD | DISEASE_SPREAD_FLUIDS
	cure_text = REAGENT_ADRANOL + " & " + REAGENT_SULFUR
	cures = list(REAGENT_ID_ADRANOL, REAGENT_ID_SULFUR)
	cure_chance = 15
	agent = "Gravitokinetic Bipotential SADS+"
	viable_mobtypes = list(/mob/living/carbon/human)
	danger = DISEASE_PANDEMIC
	disease_flags = CAN_NOT_POPULATE

/datum/disease/gbs/stage_act()
	if(!..())
		return FALSE
	switch(stage)
		if(2)
			if(prob(45))
				affected_mob.adjustToxLoss(5)
			if(prob(1))
				affected_mob.emote("sneeze")
		if(3)
			if(prob(5))
				affected_mob.emote("cough")
			else if(prob(5))
				affected_mob.emote("gasp")
			if(prob(10))
				to_chat(affected_mob, span_danger("You're starting to feel very weak..."))
		if(4)
			if(prob(10))
				affected_mob.emote("cough")
			affected_mob.adjustToxLoss(5)
		if(5)
			to_chat(affected_mob, span_danger("Your body feels as if it's trying to rip itself open..."))
			if(prob(50))
				affected_mob.delayed_gib()
		else
			return

/datum/disease/gbs/curable
	name = "Non-Contagious GBS"
	medical_name = "Non-Contagious Guillain-Barré Syndrome"
	desc = "If left untreated death will occur."
	stage_prob = 5
	spread_text = "Non-contagious"
	spread_flags = DISEASE_SPREAD_NON_CONTAGIOUS
	cure_text = REAGENT_CRYOXADONE
	cures = list(REAGENT_ID_CRYOXADONE)
	cure_chance = 10
	agent = "gibbis"
	disease_flags = CURABLE|CAN_NOT_POPULATE
