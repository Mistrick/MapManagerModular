#include <amxmodx>
#include <map_manager>
#include <map_manager_scheduler>

#if AMXX_VERSION_NUM < 183
#include <colorchat>
#endif

#define PLUGIN "Map Manager: Informer"
#define VERSION "0.0.2"
#define AUTHOR "Mistrick"

#pragma semicolon 1

#define get_num(%0) get_pcvar_num(g_pCvars[%0])

enum Cvars {
	TIMELIMIT,
	WINLIMIT,
	MAXROUNDS,
	NEXTMAP,
	EXTENDED_TYPE
};

new g_pCvars[Cvars];

new g_iTeamScore[2];
new g_szCurMap[MAPNAME_LENGTH];
new PREFIX[32];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say timeleft", "clcmd_timeleft");
	register_clcmd("say thetime", "clcmd_thetime");
	register_clcmd("say nextmap", "clcmd_nextmap");
	register_clcmd("say currentmap", "clcmd_currentmap");

	register_event("TeamScore", "event_teamscore", "a");

	get_mapname(g_szCurMap, charsmax(g_szCurMap));
	mapm_get_prefix(PREFIX, charsmax(PREFIX));
}
public plugin_cfg()
{
	g_pCvars[TIMELIMIT] = get_cvar_pointer("mp_timelimit");
	g_pCvars[WINLIMIT] = get_cvar_pointer("mp_winlimit");
	g_pCvars[MAXROUNDS] = get_cvar_pointer("mp_maxrounds");
	g_pCvars[NEXTMAP] = get_cvar_pointer("amx_nextmap");
	g_pCvars[EXTENDED_TYPE] = get_cvar_pointer("mapm_extended_type");
}
public event_teamscore()
{
	new team[2]; read_data(1, team, charsmax(team));
	g_iTeamScore[(team[0] == 'C') ? 0 : 1] = read_data(2);
}
public clcmd_timeleft(id)
{
	new win_limit = get_num(WINLIMIT);
	new max_rounds = get_num(MAXROUNDS);
	
	if((win_limit || max_rounds) && get_num(EXTENDED_TYPE) == EXTEND_ROUNDS) {
		new text[128], len;
		len = formatex(text, charsmax(text), "%L ", LANG_PLAYER, "MAPM_TIME_TO_END");
		if(win_limit) {
			new left_wins = win_limit - max(g_iTeamScore[0], g_iTeamScore[1]);
			// TODO: add to ML MAPM_WINS
			len += formatex(text[len], charsmax(text) - len, "%d %L", left_wins, LANG_PLAYER, "MAPM_WINS");
		}
		if(win_limit && max_rounds) {
			len += formatex(text[len], charsmax(text) - len, " %L ", LANG_PLAYER, "MAPM_TIMELEFT_OR");
		}
		if(max_rounds) {
			new left_rounds = max_rounds - g_iTeamScore[0] - g_iTeamScore[1];
			// TODO: add to ML MAPM_ROUNDS
			len += formatex(text[len], charsmax(text) - len, "%d %L", left_rounds, LANG_PLAYER, "MAPM_ROUNDS");
		}
		client_print_color(0, print_team_default, "%s^1 %s.", PREFIX, text);
	} else {
		if (get_num(TIMELIMIT)) {
			new a = get_timeleft();
			client_print_color(0, id, "%s^1 %L:^3 %d:%02d", PREFIX, LANG_PLAYER, "MAPM_TIME_TO_END", (a / 60), (a % 60));
		} else {
			if(is_vote_will_in_next_round()) {
				// TODO: add ML
				client_print_color(0, print_team_default, "%s^1 Wait vote in next round.", PREFIX);
			} else {
				client_print_color(0, print_team_default, "%s^1 %L", PREFIX, LANG_PLAYER, "MAPM_NO_TIMELIMIT");
			}
		}
	}
}
public clcmd_thetime(id)
{
	new curtime[64]; get_time("%Y/%m/%d - %H:%M:%S", curtime, charsmax(curtime));
	client_print_color(0, print_team_default, "%s^3 %L", PREFIX, LANG_PLAYER, "MAPM_THETIME", curtime);
}
public clcmd_nextmap(id)
{
	if(is_vote_finished()) {
		new map[MAPNAME_LENGTH]; get_pcvar_string(g_pCvars[NEXTMAP], map, charsmax(map));
		client_print_color(0, id, "%s^1 %L ^3%s^1.", PREFIX, LANG_PLAYER, "MAPM_NEXTMAP", map);
	} else {
		client_print_color(0, id, "%s^1 %L ^3%L^1.", PREFIX, LANG_PLAYER, "MAPM_NEXTMAP", LANG_PLAYER, "MAPM_NOT_SELECTED");
	}
}
public clcmd_currentmap(id)
{
	client_print_color(0, id, "%s^1 %L", PREFIX, LANG_PLAYER, "MAPM_CURRENT_MAP", g_szCurMap);
}
