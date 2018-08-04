#include <amxmodx>
#include <map_manager_consts>
#include <map_manager_stocks>

#if AMXX_VERSION_NUM < 183
#include <colorchat>
#endif

#define PLUGIN "Map Manager: Core"
#define VERSION "3.0.0-Beta-5"
#define AUTHOR "Mistrick"

#pragma semicolon 1

//-----------------------------------------------------//
// Consts
//-----------------------------------------------------//
new const FILE_MAPS[] = "maps.ini";
//-----------------------------------------------------//

#define get_num(%0) get_pcvar_num(g_pCvars[%0])

const NOT_VOTED = -1;

enum (+=100) {
	TASK_PREPARE_VOTE = 100,
	TASK_VOTE_TIME
};

enum Forwards {
	MAPLIST_LOADED,
	CAN_BE_IN_VOTELIST,
	CAN_BE_EXTENDED,
	PREPARE_VOTELIST,
	VOTE_STARTED,
	VOTE_CANCELED,
	ANALYSIS_OF_RESULTS,
	VOTE_FINISHED,
	COUNTDOWN
};

enum {
	SHOW_DISABLED,
	SHOW_MENU,
	SHOW_HUD
};

enum Cvars {
	PREFIX,
	VOTELIST_SIZE,
	SHOW_RESULT_TYPE,
	SHOW_SELECTS,
	RANDOM_NUMS,
	PREPARE_TIME,
	VOTE_TIME,
	VOTE_ITEM_OFFSET
};

new g_pCvars[Cvars];

new g_iOffset;
new g_iVoteItems;
new g_sVoteList[MAX_VOTELIST_SIZE + 1][MAPNAME_LENGTH];
new g_iVotes[MAX_VOTELIST_SIZE + 1];
new g_iTotalVotes;
new g_iVoted[33];

new g_hForwards[Forwards];

new Array:g_aMapsList;

new g_iShowType;
new g_bShowSelects;
new g_iTimer;
new g_bCanExtend;
new g_iMaxItems;
new g_iCurMap;

new g_iRandomNums[MAX_VOTELIST_SIZE + 1];

new g_iVoteType;
new bool:g_bVoteStarted;
new bool:g_bVoteFinished;

new g_sCurMap[MAPNAME_LENGTH];
new g_sPrefix[48];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_cvar("mapm_version", VERSION, FCVAR_SERVER | FCVAR_SPONLY);

	g_pCvars[PREFIX] = register_cvar("mapm_prefix", "^4[MapManager]");
	g_pCvars[VOTELIST_SIZE] = register_cvar("mapm_votelist_size", "5");
	g_pCvars[SHOW_RESULT_TYPE] = register_cvar("mapm_show_result_type", "1"); //0 - disable, 1 - menu, 2 - hud
	g_pCvars[SHOW_SELECTS] = register_cvar("mapm_show_selects", "1"); // 0 - disable, 1 - all
	g_pCvars[RANDOM_NUMS] = register_cvar("mapm_random_nums", "0"); // 0 - disable, 1 - enable
	g_pCvars[PREPARE_TIME] = register_cvar("mapm_prepare_time", "5"); // seconds
	g_pCvars[VOTE_TIME] = register_cvar("mapm_vote_time", "10"); // seconds
	g_pCvars[VOTE_ITEM_OFFSET] = register_cvar("mapm_vote_item_offset", "0");

	g_hForwards[MAPLIST_LOADED] = CreateMultiForward("mapm_maplist_loaded", ET_IGNORE, FP_CELL);
	g_hForwards[PREPARE_VOTELIST] = CreateMultiForward("mapm_prepare_votelist", ET_IGNORE, FP_CELL);
	g_hForwards[VOTE_STARTED] = CreateMultiForward("mapm_vote_started", ET_IGNORE, FP_CELL);
	g_hForwards[VOTE_CANCELED] = CreateMultiForward("mapm_vote_canceled", ET_IGNORE, FP_CELL);
	g_hForwards[ANALYSIS_OF_RESULTS] = CreateMultiForward("mapm_analysis_of_results", ET_CONTINUE, FP_CELL, FP_CELL);
	g_hForwards[VOTE_FINISHED] = CreateMultiForward("mapm_vote_finished", ET_IGNORE, FP_STRING, FP_CELL, FP_CELL);
	g_hForwards[CAN_BE_IN_VOTELIST] = CreateMultiForward("mapm_can_be_in_votelist", ET_CONTINUE, FP_STRING, FP_CELL, FP_CELL);
	g_hForwards[CAN_BE_EXTENDED] = CreateMultiForward("mapm_can_be_extended", ET_CONTINUE, FP_CELL);
	g_hForwards[COUNTDOWN] = CreateMultiForward("mapm_countdown", ET_IGNORE, FP_CELL, FP_CELL);

	register_menucmd(register_menuid("VoteMenu"), 1023, "votemenu_handler");

	register_dictionary("mapmanager.txt");
}

