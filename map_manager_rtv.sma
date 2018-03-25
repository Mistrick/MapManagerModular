#include <amxmodx>
#include <map_manager>
#include <map_manager_scheduler>

#if AMXX_VERSION_NUM < 183
#include <colorchat>
#endif

#define PLUGIN "Map Manager: Rtv"
#define VERSION "0.0.1"
#define AUTHOR "Mistrick"

#pragma semicolon 1

#define get_num(%0) get_pcvar_num(g_pCvars[%0])

enum Cvars {
	MODE,
	PERCENT,
	PLAYERS,
	DELAY,
	CHANGE_TYPE,
	ALLOW_EXTEND
};

enum {
	MODE_PERCENTS,
	MODE_PLAYERS
};

new g_pCvars[Cvars];
new g_iMapStartTime;
new bool:g_bVoted[33];
new g_iVotes;

new PREFIX[32];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvars[MODE] = register_cvar("mapm_rtv_mode", "0"); // 0 - percents, 1 - players
	g_pCvars[PERCENT] = register_cvar("mapm_rtv_percent", "60");
	g_pCvars[PLAYERS] = register_cvar("mapm_rtv_players", "5");
	g_pCvars[DELAY] = register_cvar("mapm_rtv_delay", "0"); // minutes
	// g_pCvars[CHANGE_TYPE] = register_cvar("mapm_rtv_change_type", "1"); // 0 - after vote, 1 - in round end
	g_pCvars[ALLOW_EXTEND] = register_cvar("mapm_rtv_allow_extend", "0"); // 0 - disable, 1 - enable

	register_clcmd("say rtv", "ClCmd_Rtv");
	register_clcmd("say /rtv", "ClCmd_Rtv");

	// reset it with sv_restart?
	g_iMapStartTime = get_systime();

	mapm_get_prefix(PREFIX, charsmax(PREFIX));
}
public client_disconnect(id)
{
	if(g_bVoted[id]) {
		g_bVoted[id] = false;
		g_iVotes--;
	}
}
public ClCmd_Rtv(id)
{
	if(is_vote_started() || is_vote_finished()) {
		// add msg?
		return PLUGIN_HANDLED;
	}

	new delay = get_num(DELAY) * 60 - (get_systime() - g_iMapStartTime);
	if(delay > 0) {
		client_print_color(id, print_team_default, "%s^1 %L", PREFIX, id, "MAPM_RTV_DELAY", delay / 60, delay % 60);
		return PLUGIN_HANDLED;
	}

	if(!g_bVoted[id]) {
		g_iVotes++;
	}

	new need_votes;
	if(get_num(MODE) == MODE_PERCENTS) {
		need_votes = floatround(get_players_num() * get_num(PERCENT) / 100.0) - g_iVotes;
	} else {
		need_votes = get_num(PLAYERS) - g_iVotes;
	}

	if(need_votes <= 0) {
		map_scheduler_start_vote(VOTE_BY_RTV);
		return PLUGIN_HANDLED;
	}

	if(!g_bVoted[id]) {
		g_bVoted[id] = true;
		new name[32]; get_user_name(id, name, charsmax(name));
		client_print_color(0, print_team_default, "%s^3 %L %L.", PREFIX, LANG_PLAYER, "MAPM_RTV_VOTED", name, need_votes, LANG_PLAYER, "MAPM_VOTES");
	} else {
		client_print_color(id, print_team_default, "%s^1 %L %L.", PREFIX, id, "MAPM_RTV_ALREADY_VOTED", need_votes, id, "MAPM_VOTES");
	}

	return PLUGIN_HANDLED;
}
public mapm_can_be_extended(type)
{
	if(type == VOTE_BY_RTV && !get_num(ALLOW_EXTEND)) {
		return EXTEND_BLOCKED;
	}
	return EXTEND_ALLOWED;
}
