#include <amxmodx>
#include <map_manager>

#if AMXX_VERSION_NUM < 183
#include <colorchat>
#endif

#define PLUGIN "Map Manager: BlockList"
#define VERSION "0.0.1"
#define AUTHOR "Mistrick"

#pragma semicolon 1

#define BLOCK_MAP_COUNT 10

new const FILE_BLOCKED_MAPS[] = "blockedmaps.ini"; //datadir

new Trie:g_tBlockedList;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
}
public plugin_natives()
{
	register_library("map_manager_blocklist");
	register_native("mapm_get_blocked_count", "native_get_blocked_count");
}
public native_get_blocked_count(plugin, params)
{
	enum { arg_map = 1 };
	new map[MAPNAME_LENGTH]; get_string(arg_map, map, charsmax(map));

	if(!TrieKeyExists(g_tBlockedList, map)) {
		return 0;
	}

	new count; TrieGetCell(g_tBlockedList, map, count);

	return count;
}
public plugin_cfg()
{
	g_tBlockedList = TrieCreate();
	load_blocklist();
}
load_blocklist()
{
	new file_dir[128]; get_localinfo("amxx_datadir", file_dir, charsmax(file_dir));
	new file_path[128]; formatex(file_path, charsmax(file_path), "%s/%s", file_dir, FILE_BLOCKED_MAPS);

	new cur_map[MAPNAME_LENGTH]; get_mapname(cur_map, charsmax(cur_map)); strtolower(cur_map);
	TrieSetCell(g_tBlockedList, cur_map, BLOCK_MAP_COUNT);

	new f, temp;

	if(file_exists(file_path)) {
		new temp_file_path[128]; formatex(temp_file_path, charsmax(temp_file_path), "%s/temp.ini", file_dir);
		f = fopen(file_path, "rt");
		temp = fopen(temp_file_path, "wt");

		new buffer[40], map[MAPNAME_LENGTH], str_count[6], count;
		server_print("Blocked list:^n%s", cur_map);
		while(!feof(f)) {
			fgets(f, buffer, charsmax(buffer));
			parse(buffer, map, charsmax(map), str_count, charsmax(str_count));
			strtolower(map);
			
			if(!is_map_valid(map) || TrieKeyExists(g_tBlockedList, map)) continue;
			
			count = min(str_to_num(str_count) - 1, BLOCK_MAP_COUNT);
			
			if(count <= 0) continue;

			fprintf(temp, "^"%s^" ^"%d^"^n", map, count);
			TrieSetCell(g_tBlockedList, map, count);
			server_print("%s", map);
		}
		
		fprintf(temp, "^"%s^" ^"%d^"^n", cur_map, BLOCK_MAP_COUNT);
		
		fclose(f);
		fclose(temp);
		
		delete_file(file_path);
		rename_file(temp_file_path, file_path, 1);
	}
	else {
		f = fopen(file_path, "wt");
		if(f) {
			fprintf(f, "^"%s^" ^"%d^"^n", cur_map, BLOCK_MAP_COUNT);
		}
		fclose(f);
	}
}

public mapm_can_be_in_votelist(map[])
{
	// TODO: need checks if blocked maps more than available
	return TrieKeyExists(g_tBlockedList, map) ? MAP_BLOCKED : MAP_ALLOWED;
}