public plugin_natives()
{
	register_library("map_manager_core");

	register_native("mapm_load_maplist", "native_load_maplist");
	register_native("mapm_load_maplist_to_array", "native_load_maplist_to_array");
	register_native("mapm_get_map_index", "native_get_map_index");
	register_native("mapm_get_prefix", "native_get_prefix");
	register_native("mapm_set_vote_finished", "native_set_vote_finished");
	register_native("mapm_start_vote", "native_start_vote");
	register_native("mapm_stop_vote", "native_stop_vote");
	register_native("mapm_get_votelist_size", "native_get_votelist_size");
	register_native("mapm_set_votelist_max_items", "native_set_votelist_max_items");
	register_native("mapm_push_map_to_votelist", "native_push_map_to_votelist");
	register_native("mapm_get_count_maps_in_vote", "native_get_count_maps_in_vote");
	register_native("mapm_get_voteitem_info", "native_get_voteitem_info");
	register_native("is_vote_started", "native_is_vote_started");
	register_native("is_vote_finished", "native_is_vote_finished");
}
public native_load_maplist(plugin, params)
{
	enum {
		arg_filename = 1,
		arg_clearlist
	};

	if(get_param(arg_clearlist)) {
		ArrayClear(g_aMapsList);
	}

	new filename[256];
	get_string(arg_filename, filename, charsmax(filename));
	load_maplist(g_aMapsList, filename);
}
public native_load_maplist_to_array(plugin, params)
{
	enum {
		arg_array = 1,
		arg_filename
	};

	new filename[256];
	get_string(arg_filename, filename, charsmax(filename));

	return load_maplist(Array:get_param(arg_array), filename, true);
}
public native_get_map_index(plugin, params)
{
	enum { arg_map = 1 };
	new map[MAPNAME_LENGTH]; get_string(arg_map, map, charsmax(map));
	return get_map_index(g_aMapsList, map);
}
public native_get_prefix(plugin, params)
{
	enum {
		arg_prefix = 1,
		arg_len
	};
	set_string(arg_prefix, g_sPrefix, get_param(arg_len));
}
public native_set_vote_finished(plugin, params)
{
	enum { arg_value = 1 };
	g_bVoteFinished = bool:get_param(arg_value);
}
public native_start_vote(plugin, params)
{
	enum { arg_type = 1 };
	return prepare_vote(get_param(arg_type));
}
public native_stop_vote(plugin, params)
{
	stop_vote();
}
public native_get_votelist_size(plugin, params)
{
	return min(get_num(VOTELIST_SIZE), MAX_VOTELIST_SIZE);
}
public native_set_votelist_max_items(plugin, params)
{
	enum { arg_value = 1 };
	g_iMaxItems = get_param(arg_value);
}
public native_push_map_to_votelist(plugin, params)
{
	enum {
		arg_map = 1,
		arg_type,
		arg_ignore_check 
	};

	if(g_iVoteItems >= min(min(get_num(VOTELIST_SIZE), MAX_VOTELIST_SIZE), ArraySize(g_aMapsList))) {
		return PUSH_CANCELED;
	}

	new map[MAPNAME_LENGTH]; get_string(arg_map, map, charsmax(map));

	new ignore_checks = get_param(arg_ignore_check);

	if(!(ignore_checks & CHECK_IGNORE_VALID_MAP) && !is_map_valid(map)) {
		return PUSH_CANCELED;
	}

	if(is_map_in_vote(map)) {
		return PUSH_BLOCKED;
	}

	if(!(ignore_checks & CHECK_IGNORE_MAP_ALLOWED) && !is_map_allowed(map, get_param(arg_type), get_map_index(g_aMapsList, map))) {
		return PUSH_BLOCKED;
	}

	copy(g_sVoteList[g_iVoteItems], charsmax(g_sVoteList[]), map);
	g_iVoteItems++;

	return PUSH_SUCCESS;
}
public native_get_count_maps_in_vote(plugin, params)
{
	return g_iVoteItems + g_bCanExtend;
}
public native_get_voteitem_info(plugin, params)
{
	enum {
		arg_item = 1,
		arg_map,
		arg_len
	};

	new item = get_param(arg_item);
	if(item < 0 || item >= g_iVoteItems + g_bCanExtend) {
		return 0;
	}

	set_string(arg_map, g_sVoteList[item], get_param(arg_len));

	return g_iVotes[item];
}
public native_is_vote_started(plugin, params)
{
	return g_bVoteStarted;
}
public native_is_vote_finished(plugin, params)
{
	return g_bVoteFinished;
}
//-----------------------------------------------------//
// Maplist stuff
//-----------------------------------------------------//
public plugin_cfg()
{
	g_aMapsList = ArrayCreate(MapStruct, 1);

	new configsdir[256]; get_localinfo("amxx_configsdir", configsdir, charsmax(configsdir));
	server_cmd("exec %s/map_manager.cfg", configsdir);
	server_exec();

	get_mapname(g_sCurMap, charsmax(g_sCurMap));

	get_pcvar_string(g_pCvars[PREFIX], g_sPrefix, charsmax(g_sPrefix));
	replace_color_tag(g_sPrefix, charsmax(g_sPrefix));

	// add forward for change file?
	load_maplist(g_aMapsList, FILE_MAPS);
}
load_maplist(Array:array, const file[], bool:silent = false)
{
	new file_path[256]; get_localinfo("amxx_configsdir", file_path, charsmax(file_path));
	format(file_path, charsmax(file_path), "%s/%s", file_path, file);

	if(!file_exists(file_path)) {
		if(!silent) {
			new error[192]; formatex(error, charsmax(error), "File doesn't exist ^"%s^".", file_path);
			set_fail_state(error);
		}
		return 0;
	}

	new f = fopen(file_path, "rt");
	
	if(!f) {
		if(!silent) {
			set_fail_state("Can't read maps file.");
		}
		return 0;
	}

	new map_info[MapStruct], text[48], map[MAPNAME_LENGTH], first_map[MAPNAME_LENGTH], min[3], max[3], bool:nextmap, bool:found_nextmap;

	while(!feof(f)) {
		fgets(f, text, charsmax(text));
		parse(text, map, charsmax(map), min, charsmax(min), max, charsmax(max));

		if(!map[0] || map[0] == ';' || !valid_map(map) || get_map_index(array, map) != INVALID_MAP_INDEX) continue;
		
		if(!first_map[0]) {
			copy(first_map, charsmax(first_map), map);
		}
		if(equali(map, g_sCurMap)) {
			nextmap = true;
			continue;
		}
		if(nextmap) {
			nextmap = false;
			found_nextmap = true;
			set_cvar_string("amx_nextmap", map);
		}
		
		map_info[MapName] = map;
		map_info[MinPlayers] = str_to_num(min);
		map_info[MaxPlayers] = str_to_num(max) == 0 ? 32 : str_to_num(max);

		ArrayPushArray(array, map_info);
		min = ""; max = "";
	}
	fclose(f);

	if(!ArraySize(array)) {
		if(!silent) {
			new error[192]; formatex(error, charsmax(error), "Nothing loaded from ^"%s^".", file_path);
			set_fail_state(error);
		}
		return 0;
	}

	if(!silent) {
		if(!found_nextmap) {
			set_cvar_string("amx_nextmap", first_map);
		}
		new ret;
		ExecuteForward(g_hForwards[MAPLIST_LOADED], ret, array);
	}

	return 1;
}
//-----------------------------------------------------//
// Vote stuff
//-----------------------------------------------------//
prepare_vote(type)
{
	if(g_bVoteStarted) {
		return 0;
	}

	// server_print("--prepare vote--");

	g_bVoteStarted = true;
	g_bVoteFinished = false;

	g_iVoteType = type;

	g_iVoteItems = 0;
	g_iTotalVotes = 0;
	arrayset(g_iVoted, NOT_VOTED, sizeof(g_iVoted));
	arrayset(g_iVotes, 0, sizeof(g_iVotes));

	new array_size = ArraySize(g_aMapsList);
	new vote_max_items = min(min(get_num(VOTELIST_SIZE), MAX_VOTELIST_SIZE), array_size);

	new ret;
	ExecuteForward(g_hForwards[PREPARE_VOTELIST], ret, type);

	if(g_iMaxItems) {
		vote_max_items = g_iMaxItems;
		g_iMaxItems = 0;
	}

	if(g_iVoteItems < vote_max_items) {
		new map_info[MapStruct];
		for(new random_map; g_iVoteItems < vote_max_items; g_iVoteItems++) {
			do {
				random_map = random(array_size);
				ArrayGetArray(g_aMapsList, random_map, map_info);
			} while(is_map_in_vote(map_info[MapName]) || !is_map_allowed(map_info[MapName], PUSH_BY_CORE, random_map));

			copy(g_sVoteList[g_iVoteItems], charsmax(g_sVoteList[]), map_info[MapName]);
		}
	}

	ExecuteForward(g_hForwards[CAN_BE_EXTENDED], ret, type);
	g_bCanExtend = !ret;

	if(g_bCanExtend) {
		copy(g_sVoteList[g_iVoteItems], charsmax(g_sVoteList[]), g_sCurMap);
	}

	g_iCurMap = -1;
	for(new i; i < g_iVoteItems + g_bCanExtend; i++) {
		if(equali(g_sCurMap, g_sVoteList[i])) {
			g_iCurMap = i;
			break;
		}
	}

	if(get_num(RANDOM_NUMS)) {
		arrayset(g_iRandomNums, -1, sizeof(g_iRandomNums));
		for(new i; i < g_iVoteItems + g_bCanExtend; i++) {
			do {
				g_iRandomNums[i] = random(g_iVoteItems + g_bCanExtend);
			} while(in_array(i, g_iRandomNums[i]));
		}
	} else {
		for(new i; i < g_iVoteItems + g_bCanExtend; i++) {
			g_iRandomNums[i] = i;
		}
	}

	g_iOffset = get_num(VOTE_ITEM_OFFSET);

	if(g_iOffset + g_iVoteItems + g_bCanExtend >= MAX_VOTELIST_SIZE + 1) {
		g_iOffset = MAX_VOTELIST_SIZE + 1 - g_iVoteItems - g_bCanExtend;
	}

	g_iTimer = get_num(PREPARE_TIME) + 1;
	countdown(TASK_PREPARE_VOTE);

	return 1;
}
is_map_allowed(map[], type, index)
{
	new ret;
	ExecuteForward(g_hForwards[CAN_BE_IN_VOTELIST], ret, map, type, index);
	return ret == MAP_ALLOWED;
}
in_array(index, num)
{
	for(new i; i < index; i++) {
		if(num == g_iRandomNums[i]) {
			return true;
		}
	}
	return false;
}
get_original_num(num)
{
	for(new i; i < g_iVoteItems + g_bCanExtend; i++) {
		if(g_iRandomNums[i] == num) {
			return i;
		}
	}
	return 0;
}
public countdown(taskid)
{
	if(--g_iTimer > 0) {
		if(taskid == TASK_VOTE_TIME) {
			new dont_show_result = get_num(SHOW_RESULT_TYPE) == SHOW_DISABLED;
			g_iShowType = get_num(SHOW_RESULT_TYPE);
			g_bShowSelects = get_num(SHOW_SELECTS);
			
			new players[32], pnum; get_players(players, pnum, "ch");
			for(new i, id; i < pnum; i++) {
				id = players[i];
				if(!dont_show_result || g_iVoted[id] == NOT_VOTED) {
					show_votemenu(id);
				}
			}
		}

		new type = COUNTDOWN_UNKNOWN;
		switch(taskid) {
			case TASK_PREPARE_VOTE: type = COUNTDOWN_PREPARE;
			case TASK_VOTE_TIME: type = COUNTDOWN_VOTETIME;
		}
		new ret;
		ExecuteForward(g_hForwards[COUNTDOWN], ret, type, g_iTimer);

		set_task(1.0, "countdown", taskid);
	} else {
		if(taskid == TASK_PREPARE_VOTE) {
			start_vote();
		} else if(taskid == TASK_VOTE_TIME) {
			show_menu(0, 0, "^n", 1);
			finish_vote();
		}
	}
}
start_vote()
{
	// server_print("--start vote--");

	new ret;
	ExecuteForward(g_hForwards[VOTE_STARTED], ret, g_iVoteType);

	// TODO: add preview for N seconds

	g_iTimer = get_num(VOTE_TIME) + 1;
	countdown(TASK_VOTE_TIME);
}
public show_votemenu(id)
{
	static menu[512];
	new len, keys, percent, item;
	
	len = formatex(menu, charsmax(menu), "\y%L:^n^n", id, g_iVoted[id] != NOT_VOTED ? "MAPM_MENU_VOTE_RESULTS" : "MAPM_MENU_CHOOSE_MAP");
	
	for(item = 0; item < g_iVoteItems + g_bCanExtend; item++) {
		len += formatex(menu[len], charsmax(menu) - len, "%s", (item == g_iVoteItems) ? "^n" : "");

		if(g_iVoted[id] == NOT_VOTED) {
			len += formatex(menu[len], charsmax(menu) - len, "\r%d.\w %s", (g_iRandomNums[item] + 1 + g_iOffset == 10 ? 0 : g_iRandomNums[item] + 1 + g_iOffset), g_sVoteList[item]);
			keys |= (1 << (g_iRandomNums[item] + g_iOffset));
		} else {
			len += formatex(menu[len], charsmax(menu) - len, "%s%s", (g_iRandomNums[item] + g_iOffset == g_iVoted[id]) ? "\r" : "\d", g_sVoteList[item]);
		}

		percent = g_iTotalVotes ? floatround(g_iVotes[item] * 100.0 / g_iTotalVotes) : 0;
		len += formatex(menu[len], charsmax(menu) - len, "\d[\r%d%%\d]", percent);

		if(item == g_iCurMap) {
			len += formatex(menu[len], charsmax(menu) - len, "\y[%L]", id, "MAPM_MENU_EXTEND");
		}
		
		len += formatex(menu[len], charsmax(menu) - len, "^n");
	}

	len += formatex(menu[len], charsmax(menu) - len, "^n\d%L \r%d\d %L", id, "MAPM_MENU_LEFT", g_iTimer, id, "MAPM_SECONDS");

	if(!keys) keys = (1 << 9);

	if(g_iVoted[id] != NOT_VOTED && g_iShowType == SHOW_HUD) {
		while(replace(menu, charsmax(menu), "\r", "")){}
		while(replace(menu, charsmax(menu), "\d", "")){}
		while(replace(menu, charsmax(menu), "\w", "")){}
		while(replace(menu, charsmax(menu), "\y", "")){}
		
		set_hudmessage(0, 55, 255, 0.02, -1.0, 0, 6.0, 1.0, 0.1, 0.2, 4);
		show_hudmessage(id, "%s", menu);
	} else {
		show_menu(id, keys, menu, -1, "VoteMenu");
	}
}
public votemenu_handler(id, key)
{
	if(g_iVoted[id] != NOT_VOTED) {
		show_votemenu(id);
		return PLUGIN_HANDLED;
	}
	
	new original = get_original_num(key - g_iOffset);
	g_iVotes[original]++;
	g_iTotalVotes++;
	g_iVoted[id] = key;

	if(g_bShowSelects) {
		new name[32]; get_user_name(id, name, charsmax(name));
		if(original == g_iVoteItems) {
			client_print_color(0, id, "%s^3 %L", g_sPrefix, LANG_PLAYER, "MAPM_CHOSE_EXTEND", name);
		} else {
			client_print_color(0, id, "%s^3 %L", g_sPrefix, LANG_PLAYER, "MAPM_CHOSE_MAP", name, g_sVoteList[original]);
		}
	}

	if(g_iShowType != SHOW_DISABLED) {
		show_votemenu(id);
	}
	
	return PLUGIN_HANDLED;
}
finish_vote()
{
	g_bVoteStarted = false;

	// vote results
	// server_print("--finish vote--");

	// pre forward
	new ret;
	ExecuteForward(g_hForwards[ANALYSIS_OF_RESULTS], ret, g_iVoteType, g_iTotalVotes);

	if(ret) {
		if(ret == ABORT_VOTE_WITH_FORWARD) {
			ExecuteForward(g_hForwards[VOTE_CANCELED], ret, g_iVoteType);
		}
		return;
	}

	g_bVoteFinished = true;

	new max_vote = 0;
	if(g_iTotalVotes) {
		for(new i = 1; i < g_iVoteItems + 1; i++) {
			if(g_iVotes[max_vote] < g_iVotes[i]) max_vote = i;
		}
	}
	else {
		max_vote = random(g_iVoteItems);
	}

	// post forward
	// add blocking?
	ExecuteForward(g_hForwards[VOTE_FINISHED], ret, g_sVoteList[max_vote], g_iVoteType, g_iTotalVotes);
}

stop_vote()
{
	if(task_exists(TASK_VOTE_TIME)) {
		show_menu(0, 0, "^n", 1);
	}

	remove_task(TASK_PREPARE_VOTE);
	remove_task(TASK_VOTE_TIME);
	
	g_bVoteStarted = false;
	g_bVoteFinished = false;

	new ret;
	ExecuteForward(g_hForwards[VOTE_CANCELED], ret, g_iVoteType);
}

//-----------------------------------------------------//
// Usefull func
//-----------------------------------------------------//
get_map_index(Array:array, map[])
{
	for(new i = 0, map_info[MapStruct], size = ArraySize(array); i < size; i++) {
		ArrayGetArray(array, i, map_info);
		if(equali(map, map_info[MapName])) return i;
	}
	return INVALID_MAP_INDEX;
}
bool:is_map_in_vote(map[])
{
	for(new i; i < g_iVoteItems; i++) {
		if(equali(map, g_sVoteList[i])) {
			return true;
		}
	}
	return false;
}
