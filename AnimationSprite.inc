#if defined _AnimationSpriteHead_included
	#endinput
#endif
#define _AnimationSpriteHead_included

/*
* Precache a sprite head model for use with the zh_set_user_sprite native.
*/
native zh_precache_sprite(const szModel[]);

/*
* Sets the sprite head for a player.
* @param UserId      Player id
* @param szModel     Sprite model path
* @param SpriteScale Scale of the sprite
* @param StartFrame  Starting frame of the sprite animation

* @param lifetime    Hold time of the sprite in seconds: the animation loops until it expires.
*                    0.0 = play the animation once, then the sprite is removed
* @param szClassname Custom sprite classname. Sprites with the same classname on the same
*                    player overwrite each other; a different classname creates a separate
*                    sprite layer (e.g. a second sprite positioned lower)
* @param flUpOffset  Vertical offset from the player origin (45.0 = above the head,
*                    0.0 = model center)
*
* @note The frame count is always taken from the model itself automatically
*
* @return            Sprite entity index, NULLENT on failure
*/
native zh_set_user_sprite(const UserId, const szModel[], Float:SpriteScale = 1.0, Float:StartFrame = 0.0, Float:lifetime = 0.0, const szClassname[] = "env_sprite_head", Float:flUpOffset = 35.0);