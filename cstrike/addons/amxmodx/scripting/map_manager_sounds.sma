#include <amxmodx>
#include <map_manager>

#define PLUGIN "Map Manager: Sounds"
#define VERSION "0.0.2"
#define AUTHOR "Mistrick"

#pragma semicolon 1

enum Sections {
    UNUSED_SECTION,
    SOUND_VOTE_STARTED,
    SOUND_VOTE_FINISHED,
    SOUNDS_COUNTDOWN
}
enum ParserData {
    Sections:SECTION
};
new parser_info[ParserData];

new g_sVoteStarted[128];
new g_sVoteFinished[128];
new Trie:g_tCountdownSounds;

public plugin_precache()
{
    register_plugin(PLUGIN, VERSION + VERSION_HASH, AUTHOR);

    g_tCountdownSounds = TrieCreate();
    load_settings();
}
load_settings()
{
    new INIParser:parser = INI_CreateParser();

    INI_SetParseEnd(parser, "ini_parse_end");
    INI_SetReaders(parser, "ini_key_value", "ini_new_section");
    new bool:result = INI_ParseFile(parser, "addons/amxmodx/configs/map_manager_settings.ini");

    if(!result) {
        set_fail_state("Can't read from ini file.");
    }
}
public ini_new_section(INIParser:handle, const section[], bool:invalid_tokens, bool:close_bracket, bool:extra_tokens, curtok, any:data)
{
    if(equal(section, "sound_vote_started")) {
        parser_info[SECTION] = SOUND_VOTE_STARTED;
    } else if(equal(section, "sound_vote_finished")) {
        parser_info[SECTION] = SOUND_VOTE_FINISHED;
    } else if(equal(section, "sounds_countdown")) {
        parser_info[SECTION] = SOUNDS_COUNTDOWN;
    } else {
        parser_info[SECTION] = UNUSED_SECTION;
    }
    return true;
}
public ini_key_value(INIParser:handle, const key[], const value[], bool:invalid_tokens, bool:equal_token, bool:quotes, curtok, any:data)
{
    switch(parser_info[SECTION]) {
        case SOUND_VOTE_STARTED: {
            copy(g_sVoteStarted, charsmax(g_sVoteStarted), key);
            remove_quotes(g_sVoteStarted);
            precache_generic(g_sVoteStarted);
        }
        case SOUND_VOTE_FINISHED: {
            copy(g_sVoteFinished, charsmax(g_sVoteFinished), key);
            remove_quotes(g_sVoteFinished);
            precache_generic(g_sVoteFinished);
        }
        case SOUNDS_COUNTDOWN: {
            new k[16];
            copy(k, charsmax(k), key);
            remove_quotes(k);
            precache_generic(value);
            TrieSetString(g_tCountdownSounds, k, value);
        }
    }
    return true;
}
public ini_parse_end(INIParser:handle, bool:halted, any:data)
{
    INI_DestroyParser(handle);
}
public mapm_countdown(type, time)
{
    if(type == COUNTDOWN_PREPARE) {
        new key[4], sound[128];
        num_to_str(time, key, charsmax(key));
        if(TrieKeyExists(g_tCountdownSounds, key)) {
            TrieGetString(g_tCountdownSounds, key, sound, charsmax(sound));
            play_sound(0, sound);
        }
    }
}
public mapm_vote_started(type)
{
    if(g_sVoteStarted[0]) {
        play_sound(0, g_sVoteStarted);
    }
}
public mapm_vote_finished(const map[], type, total_votes)
{
    if(g_sVoteFinished[0]) {
        play_sound(0, g_sVoteFinished);
    }
}
play_sound(id, sound[])
{
    new len = strlen(sound);
    if(equali(sound[len - 3], "wav")) {
        send_audio(id, sound, PITCH_NORM);
    } else if(equali(sound[len - 3], "mp3")) {
        client_cmd(id, "mp3 play ^"%s^"", sound);
    }
}
