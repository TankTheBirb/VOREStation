/datum/tgs_chat_command/status
	name = "status"
	help_text = "Shows the current production server status"
	admin_only = FALSE

/datum/tgs_chat_command/status/Run(datum/tgs_chat_user/sender, params)
	var/counts = 0
	var/afks = 0
	var/active = 0
	var/bellied = 0
	var/map_name = "n/a"
	if(using_map && using_map.full_name)
		map_name = using_map.full_name

	for(var/client/C in GLOB.clients)
		counts++
		if(!(isnewplayer(C.mob) || istype(C.mob, /mob/observer)))
			if(C.mob && isbelly(C.mob.loc))
				bellied++
		if(C.is_afk())
			afks++
		else
			active++

	return "Current server status:\n**Web Manifest:** <https://vore-station.net/manifest.php>\n**Players:** [counts]\n**Active:** [active]\n**AFK:** [afks]\n**Bellied:** [bellied]\n\n**Round Duration:** [roundduration2text()]\n**Current Map:** [map_name]"

/datum/tgs_chat_command/parsetest
	name = "parsetest"
	help_text = "Shows the current production server status"
	admin_only = FALSE

/datum/tgs_chat_command/parsetest/Run(datum/tgs_chat_user/sender, params)
	return "```You passed:[params]```"

/datum/tgs_chat_command/staffwho
	name = "staffwho"
	help_text = "Shows the current online staff count"
	admin_only = TRUE

/datum/tgs_chat_command/staffwho/Run(datum/tgs_chat_user/sender, params)
	var/message = "Current online staff:\n"

	var/list/admin_keys = list()
	var/list/mod_keys = list()
	var/list/dev_keys = list()
	var/list/other_keys = list()

	var/count = 0

	for(var/client/C in GLOB.admins)
		count++
		var/keymsg = "[C.key]"
		if(C.is_afk())
			keymsg += " (AFK)"
		else if(C.holder.fakekey)
			keymsg += " (Stealth)"
		else if(isobserver(C.mob))
			keymsg += " (Ghost)"
		else if(isnewplayer(C.mob))
			keymsg += " (Lobby)"
		else
			keymsg += " (Ingame)"

		if(check_rights_for(C, R_ADMIN) && check_rights_for(C, R_BAN)) // R_ADMIN and R_BAN apparently an admin makes
			admin_keys += keymsg

		else if(check_rights_for(C, R_ADMIN) && !(check_rights_for(C, R_SERVER))) // R_ADMIN but not R_SERVER makes a moderator
			mod_keys += keymsg

		else if(check_rights_for(C, R_SERVER)) // R_SERVER makes a dev
			dev_keys += keymsg

		else // No R_ADMIN&&R_BAN, R_ADMIN!R_BAN, R_SERVER, must be a GM or something
			other_keys += keymsg

	var/admin_msg = english_list(admin_keys, "-None-")
	var/mod_msg = english_list(mod_keys, "-None-")
	var/dev_msg = english_list(dev_keys, "-None-")
	var/other_msg = english_list(other_keys, "-None-")

	message += "**Admins:** [admin_msg]\n**Mods/GMs:** [mod_msg]\n**Devs:** [dev_msg]\n**Other:** [other_msg]\n**Total:** [count] online"
	return message

GLOBAL_LIST_EMPTY(pending_discord_registrations)
/datum/tgs_chat_command/register
	name = "register"
	help_text = "Registers your chat username with your Byond username"
	admin_only = FALSE

/datum/tgs_chat_command/register/Run(datum/tgs_chat_user/sender, params)
	// Try to find if that ID is registered to someone already
	var/sql_discord = sql_sanitize_text(sender.id)
	var/datum/db_query/query = SSdbcore.NewQuery("SELECT discord_id FROM erro_player WHERE discord_id = '[sql_discord]'")
	query.Execute()
	if(query.NextRow())
		qdel(query)
		return "[sender.friendly_name], your Discord ID is already registered to a Byond username. Please contact an administrator if you changed your Byond username or Discord ID."
	qdel(query)
	var/key_to_find = "[ckey(params)]"

	// They didn't provide anything worth looking up.
	if(!length(key_to_find))
		return "[sender.friendly_name], you need to provide your Byond username at the end of the command. It can be in 'key' format (with spaces and characters) or 'ckey' format (without spaces or special characters)."

	// Try to find their client.
	var/client/user
	for(var/client/C in GLOB.clients)
		if(C.ckey == key_to_find)
			user = C
			break

	// Couldn't find them logged in.
	if(!user)
		return "[sender.friendly_name], I couldn't find a logged-in user with the username of '[key_to_find]', which is what you provided after conversion to Byond's ckey format. Please connect to the game server and try again."

	var/sql_ckey = sql_sanitize_text(key_to_find)
	query = SSdbcore.NewQuery("SELECT discord_id FROM erro_player WHERE ckey = '[sql_ckey]'")
	query.Execute()

	// We somehow found their client, BUT they don't exist in the database
	if(!query.NextRow())
		qdel(query)
		return "[sender.friendly_name], the server's database is either not responding or there's no evidence you've ever logged in. Please contact an administrator."

	// We found them in the database, AND they already have a discord ID assigned
	if(query.item[1])
		qdel(query)
		return "[sender.friendly_name], it appears you've already registered your chat and game IDs. If you've changed game or chat usernames, please contact an administrator for help."
	qdel(query)
	// Okay. We found them, they're in the DB, and they have no discord ID set.
	var/message = span_notice("A request has been sent from Discord to validate your Byond username, by '[sender.friendly_name]' in '[sender.channel.friendly_name]'") + "\
	<br>" + span_warning("If you did not send this request, do not click the link below, and do notify an administrator in-game or on Discord ASAP.") + "\
	<br><a href='byond://?src=\ref[user];discord_reg=[html_encode(sender.id)]'>Click Here</a> if you authorized this registration attempt. This link is valid for 10 minutes."
	to_chat(user, message)

	// To stifle href hacking
	GLOB.pending_discord_registrations.len++
	GLOB.pending_discord_registrations[GLOB.pending_discord_registrations.len] = list("ckey" = key_to_find, "id" = sender.id, "time" = world.realtime)

	return "[sender.friendly_name], I've sent you a message in-game. Please verify your username there to complete your registration within 10 minutes."
