#include <amxmodx>
#include <amxmisc>
#include <map_manager>

#if AMXX_VERSION_NUM < 183
#include <colorchat>
#endif

#define PLUGIN "Map Manager: Scheduler"
#define VERSION "0.0.2"
#define AUTHOR "Mistrick"

#pragma semicolon 1

#define get_num(%0) get_pcvar_num(g_pCvars[%0])
#define set_num(%0,%1) set_pcvar_num(g_pCvars[%0],%1)
#define get_float(%0) get_pcvar_float(g_pCvars[%0])
#define set_float(%0,%1) set_pcvar_float(g_pCvars[%0],%1)

#define EVENT_SVC_INTERMISSION "30"

enum (+=100) {
	TASK_CHECKTIME,
	TASK_DELAYED_CHANGE
};

enum {
	CHANGE_AFTER_VOTE,
	CHANGE_NEXT_ROUND,
	CHANGE_MAP_END
};

enum Cvars {
	CHANGE_TYPE,
	TIMELEFT_TO_VOTE,
	VOTE_IN_NEW_ROUND,
	LAST_ROUND,
	SECOND_VOTE,
	SECOND_VOTE_PERCENT,
	EXTENDED_TYPE,
	EXTENDED_MAX,
	EXTENDED_TIME,
	EXTENDED_ROUNDS,
	MAXROUNDS,
	WINLIMIT,
	TIMELIMIT,
	CHATTIME,
	NEXTMAP
};

new g_pCvars[Cvars];

new bool:g_bVoteInNewRound;
new g_iTeamScore[2];
new Float:g_fOldTimeLimit;
new g_iExtendedNum;
new g_iVoteType;

new g_sSecondVoteMaps[2][MAPNAME_LENGTH];

