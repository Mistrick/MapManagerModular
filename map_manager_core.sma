/*
    Core functions:
    - load maplist
    - start vote by time ? or do with addon
    - start/stop vote
*/
#include <amxmodx>
#include <map_manager_consts>

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

new const FILE_MAPS[] = "maps.ini";
//-----------------------------------------------------//

enum Forwards
{
    PREPARE_VOTELIST
};

new g_iVoteListPointer;
new g_sVoteList[VOTELIST_SIZE][MAPNAME_LENGTH];
new g_hForwards[Forwards];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    register_cvar("mapm_version", VERSION, FCVAR_SERVER | FCVAR_SPONLY);

    register_concmd("mapm_start_vote", "ConCmd_StartVote", ADMIN_MAP);

    // TODO: register forwards
    g_hForwards[PREPARE_VOTELIST] = CreateMultiForward("mapm_prepare_votelist", ET_IGNORE);
}

public plugin_natives()
{
    register_library("map_manager_core");

    register_native("mapm_start_vote", "native_start_vote");
    register_native("mapm_stop_vote", "native_stop_vote");
    register_native("mapm_push_map_to_votelist", "native_push_map_to_votelist");
}

public native_start_vote(plugin, params)
{
    // TODO: call start vote func
}
public native_stop_vote(plugin, params)
{
    // TODO: call stop vote func
}
public native_push_map_to_votelist(plugin, params)
{
    enum { arg_map = 1 };

    if(g_iVoteListPointer >= VOTELIST_SIZE) {
        return 0;
    }

    // TODO: add map validation
    get_string(arg_map, g_sVoteList[g_iVoteListPointer], charsmax(g_sVoteList[]));
    g_iVoteListPointer++;

    return 1;
}

//-----------------------------------------------------//
// Maplist stuff
//-----------------------------------------------------//
public plugin_cfg()
{
    load_maplist();
}
load_maplist()
{
    new file_path[128]; get_localinfo("amxx_configsdir", file_path, charsmax(file_path));
	format(file_path, charsmax(file_path), "%s/%s", file_path, file);

	if(!file_exists(file_path))
	{
		set_fail_state("Maps file doesn't exist.");
	}

	new cur_map[MAP_NAME_LENGTH]; get_mapname(cur_map, charsmax(cur_map));
	new file = fopen(file_path, "rt");
	
	if(file)
	{
		new map_info[MapsListStruct], text[48], map[MAP_NAME_LENGTH], min[3], max[3];

		#if defined FUNCTION_NEXTMAP
		new nextmap = false, founded_nextmap = false, first_map[32];
		#endif // FUNCTION_NEXTMAP

		#if defined FUNCTION_NOMINATION
		new prefix[MAP_NAME_LENGTH];
		#endif // FUNCTION_NOMINATION

		while(!feof(file))
		{
			fgets(file, text, charsmax(text));
			parse(text, map, charsmax(map), min, charsmax(min), max, charsmax(max));
			
			strtolower(map);

			if(!map[0] || map[0] == ';' || !valid_map(map) || is_map_in_array(map)) continue;
			
			#if defined FUNCTION_NEXTMAP
			if(!first_map[0])
			{
				copy(first_map, charsmax(first_map), map);
			}
			#endif
			
			if(equali(map, cur_map))
			{
				#if defined FUNCTION_NEXTMAP
				nextmap = true;
				#endif // FUNCTION_NEXTMAP
				continue;
			}

			#if defined FUNCTION_NEXTMAP
			if(nextmap)
			{
				nextmap = false;
				founded_nextmap = true;
				set_pcvar_string(g_pCvars[NEXTMAP], map);
				server_print("founded nextmap: %s", map);
			}
			#endif // FUNCTION_NEXTMAP

			#if defined FUNCTION_NOMINATION
			if(get_map_prefix(map, prefix, charsmax(prefix)) && !is_prefix_in_array(prefix))
			{
				ArrayPushString(g_aMapsPrefixes, prefix);
				g_iMapsPrefixesNum++;
			}
			#endif // FUNCTION_NOMINATION
			
			map_info[m_MapName] = map;
			map_info[m_MinPlayers] = str_to_num(min);
			map_info[m_MaxPlayers] = str_to_num(max) == 0 ? 32 : str_to_num(max);
			
			#if defined FUNCTION_BLOCK_MAPS
			if(TrieKeyExists(trie_blocked_maps, map))
			{
				TrieGetCell(trie_blocked_maps, map, map_info[m_BlockCount]);
				g_iBlockedMaps++;
			}
			#endif // FUNCTION_BLOCK_MAPS

			ArrayPushArray(g_aMapsList, map_info);
			min = ""; max = ""; map_info[m_BlockCount] = 0;
			g_iMapsListSize++;
		}
		fclose(file);

		if(g_iMapsListSize == 0)
		{
			set_fail_state("Nothing loaded from file.");
		}

		#if defined FUNCTION_NEXTMAP
		if(!founded_nextmap)
		{
			set_pcvar_string(g_pCvars[NEXTMAP], first_map);
			server_print("founded nextmap: %s (first in file)", first_map);
		}
		#endif // FUNCTION_NEXTMAP
	}
}
//-----------------------------------------------------//
// Commands stuff
//-----------------------------------------------------//
public ConCmd_StartVote(id, level, cid)
{
    // TODO: add flag check
    prepare_vote();
}
//-----------------------------------------------------//
// Vote stuff
//-----------------------------------------------------//
prepare_vote()
{
    // TODO: fill vote list

    g_iVoteListPointer = 0;

    // call mapm_prepare_votelist()
    new ret;
    ExecuteForward(g_hForwards[PREPARE_VOTELIST], ret);

    if(g_iVoteListPointer < VOTELIST_SIZE) {
        // add random maps from list
    }

    start_vote();
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
}

stop_vote()
{
    // vote results
}