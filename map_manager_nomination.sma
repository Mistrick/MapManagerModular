#include <amxmodx>
#include <map_manager>

#if AMXX_VERSION_NUM < 183
#include <colorchat>
#endif

#define PLUGIN "Map Manager: Nomination"
#define VERSION "0.0.1"
#define AUTHOR "Mistrick"

#pragma semicolon 1

#define NOMINATED_MAPS_IN_VOTE 3
#define NOMINATED_MAPS_PER_PLAYER 3

enum {
	NOMINATION_FAIL,
	NOMINATION_SUCCESS,
	NOMINATION_REMOVED
};

new Array:g_aNomList;
new Array:g_aMapsList;
new Array:g_aMapsPrefixes;
new g_iMapsPrefixesNum;

new g_iNomMaps[33];

new PREFIX[32];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say", "ClCmd_Say");
	register_clcmd("say_team", "ClCmd_Say");
	register_clcmd("say maps", "ClCmd_MapsList");
	register_clcmd("say /maps", "ClCmd_MapsList");
}

public mapm_maplist_loaded(Array:maplist)
{
	g_aMapsList = maplist;
	g_aNomList = ArrayCreate(NomStruct, 1);
	g_aMapsPrefixes = ArrayCreate(MAPNAME_LENGTH, 1);
	mapm_get_prefix(PREFIX, charsmax(PREFIX));
	load_map_prefixes();
}
load_map_prefixes()
{
	new map_info[MapStruct], prefix[MAPNAME_LENGTH], size = ArraySize(g_aMapsList);
	server_print("Loaded prefixes:");
	for(new i; i < size; i++) {
		ArrayGetArray(g_aMapsList, i, map_info);
		if(get_map_prefix(map_info[MapName], prefix, charsmax(prefix)) && !is_prefix_in_array(prefix))
		{
			ArrayPushString(g_aMapsPrefixes, prefix);
			g_iMapsPrefixesNum++;
			server_print("%s", prefix);
		}
	}
}
public client_disconnect(id)
{
	if(g_iNomMaps[id]) {
		clear_nominated_maps(id);
	}
}
public ClCmd_Say(id)
{
	new text[MAPNAME_LENGTH]; read_args(text, charsmax(text));
	remove_quotes(text); trim(text); strtolower(text);
	
	if(is_string_with_space(text)) return PLUGIN_CONTINUE;
	
	new map_index = mapm_is_map_in_list(text);

	if(map_index) {
		nominate_map(id, text, map_index - 1);
	}
	else if(strlen(text) >= 4) {
		/*
		new buffer[MAP_NAME_LENGTH], prefix[MAP_NAME_LENGTH], Array:array_nominate_list = ArrayCreate(), array_size;
		for(new i; i < g_iMapsPrefixesNum; i++)
		{
			ArrayGetString(g_aMapsPrefixes, i, prefix, charsmax(prefix));
			formatex(buffer, charsmax(buffer), "%s%s", prefix, text);
			map_index = 0;
			while((map_index = find_similar_map(map_index, buffer)))
			{
				ArrayPushCell(array_nominate_list, map_index - 1);
				array_size++;
			}
		}
		
		if(array_size == 1)
		{
			map_index = ArrayGetCell(array_nominate_list, 0);
			new map_info[MapsListStruct]; ArrayGetArray(g_aMapsList, map_index, map_info);
			copy(buffer, charsmax(buffer), map_info[m_MapName]);
			nominate_map(id, buffer, map_index);
		}
		else if(array_size > 1)
		{
			Show_NominationList(id, array_nominate_list, array_size);
		}
		
		ArrayDestroy(array_nominate_list);
		*/
	}

	return PLUGIN_CONTINUE;
}
nominate_map(id, map[], index)
{
	new map_info[MapStruct]; ArrayGetArray(g_aMapsList, index, map_info);
	
	// TODO: add check is map blocked
	
	new nom_info[NomStruct], name[32];
	get_user_name(id, name, charsmax(name));
	
	new nom_index = is_map_nominated(index);
	if(nom_index) {
		ArrayGetArray(g_aNomList, nom_index - 1, nom_info);
		if(id != nom_info[NomPlayer]) {
			client_print_color(id, print_team_default, "%s^1 %L", PREFIX, id, "MAPM_NOM_ALREADY_NOM");
			return NOMINATION_FAIL;
		}

		// TODO: add spam protection for nom/denom
		g_iNomMaps[id]--;
		ArrayDeleteItem(g_aNomList, nom_index - 1);
		
		client_print_color(0, id, "%s^3 %L", PREFIX, LANG_PLAYER, "MAPM_NOM_REMOVE_NOM", name, map);
		return NOMINATION_REMOVED;
	}
	
	if(g_iNomMaps[id] >= NOMINATED_MAPS_PER_PLAYER) {
		client_print_color(id, print_team_default, "%s^1 %L", PREFIX, id, "MAPM_NOM_CANT_NOM");
		return NOMINATION_FAIL;
	}
	
	nom_info[NomPlayer] = id;
	nom_info[NomMapIndex] = index;
	ArrayPushArray(g_aNomList, nom_info);
	
	g_iNomMaps[id]++;
	
	client_print_color(0, id, "%s^3 %L", PREFIX, LANG_PLAYER, "MAPM_NOM_MAP", name, map);
	
	return NOMINATION_SUCCESS;
}
public ClCmd_MapsList(id)
{
	
}

public mapm_prepare_votelist()
{
	new nom_info[NomStruct], map_info[MapStruct];
	for(new i, index; i < NOMINATED_MAPS_IN_VOTE && ArraySize(g_aNomList); i++) {
		index = random(ArraySize(g_aNomList));
		ArrayGetArray(g_aNomList, index, nom_info);
		ArrayGetArray(g_aMapsList, nom_info[NomMapIndex], map_info);
		ArrayDeleteItem(g_aNomList, index);
		g_iNomMaps[nom_info[NomPlayer]]--;

		if(mapm_push_map_to_votelist(map_info[MapName]) == PUSH_BLOCKED) {
			i--;
		}
	}
}

is_prefix_in_array(prefix[])
{
	for(new i, str[MAPNAME_LENGTH]; i < g_iMapsPrefixesNum; i++) {
		ArrayGetString(g_aMapsPrefixes, i, str, charsmax(str));
		if(equali(prefix, str)) return true;
	}
	return false;
}
is_map_nominated(index)
{
	new nom_info[NomStruct], size = ArraySize(g_aNomList);
	for(new i; i < size; i++) {
		ArrayGetArray(g_aNomList, i, nom_info);
		if(index == nom_info[NomMapIndex]) {
			return i + 1;
		}
	}
	return 0;
}
clear_nominated_maps(id)
{
	new nom_info[NomStruct];
	for(new i = 0; i < ArraySize(g_aNomList); i++) {
		ArrayGetArray(g_aNomList, i, nom_info);
		if(id == nom_info[NomPlayer]) {
			ArrayDeleteItem(g_aNomList, i--);
			if(!--g_iNomMaps[id]) {
				break;
			}
		}
	}
}
