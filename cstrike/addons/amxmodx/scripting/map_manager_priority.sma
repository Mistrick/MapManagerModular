#include <amxmodx>
#include <map_manager>

#define PLUGIN "Map Manager: Priority"
#define VERSION "0.0.1"
#define AUTHOR "Mistrick"

#pragma semicolon 1

new Array:g_aMapList;

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
}

public mapm_maplist_loaded(Array:maplist, const nextmap[])
{
    g_aMapList = maplist;
}

public mapm_can_be_in_votelist(const map[], type, index)
{
    new map_info[MapStruct];
    ArrayGetArray(g_aMapList, index, map_info);
    new rnd = random_num(0, 99);
    
    return rnd < map_info[MapPriority] ? MAP_ALLOWED : MAP_BLOCKED;
}
