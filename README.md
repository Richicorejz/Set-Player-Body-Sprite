# Set-Player-Body-Sprite
A lightweight ReAPI-based plugin that attaches an animated sprite to any point of a player's body — above the head, on the chest, at the feet — via a configurable vertical offset. Intended for status icons or effects, and visual indicators in zombie or other gameplay mods.

## Features

- Per-player animated sprite that follows the player automatically (origin synced at 0.02 s)
- Each sprite has its own coordinates: an independent vertical offset per sprite, set individually for every layer
- Flexible vertical placement: any offset from the player origin — head, body, feet
- Frame count and framerate are taken from the model automatically — one full cycle always takes ~1 second
- Two play modes: loop for a given duration, or play once and auto-remove
- Smooth 0.5 s alpha fade-out before removal (kRenderTransAdd)
- Multiple independent sprite layers per player via custom classnames — e.g. one sprite above the head and another on the body at the same time
- Re-attaching a sprite reuses the entity: refreshes lifetime, cancels fade, no animation restart
- Sprites are cleaned up automatically on player death, round restart and plugin termination
- Safe model handling: missing model files are rejected before precache/spawn

## API

```pawn
// Precache a sprite model. Returns precache index, or 0 on failure
// (empty path / file not found).
native zh_precache_sprite(const szModel[]);

// Attach an animated sprite to a player. Returns sprite ent index,
// or NULLENT on failure (dead player / bad params / model not found).
native zh_set_user_sprite(const UserId, const szModel[], Float:SpriteScale = 1.0,
        Float:StartFrame = 0.0, Float:lifetime = 0.0,
        const szClassname[] = "env_sprite_head", Float:flUpOffset = 35.0);
// flUpOffset = vertical offset from the player origin:
//   35.0–45.0 ≈ above the head, 0.0 ≈ model center, negative = lower body/feet
```

## Example

```pawn
public plugin_precache()
{
    zh_precache_sprite("sprites/mymod/head_icon.spr");
    zh_precache_sprite("sprites/mymod/body_aura.spr");
}

// Icon above the head, loop for 5 seconds
zh_set_user_sprite(id, "sprites/mymod/head_icon.spr", 0.25, 0.0, 5.0, _, 40.0);

// Aura on the body (independent layer), play once
zh_set_user_sprite(id, "sprites/mymod/body_aura.spr", 0.6, 0.0, 0.0, "env_sprite_body", 0.0);
```

## Requirements

- AMX Mod X 1.9 or newer;
- ReAPI Module.
