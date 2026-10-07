public stock const PluginName[] =		"Set player Sprite";
public stock const PluginVersion[] =	"1.3";
public stock const PluginAuthor[] =		"R1CHICOREJZ";

#include <amxmodx>
#include <fakemeta>
#include <reapi>

/* -> Entity: Sprites <- */
#define var_max_frame					var_yaw_speed
#define var_last_time					var_pitch_speed
#define var_start_frame					var_fuser3
#define var_end_time					var_ltime
#define var_fade_end					var_fuser1

#define DEFAULT_SPRITE_CLASSNAME		"env_sprite_head"
#define MAX_CLASSNAME_LENGTH			32

#define SPRITE_NEXTTHINK				0.02
#define SPRITE_FADE_TIME				0.5

#define Vector3(%0)						Float: %0[3]

new const szInfoTargetReference[] = 	"info_target";
new Array:g_aSpriteClasses;

public plugin_precache()
{
	g_aSpriteClasses = ArrayCreate(MAX_CLASSNAME_LENGTH);
}

public plugin_init()
{
	register_plugin(PluginName, PluginVersion, PluginAuthor);

	RegisterHookChain(RG_CBasePlayer_Killed, "CBasePlayer_Killed_Post", true);
	RegisterHookChain(RG_CSGameRules_RestartRound, "CSGameRules_RestartRound_Pre", false);
}

public plugin_end()
{
	for (new pPlayer = 1; pPlayer <= MaxClients; pPlayer++)
	{
		UTIL_KillUserSprites(pPlayer);
	}

	ArrayDestroy(g_aSpriteClasses);
}

public CBasePlayer_Killed_Post(const pPlayer, const pevAttacker, const iGib)
{
	UTIL_KillUserSprites(pPlayer);
}

stock UTIL_KillUserSprite(const pPlayer, const szClass[])
{
	new pEntity = NULLENT;

	while (rg_find_ent_by_owner(pEntity, szClass, pPlayer))
	{
		UTIL_KillEntity(pEntity);
	}
}

stock UTIL_KillUserSprites(const pPlayer)
{
	new szClass[MAX_CLASSNAME_LENGTH];

	for (new i; i < ArraySize(g_aSpriteClasses); i++)
	{
		ArrayGetString(g_aSpriteClasses, i, szClass, charsmax(szClass));
		UTIL_KillUserSprite(pPlayer, szClass);
	}
}

public CSGameRules_RestartRound_Pre()
{
	for (new pPlayer = 1; pPlayer <= MaxClients; pPlayer++)
	{
		UTIL_KillUserSprites(pPlayer);
	}
}

public plugin_natives()
{
	register_library("AnimationSprite");

	register_native("zh_precache_sprite", "Native_PrecacheSpriteHead");
	register_native("zh_set_user_sprite", "Native_SetPlayerSpriteHead");
}

public Native_PrecacheSpriteHead(const iPlugin, const iParams)
{
	new szModel[256];
	get_string(1, szModel, charsmax(szModel));

	if (!szModel[0] || !file_exists(szModel)) { return 0; }

	return engfunc(EngFunc_PrecacheModel, szModel);
}

public Native_SetPlayerSpriteHead(const iPlugin, const iParams)
{
	enum {
		arg_player = 1,
		arg_spritemdl,
		arg_spritescale,
		arg_startframe,
		arg_holdtime,
		arg_classname,
		arg_up_offset
	}

	new pPlayer = get_param(arg_player);

	new szModel[256];
	get_string(arg_spritemdl, szModel, charsmax(szModel));

	new Float:flSpriteScale = get_param_f(arg_spritescale);
	new Float:flStartFrame = get_param_f(arg_startframe);
	new Float:flHoldTime = (iParams >= arg_holdtime) ? get_param_f(arg_holdtime) : 0.0;

	new szClassname[MAX_CLASSNAME_LENGTH];
	if (iParams >= arg_classname)
		get_string(arg_classname, szClassname, charsmax(szClassname));

	if (!szClassname[0])
		copy(szClassname, charsmax(szClassname), DEFAULT_SPRITE_CLASSNAME);

	new Float:flUpOffset = (iParams >= arg_up_offset) ? get_param_f(arg_up_offset) : 0.0;

	return CSprite__CreateEntity(pPlayer, szModel, flSpriteScale, flStartFrame, flHoldTime, szClassname, flUpOffset);
}