new PREFIX[32];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvars[CHANGE_TYPE] = register_cvar("mapm_change_type", "1"); // 0 - after end vote, 1 - in round end, 2 - after end map
	g_pCvars[TIMELEFT_TO_VOTE] = register_cvar("mapm_timeleft_to_vote", "2"); // minutes
	g_pCvars[VOTE_IN_NEW_ROUND] = register_cvar("mapm_vote_in_new_round", "0"); // 0 - disable, 1 - enable
	g_pCvars[LAST_ROUND] = register_cvar("mapm_last_round", "0"); // 0 - disable, 1 - enable

	g_pCvars[SECOND_VOTE] = register_cvar("mapm_second_vote", "0"); // 0 - disable, 1 - enable
	g_pCvars[SECOND_VOTE_PERCENT] = register_cvar("mapm_second_vote_percent", "50");

	g_pCvars[EXTENDED_TYPE] = register_cvar("mapm_extended_type", "0"); // 0 - minutes, 1 - rounds
	g_pCvars[EXTENDED_MAX] = register_cvar("mapm_extended_map_max", "3");
	g_pCvars[EXTENDED_TIME] = register_cvar("mapm_extended_time", "15"); // minutes
	g_pCvars[EXTENDED_ROUNDS] = register_cvar("mapm_extended_rounds", "3"); // rounds

	g_pCvars[MAXROUNDS] = get_cvar_pointer("mp_maxrounds");
	g_pCvars[WINLIMIT] = get_cvar_pointer("mp_winlimit");
	g_pCvars[TIMELIMIT] = get_cvar_pointer("mp_timelimit");
	g_pCvars[CHATTIME] = get_cvar_pointer("mp_chattime");

	g_pCvars[NEXTMAP] = register_cvar("amx_nextmap", "", FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY);

	register_concmd("mapm_start_vote", "concmd_startvote", ADMIN_MAP);
	register_concmd("mapm_stop_vote", "concmd_stopvote", ADMIN_MAP);

	register_clcmd("votemap", "clcmd_votemap");

	register_event("TeamScore", "event_teamscore", "a");
	register_event("HLTV", "event_newround", "a", "1=0", "2=0");
	// register_event("TextMsg", "event_restart", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
	register_event(EVENT_SVC_INTERMISSION, "event_intermission", "a");

	set_task(10.0, "task_checktime", TASK_CHECKTIME, .flags = "b");

	mapm_get_prefix(PREFIX, charsmax(PREFIX));
}
public plugin_natives()
{
	register_library("map_manager_scheduler");

	register_native("map_scheduler_start_vote", "native_start_vote");
	register_native("is_vote_will_in_next_round", "native_vote_will_in_next_round");
}
public native_start_vote(plugin, params)
{
	if(g_bVoteInNewRound) {
		return 0;
	}

	enum { arg_type = 1 };
	planning_vote(get_param(arg_type));

	return 1;
}
public native_vote_will_in_next_round(plugin, params)
{
	return g_bVoteInNewRound;
}
public plugin_end()
{
	if(g_fOldTimeLimit > 0.0) {
		set_float(TIMELIMIT, g_fOldTimeLimit);
	}
	restore_limits();
}
restore_limits()
{
	if(g_iExtendedNum) {
		if(get_num(EXTENDED_TYPE) == EXTEND_ROUNDS) {
			new win_limit = get_num(WINLIMIT);
			if(win_limit) {
				set_pcvar_num(g_pCvars[WINLIMIT], win_limit - g_iExtendedNum * get_num(EXTENDED_ROUNDS));
			}
			new max_rounds = get_num(MAXROUNDS);
			if(max_rounds) {
				set_pcvar_num(g_pCvars[MAXROUNDS], max_rounds - g_iExtendedNum * get_num(EXTENDED_ROUNDS));
			}
		} else {
			new Float:timelimit = get_float(TIMELIMIT);
			if(timelimit) {
				new Float:restored_value = timelimit - float(g_iExtendedNum * get_num(EXTENDED_TIME));
				set_float(TIMELIMIT, restored_value);
			}
		}
		g_iExtendedNum = 0;
	}
}
public concmd_startvote(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	// TODO: add logging
	planning_vote(VOTE_BY_CMD);

	return PLUGIN_HANDLED;
}
public concmd_stopvote(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	// TODO: add logging
	mapm_stop_vote();

	if(g_bVoteInNewRound) {
		g_bVoteInNewRound = false;

		if(g_fOldTimeLimit > 0.0) {
			set_float(TIMELIMIT, g_fOldTimeLimit);
		}
	}

	return PLUGIN_HANDLED;
}
public clcmd_votemap()
{
	// Block default vote
	return PLUGIN_HANDLED;
}
public task_checktime()
{
	if(is_vote_started() || is_vote_finished() || get_float(TIMELIMIT) <= 0.0) {
		return 0;
	}

	new Float:time_to_vote = get_float(TIMELEFT_TO_VOTE);
	
	new timeleft = get_timeleft();
	if(timeleft <= floatround(time_to_vote * 60.0) && get_players_num()) {
		log_amx("SetVoteStart: timeleft %d", timeleft);
		
		planning_vote(VOTE_BY_SCHEDULER);
	}
	
	return 0;
}
public event_teamscore()
{
	new team[2]; read_data(1, team, charsmax(team));
	g_iTeamScore[(team[0] == 'C') ? 0 : 1] = read_data(2);
}
public event_newround()
{
	new max_rounds = get_num(MAXROUNDS);
	if(!is_vote_finished() && max_rounds && (g_iTeamScore[0] + g_iTeamScore[1]) >= max_rounds - 2) {
		log_amx("StartVote: maxrounds %d [%d]", max_rounds, g_iTeamScore[0] + g_iTeamScore[1]);
		mapm_start_vote(VOTE_BY_SCHEDULER);
	}
	
	new win_limit = get_num(WINLIMIT) - 2;
	if(!is_vote_finished() && win_limit > 0 && (g_iTeamScore[0] >= win_limit || g_iTeamScore[1] >= win_limit)) {
		log_amx("StartVote: winlimit %d [CT: %d, T: %d]", win_limit, g_iTeamScore[0], g_iTeamScore[1]);
		mapm_start_vote(VOTE_BY_SCHEDULER);
	}

	if(g_bVoteInNewRound && !is_vote_started()) {
		log_amx("StartVote: timeleft %d, new round", get_timeleft());
		mapm_start_vote(g_iVoteType);
	}

	if(is_vote_finished() && (get_num(CHANGE_TYPE) == CHANGE_NEXT_ROUND || get_num(LAST_ROUND))) {
		new nextmap[MAPNAME_LENGTH]; get_pcvar_string(g_pCvars[NEXTMAP], nextmap, charsmax(nextmap));
		client_print_color(0, print_team_default, "%s^1 %L^3 %s^1.", PREFIX, LANG_PLAYER, "MAPM_NEXTMAP", nextmap);
		intermission();
	}
}
/*
public event_restart()
{
	if(get_num(RESTORE_MAP_LIMITS)) {
		restore_limits();
	}
}
*/
public event_intermission()
{
	if(task_exists(TASK_DELAYED_CHANGE)) {
		log_amx("Double intermission, how?");
		return;
	}
	new Float:chattime = get_float(CHATTIME);
	set_float(CHATTIME, chattime + 1.0);
	set_task(chattime, "delayed_change", TASK_DELAYED_CHANGE);
}
public delayed_change()
{
	new nextmap[MAPNAME_LENGTH]; get_pcvar_string(g_pCvars[NEXTMAP], nextmap, charsmax(nextmap));
	set_float(CHATTIME, get_float(CHATTIME) - 1.0);
	server_cmd("changelevel %s", nextmap);
}
planning_vote(type)
{
	g_iVoteType = type;
	if(get_num(VOTE_IN_NEW_ROUND)) {
		g_bVoteInNewRound = true;

		g_fOldTimeLimit = get_float(TIMELIMIT);
		if(g_fOldTimeLimit > 0.0) {
			set_float(TIMELIMIT, 0.0);
		}

		client_print_color(0, print_team_default, "%s^1 %L", PREFIX, LANG_PLAYER, "MAPM_VOTE_WILL_BEGIN");
		server_print("SetVoteStart: vote in new round");
	} else {
		mapm_start_vote(type);
	}
}
public mapm_can_be_extended(type)
{
	if(type == VOTE_BY_SCHEDULER_SECOND) {
		return EXTEND_BLOCKED;
	}
	if(g_iExtendedNum >= get_num(EXTENDED_MAX)) {
		return EXTEND_BLOCKED;
	}
	return EXTEND_ALLOWED;
}
public mapm_prepare_votelist(type)
{
	if(type != VOTE_BY_SCHEDULER_SECOND) {
		return;
	}
	
	// add maps for second vote
	for(new i; i < 2; i++) {
		mapm_push_map_to_votelist(g_sSecondVoteMaps[i], CHECK_IGNORE_MAP_ALLOWED);
	}
	mapm_set_votelist_max_items(2);
}
public mapm_analysis_of_results(type, total_votes)
{
	if(type == VOTE_BY_SCHEDULER_SECOND || !get_num(SECOND_VOTE)) {
		return ALLOW_VOTE;
	}

	new max_items = mapm_get_count_maps_in_vote();
	new map[MAPNAME_LENGTH], votes, max_votes;

	for(new i; i < max_items; i++) {
		votes = mapm_get_voteitem_info(i, map, charsmax(map));
		if(votes > max_votes) {
			copy(g_sSecondVoteMaps[1], charsmax(g_sSecondVoteMaps[]), g_sSecondVoteMaps[0]);
			max_votes = votes;
			copy(g_sSecondVoteMaps[0], charsmax(g_sSecondVoteMaps[]), map);
		}
	}
	
	new percent = total_votes ? floatround(max_votes * 100.0 / total_votes) : 0;

	if(percent > get_num(SECOND_VOTE_PERCENT)) {
		return ALLOW_VOTE;
	}

	// TODO: add ML
	client_print_color(0, print_team_default, "%s^1 Second vote.", PREFIX);
	mapm_start_vote(VOTE_BY_SCHEDULER_SECOND);

	return ABORT_VOTE;
}
public mapm_vote_finished(map[], type, total_votes)
{
	if(g_fOldTimeLimit > 0.0) {
		set_float(TIMELIMIT, g_fOldTimeLimit);
		g_fOldTimeLimit = 0.0;
	}
	g_bVoteInNewRound = false;

	// map extended
	new curmap[MAPNAME_LENGTH]; get_mapname(curmap, charsmax(curmap));
	if(equali(map, curmap)) {
		g_iExtendedNum++;

		new win_limit = get_num(WINLIMIT);
		new max_rounds = get_num(MAXROUNDS);

		if(get_num(EXTENDED_TYPE) == EXTEND_ROUNDS && (win_limit || max_rounds)) {
			new rounds = get_num(EXTENDED_ROUNDS);
			
			if(win_limit > 0) {
				set_num(WINLIMIT, win_limit + rounds);
			}
			if(max_rounds > 0) {
				set_num(MAXROUNDS, max_rounds + rounds);
			}
			
			client_print_color(0, print_team_default, "%s^1 %L %L.", PREFIX, LANG_PLAYER, "MAPM_MAP_EXTEND", rounds, LANG_PLAYER, "MAPM_ROUNDS");
		} else {
			new min = get_num(EXTENDED_TIME);
			
			client_print_color(0, print_team_default, "%s^1 %L %L.", PREFIX, LANG_PLAYER, "MAPM_MAP_EXTEND", min, LANG_PLAYER, "MAPM_MINUTES");
			set_float(TIMELIMIT, get_float(TIMELIMIT) + float(min));
		}
		
		server_print("map extended");
		return 0;
	}

	// change map
	if(!total_votes) {
		client_print_color(0, print_team_default, "%s^1 %L", PREFIX, LANG_PLAYER, "MAPM_NOBODY_VOTE", map);
	} else {
		client_print_color(0, print_team_default, "%s^1 %L^3 %s^1.", PREFIX, LANG_PLAYER, "MAPM_NEXTMAP", map);
	}

	set_pcvar_string(g_pCvars[NEXTMAP], map);

	if(get_num(LAST_ROUND)) {
		// What if timelimit 0?
		g_fOldTimeLimit = get_float(TIMELIMIT);
		set_float(TIMELIMIT, 0.0);
		client_print_color(0, print_team_default, "%s^1 %L", PREFIX, LANG_PLAYER, "MAPM_LASTROUND");
		
		server_print("last round cvar: saved timelimit is %f", g_fOldTimeLimit);
	} else {
		switch(get_num(CHANGE_TYPE)) {
			case CHANGE_NEXT_ROUND: {
				client_print_color(0, print_team_default, "%s^1 %L", PREFIX, LANG_PLAYER, "MAPM_MAP_CHANGE_NEXTROUND");
			}
			case CHANGE_AFTER_VOTE: {
				client_print_color(0, print_team_default, "%s^1 %L^1 %L.", PREFIX, LANG_PLAYER, "MAPM_MAP_CHANGE", get_num(CHATTIME), LANG_PLAYER, "MAPM_SECONDS");
				intermission();
			}
		}
	}

	return 0;
}
