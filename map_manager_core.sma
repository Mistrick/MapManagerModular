/*
	Core functions:
	- load maplist
	- start vote by time ? or do with addon
	- start/stop vote
*/
#include <amxmodx>
#include <map_manager_consts>
#include <map_manager_stocks>

#if AMXX_VERSION_NUM < 183
#include <colorchat>
#endif

#define PLUGIN "Map Manager: Core"
#define VERSION "0.0.1"
#define AUTHOR "Mistrick"

#pragma semicolon 1

//-----------------------------------------------------//
// Consts
//-----------------------------------------------------//
#define VOTELIST_SIZE 5

new PREFIX[] = "[MapManager]";

new const FILE_MAPS[] = "maps.ini";
//-----------------------------------------------------//

enum Forwards {
	PREPARE_VOTELIST,
	MAPLIST_LOADED,
	CAN_BE_IN_VOTELIST,
	VOTE_STARTED,
	VOTE_FINISHED
};

new g_iVoteListPointer;
new g_sVoteList[VOTELIST_SIZE][MAPNAME_LENGTH];
new g_hForwards[Forwards];

new Array:g_aMapsList;
new g_iMapsListSize;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_cvar("mapm_version", VERSION, FCVAR_SERVER | FCVAR_SPONLY);

	register_concmd("mapm_start_vote", "ConCmd_StartVote", ADMIN_MAP);

	// TODO: register forwards
	g_hForwards[PREPARE_VOTELIST] = CreateMultiForward("mapm_prepare_votelist", ET_IGNORE);
	g_hForwards[MAPLIST_LOADED] = CreateMultiForward("mapm_maplist_loaded", ET_IGNORE, FP_CELL);
	g_hForwards[CAN_BE_IN_VOTELIST] = CreateMultiForward("mapm_can_be_in_votelist", ET_CONTINUE, FP_STRING);

	register_dictionary("mapmanager.txt");
}

public plugin_natives()
{
	register_library("map_manager_core");

	register_native("mapm_is_map_in_list", "native_is_map_in_list");
	register_native("mapm_get_prefix", "native_get_prefix");
	register_native("mapm_start_vote", "native_start_vote");
	register_native("mapm_stop_vote", "native_stop_vote");
	register_native("mapm_push_map_to_votelist", "native_push_map_to_votelist");
}
public native_is_map_in_list(plugin, params)
{
	enum { arg_map = 1 };
	new map[MAPNAME_LENGTH]; get_string(arg_map, map, charsmax(map));
	return is_map_in_array(map);
}
public native_get_prefix(plugin, params)
{
	enum {
		arg_prefix = 1,
		arg_len
	};
	set_string(arg_prefix, PREFIX, get_param(arg_len));
}
public native_start_vote(plugin, params)
{
	prepare_vote();
}
public native_stop_vote(plugin, params)
{
	stop_vote();
}
public native_push_map_to_votelist(plugin, params)
{
	enum { arg_map = 1 };

	if(g_iVoteListPointer >= VOTELIST_SIZE) {
		return PUSH_CANCELED;
	}

	new map[MAPNAME_LENGTH]; get_string(arg_map, map, charsmax(map));
	if(!is_map_valid(map)) {
		return PUSH_CANCELED;
	}

	// TODO: add param call from native
	if(!is_map_allowed(map)) {
		return PUSH_BLOCKED;
	}

	copy(g_sVoteList[g_iVoteListPointer], charsmax(g_sVoteList[]), map);
	g_iVoteListPointer++;

	return PUSH_SUCCESS;
}

//-----------------------------------------------------//
// Maplist stuff
//-----------------------------------------------------//
public plugin_cfg()
{
	g_aMapsList = ArrayCreate(MapStruct, 1);

	// add forward for change file?
	load_maplist(FILE_MAPS);
}
load_maplist(const file[])
{
	new file_path[128]; get_localinfo("amxx_configsdir", file_path, charsmax(file_path));
	format(file_path, charsmax(file_path), "%s/%s", file_path, file);

	if(!file_exists(file_path)) {
		set_fail_state("Maps file doesn't exist.");
	}

	new f = fopen(file_path, "rt");
	
	if(!f) {
		set_fail_state("Can't read maps file.");
	}

	new map_info[MapStruct], text[48], map[MAPNAME_LENGTH], min[3], max[3];

	while(!feof(f)) {
		fgets(f, text, charsmax(text));
		parse(text, map, charsmax(map), min, charsmax(min), max, charsmax(max));
		
		strtolower(map);

		if(!map[0] || map[0] == ';' || !valid_map(map) || is_map_in_array(map)) continue;
		
		map_info[MapName] = map;
		map_info[MinPlayers] = str_to_num(min);
		map_info[MaxPlayers] = str_to_num(max) == 0 ? 32 : str_to_num(max);

		ArrayPushArray(g_aMapsList, map_info);
		min = ""; max = "";
		g_iMapsListSize++;
	}
	fclose(f);

	if(g_iMapsListSize == 0) {
		new error[192]; formatex(error, charsmax(error), "Nothing loaded from ^"%s^".", file_path);
		set_fail_state(error);
	}

	new ret;
	ExecuteForward(g_hForwards[MAPLIST_LOADED], ret, g_aMapsList);
}
//-----------------------------------------------------//
// Commands stuff
//-----------------------------------------------------//
public ConCmd_StartVote(id, level, cid)
{
	// TODO: add flag check
	prepare_vote();
	return PLUGIN_HANDLED;
}
//-----------------------------------------------------//
// Vote stuff
//-----------------------------------------------------//
prepare_vote()
{
	g_iVoteListPointer = 0;

	new vote_max_items = min(VOTELIST_SIZE, g_iMapsListSize);

	new ret;
	ExecuteForward(g_hForwards[PREPARE_VOTELIST], ret);

	// TODO: add min/max sort
	if(g_iVoteListPointer < vote_max_items) {
		new map_info[MapStruct];
		for(new random_map; g_iVoteListPointer < vote_max_items; g_iVoteListPointer++) {
			do {
				random_map = random(g_iMapsListSize);
				ArrayGetArray(g_aMapsList, random_map, map_info);
			} while(is_map_in_vote(map_info[MapName]) || !is_map_allowed(map_info[MapName]));

			copy(g_sVoteList[g_iVoteListPointer], charsmax(g_sVoteList[]), map_info[MapName]);
		}
	}

	start_vote();
}

is_map_allowed(map[])
{
	new ret;
	ExecuteForward(g_hForwards[CAN_BE_IN_VOTELIST], ret, map);
	return ret == MAP_ALLOWED;
}

start_vote()
{
	// show menu
	// timer
	server_print("Votelist:");
	for(new i; i < g_iVoteListPointer; i++) {
		if(g_sVoteList[i][0]) {
			server_print("%d - %s", i + 1, g_sVoteList[i]);
		}
	}

	finish_vote();
}

finish_vote()
{
	// vote results
}

stop_vote()
{
	// cancel vote
}

//-----------------------------------------------------//
// Usefull func
//-----------------------------------------------------//
is_map_in_array(map[])
{
	for(new i = 0, map_info[MapStruct]; i < g_iMapsListSize; i++) {
		ArrayGetArray(g_aMapsList, i, map_info);
		if(equali(map, map_info[MapName])) return i + 1;
	}
	return 0;
}
is_map_in_vote(map[])
{
	for(new i; i < g_iVoteListPointer; i++) {
		if(equali(map, g_sVoteList[i])) {
			return true;
		}
	}
	return false;
}