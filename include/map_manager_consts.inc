#if defined _map_manager_consts_included
  #endinput
#endif
#define _map_manager_consts_included

#define MAPNAME_LENGTH 32

enum _:MapList {
	MapName[MAPNAME_LENGTH],
	MinPlayers,
	MaxPlayers
};

enum {
	MAP_ALLOWED,
	MAP_BLOCKED
};
