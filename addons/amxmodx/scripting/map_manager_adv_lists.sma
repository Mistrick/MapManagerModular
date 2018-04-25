#include <amxmodx>
#include <map_manager>

#define PLUGIN "Map Manager: Advanced lists"
#define VERSION "0.0.2"
#define AUTHOR "Mistrick"

new const FILE_MAP_LISTS[] = "maplists.ini";

enum (+=100) {
	TASK_CHECK_LIST = 150
};

enum _:MapListInfo {
	StartTime,
	StopTime,
	ClearOldList,
	FileList[128]
};

new Array:g_aLists;
new g_iCurList = -1;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
}
public plugin_cfg()
{
	new file_path[256]; get_localinfo("amxx_configsdir", file_path, charsmax(file_path));
	format(file_path, charsmax(file_path), "%s/%s", file_path, FILE_MAP_LISTS);

	if(!file_exists(file_path)) {
		set_fail_state("Maplists file doesn't exist.");
	}

	new f = fopen(file_path, "rt");
	
	if(!f) {
		set_fail_state("Can't read maplists file.");
	}

	// <start> <stop> <filename> <clear old list>

	g_aLists = ArrayCreate(MapListInfo, 1);

	new list_info[MapListInfo];
	new text[256], start[6], stop[6], file_list[128], clr[4]
	while(!feof(f)) {
		fgets(f, text, charsmax(text));
		trim(text);

		if(!text[0] || text[0] == ';') continue;

		parse(text, start, charsmax(start), stop, charsmax(stop), file_list, charsmax(file_list), clr, charsmax(clr));

		list_info[StartTime] = get_int_time(start);
		list_info[StopTime] = get_int_time(stop);
		list_info[ClearOldList] = str_to_num(clr);
		copy(list_info[FileList], charsmax(list_info[FileList]), file_list);

		ArrayPushArray(g_aLists, list_info);

		// server_print("%d %d %s %d", list_info[StartTime], list_info[StopTime], list_info[FileList], list_info[ClearOldList]);
	}
	fclose(f);

	if(!ArraySize(g_aLists)) {
		// pause plugin?
		log_amx("nothing loaded.");
	} else {
		task_check_list();
		set_task(60.0, "task_check_list", TASK_CHECK_LIST, .flags = "b");
	}
}
public task_check_list()
{
	new hours, mins; time(hours, mins);
	new cur_time = hours * 60 + mins;

	new list_info[MapListInfo];

	for(new i, found_newlist, size = ArraySize(g_aLists); i < size; i++) {
		ArrayGetArray(g_aLists, i, list_info);

		if(list_info[StartTime] <= list_info[StopTime]) {
			if(g_iCurList != i && list_info[StartTime] <= cur_time <= list_info[StopTime]) {
				found_newlist = true;
			}
		} else {
			if(g_iCurList != i && (list_info[StartTime] <= cur_time <= 24 * 60 || cur_time <= list_info[StopTime])) {
				found_newlist = true;
			}
		}

		if(found_newlist) {
			found_newlist = false;
			g_iCurList = i;
			mapm_load_maplist(list_info[FileList], list_info[ClearOldList]);
			log_amx("loaded new maplist[%s]", list_info[FileList]);
		}
	}
}
get_int_time(string[])
{
	new left[4], right[4]; strtok(string, left, charsmax(left), right, charsmax(right), ':');
	return str_to_num(left) * 60 + str_to_num(right);
}