stock CSprite__CreateEntity(const pPlayer, const szModel[], Float:flSpriteScale, Float:flStartFrame, Float:flHoldTime = 0.0, const szClassname[] = DEFAULT_SPRITE_CLASSNAME, Float:flUpOffset = 0.0)
{
	if (!szModel[0] || !file_exists(szModel) || !is_user_alive(pPlayer)) {
		return NULLENT;
	}

	new pEntity = NULLENT;

	if (rg_find_ent_by_owner(pEntity, szClassname, pPlayer) && !is_nullent(pEntity))
	{
		static Float: flGameTime; flGameTime = get_gametime();

		if (Float: get_entvar(pEntity, var_fade_end) > 0.0)
		{
			set_entvar(pEntity, var_fade_end, 0.0);
			set_entvar(pEntity, var_renderamt, 255.0);
		}

		if (flHoldTime > 0.0)
			set_entvar(pEntity, var_end_time, flGameTime + flHoldTime);
		else
			set_entvar(pEntity, var_end_time, -1.0);

		return pEntity;
	}

	pEntity = rg_create_entity(szInfoTargetReference);
	if (is_nullent(pEntity)) { return NULLENT; }

	static Float: flGameTime; flGameTime = get_gametime();

	new Float: flMaxFrame = float(engfunc(EngFunc_ModelFrames, engfunc(EngFunc_ModelIndex, szModel)));

	if (flStartFrame < 0.0 || flStartFrame >= flMaxFrame) { flStartFrame = 0.0; }

	// Entity
	set_entvar(pEntity, var_classname, szClassname);
	set_entvar(pEntity, var_movetype, MOVETYPE_NONE);
	set_entvar(pEntity, var_owner, pPlayer);
	// set_entvar(pEntity, var_aiment, pPlayer);
	set_entvar(pEntity, var_end_time, (flHoldTime > 0.0) ? (flGameTime + flHoldTime) : 0.0);

	// Frames
	set_entvar(pEntity, var_framerate, flMaxFrame);
	set_entvar(pEntity, var_max_frame, flMaxFrame);
	set_entvar(pEntity, var_start_frame, flStartFrame);
	set_entvar(pEntity, var_frame, flStartFrame);
	set_entvar(pEntity, var_last_time, flGameTime);
	set_entvar(pEntity, var_fuser2, flUpOffset);

	// Model
	set_entvar(pEntity, var_scale, flSpriteScale);
	engfunc(EngFunc_SetModel, pEntity, szModel);
	UTIL_SetEntityRendering(pEntity, _, _, kRenderTransAdd, 255.0);

	if (ArrayFindString(g_aSpriteClasses, szClassname) == -1)
		ArrayPushString(g_aSpriteClasses, szClassname);

	Entity_SetThink(pEntity, "CSprite__Think", flGameTime + SPRITE_NEXTTHINK);

	return pEntity;
}

stock Entity_SetThink(const pEntity, const szCallBack[ ] = "", const Float: flNextThink = 0.0, const aData[ ] = "", const iDataLen = 0)
{
	SetThink(pEntity, szCallBack, aData, iDataLen);
	set_entvar(pEntity, var_nextthink, flNextThink);
}

public CSprite__Think(const pSprite)
{
	if(is_nullent(pSprite)) { return; }

	static Float:flGameTime; flGameTime = get_gametime();
	set_entvar(pSprite, var_nextthink, flGameTime + SPRITE_NEXTTHINK);

	static Float:flFadeEnd; flFadeEnd = Float: get_entvar(pSprite, var_fade_end);
	if (flFadeEnd > 0.0)
	{
		if (flFadeEnd <= flGameTime)
		{
			UTIL_KillEntity(pSprite);
			return;
		}

		set_entvar(pSprite, var_renderamt, 255.0 * ((flFadeEnd - flGameTime) / SPRITE_FADE_TIME));

		new pOwner = get_entvar(pSprite, var_owner);
		if (is_user_alive(pOwner))
		{
			new Vector3(vecFadeOrigin); get_entvar(pOwner, var_origin, vecFadeOrigin);
			vecFadeOrigin[2] += Float: get_entvar(pSprite, var_fuser2);
			engfunc(EngFunc_SetOrigin, pSprite, vecFadeOrigin);
		}

		return;
	}

	new pUser = get_entvar(pSprite, var_owner);
	if(!is_user_alive(pUser))
	{
		UTIL_StartFade(pSprite, flGameTime);
		return;
	}

	new Vector3(vecOrigin); get_entvar(pUser, var_origin, vecOrigin);
	vecOrigin[2] += Float: get_entvar(pSprite, var_fuser2);
	engfunc(EngFunc_SetOrigin, pSprite, vecOrigin);

	static Float:flFrame, Float:flFrameRate, Float:flMaxFrame, Float:flStartFrame, Float:flLastTime, Float:flEndTime;

	flFrame = get_entvar(pSprite, var_frame);
	flFrameRate = get_entvar(pSprite, var_framerate);
	flMaxFrame = get_entvar(pSprite, var_max_frame);
	flStartFrame = get_entvar(pSprite, var_start_frame);
	flLastTime = get_entvar(pSprite, var_last_time);
	flEndTime = get_entvar(pSprite, var_end_time);

	if (flEndTime > 0.0 && flEndTime <= flGameTime)
	{
		UTIL_StartFade(pSprite, flGameTime);
		return;
	}

	flFrame += (flGameTime - flLastTime) * flFrameRate;

	if(flFrame >= flMaxFrame)
	{
		if (flEndTime > 0.0)
		{
			flFrame = flStartFrame;
		}
		else
		{
			UTIL_StartFade(pSprite, flGameTime);
			return;
		}
	}

	set_entvar(pSprite, var_frame, flFrame);
	set_entvar(pSprite, var_last_time, flGameTime);
}

/* -> Start the smooth fade-out <- */
stock UTIL_StartFade(const pEntity, const Float:flGameTime)
{
	set_entvar(pEntity, var_fade_end, flGameTime + SPRITE_FADE_TIME);
}

/* -> Destroy Entity <- */
stock UTIL_KillEntity(const pEntity)
{
	set_entvar(pEntity, var_flags, FL_KILLME);
	set_entvar(pEntity, var_nextthink, get_gametime());
}

/* -> Set Entity Rendering <- */
stock UTIL_SetEntityRendering(const pEntity, const iRenderFx = kRenderFxNone, const Float:flRenderColor[3] = { 255.0, 255.0, 255.0 }, const iRenderMode = kRenderNormal, const Float: flRenderAmount = 16.0)
{
	set_entvar(pEntity, var_renderfx, iRenderFx);
	set_entvar(pEntity, var_rendercolor, flRenderColor);
	set_entvar(pEntity, var_rendermode, iRenderMode);
	set_entvar(pEntity, var_renderamt, flRenderAmount);
}
