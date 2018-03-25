#if defined _map_manager_consts_included
  #endinput
#endif
#define _map_manager_consts_included

const MAPNAME_LENGTH = 32;

enum _:MapStruct {
	MapName[MAPNAME_LENGTH],
	MinPlayers,
	MaxPlayers
};

enum _:NomStruct {
	NomPlayer,
	NomMapIndex
};

enum {
	MAP_ALLOWED,
	MAP_BLOCKED
};

enum {
	PUSH_BLOCKED = -1,
	PUSH_CANCELED,
	PUSH_SUCCESS
};

enum {
	VOTE_BY_CMD,
	VOTE_BY_RTV,
	VOTE_BY_SCHEDULER,
	VOTE_BY_SCHEDULER_SECOND
};

enum {
	ALLOW_VOTE,
	ABORT_VOTE
};

enum {
	EXTEND_ALLOWED,
	EXTEND_BLOCKED
};

const INVALID_MAP_INDEX = -1;
