#include <amxmodx>
#include <map_manager>

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
	// TODO: add checks in vote, finished vote
	new delay = get_num(DELAY) * 60 - (get_systime() - g_iMapStartTime);
	if(delay > 0) {
		client_print_color(id, print_team_default, "You can't use rtv, wait %d:%d.", delay / 60, delay % 60);
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
		// TODO: add rtv param for native
		mapm_start_vote(VOTE_BY_RTV);
		return PLUGIN_HANDLED;
	}

	if(!g_bVoted[id]) {
		g_bVoted[id] = true;
		new name[32]; get_user_name(id, name, charsmax(name));
		client_print_color(0, id, "Player ^3%s^1 voted for rtv, remainds votes: %d.", name, need_votes);
	} else {
		client_print_color(id, id, "You already voted, remainds votes: %d.", need_votes);
	}

	return PLUGIN_HANDLED;
}
public mapm_can_be_extended(type)
{
	if(type == VOTE_BY_RTV && !get_num(ALLOW_EXTEND)) {
		return false;
	}
	return true;
}
get_players_num()
{
	new players[32], pnum; get_players(players, pnum, "ch");
	return pnum;
}
