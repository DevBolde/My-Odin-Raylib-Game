package main
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

// Game states
GameState :: enum {
    PLAYING,
    LEVEL_COMPLETE,
    WON,
}

// Level structure
Level :: struct {
    platforms: []rl.Vector2,
    collectibles: []rl.Vector2,
    spawn_point: rl.Vector2,
    level_name: string,
}

sprite_width: i32 = 16   // Adjust based on your spritesheet
sprite_height: i32 = 16
character_pos := rl.Vector2{90, 600}
move_speed: f32 = 200 // Made this faster for testing
character_off_ground: bool 
ground_y: f32 = 600  // Ground level
jump_velocity: f32 
scale: f32 = 3.0 // Scale factor (3x larger)
sprite_height_scale:f32 = f32(sprite_height) * scale
sprite_width_scale:f32 = f32(sprite_width) * scale
character_hit_wall: bool
character_on_platform: bool
character_eat: bool
game_state: GameState = .PLAYING
current_level_index: int = 0

main :: proc() {
    rl.InitWindow(1280, 720, "My Game")
    defer rl.CloseWindow()
    
    rl.InitAudioDevice()
    defer rl.CloseAudioDevice()

    spritesheet := rl.LoadTexture("assets/16x16_Jerom_CC-BY-SA-3.0.png")
    defer rl.UnloadTexture(spritesheet) 

    background_sound := rl.LoadSound("assets/bgPlasma_sound.wav")
    defer rl.UnloadSound(background_sound)
    
    walking_sound := rl.LoadSound("assets/07064246.wav") 
    defer rl.UnloadSound(walking_sound)

    flying_sound := rl.LoadSound("assets/bat_wings.wav")
    defer rl.UnloadSound(flying_sound)
    
    jump_sound := rl.LoadSound("assets/short_jump.wav")
    defer rl.UnloadSound(jump_sound)

    background_texture := rl.LoadTexture("assets/parallax-mountain-bg.png")
    defer rl.UnloadTexture(background_texture)

    ground_texture := rl.LoadTexture("assets/parallax-mountain-trees.png")
    defer rl.UnloadTexture(ground_texture)

    // Define all levels
    levels := []Level{
        // Level 1 - Original level
        {
            platforms = {
                {300, 575},   // Original platform
                {400, 475},   // First staircase platform
                {450, 425},   // Second staircase platform  
                {500, 375},   // Third staircase platform
                {550, 325},   // Fourth staircase platform
                {600, 275},   // Fifth staircase platform
                {650, 225},   // Sixth staircase platform
                {700, 175},   // Seventh staircase platform
                {750, 125},   // Eighth staircase platform
                {800, 75},    // Ninth staircase platform
                {850, 25},    // Tenth staircase platform
            },
            collectibles = {
                {1050, 400},  // Original collectible position
            },
            spawn_point = {90, 600},
            level_name = "Mountain Climb",
        },
        
        // Level 2 - New challenging level
        {
            platforms = {
                {200, 550},   // First jump
                {400, 450},   // Second jump
                {150, 350},   // Jump back left
                {500, 300},   // Long jump right
                {350, 200},   // Jump back
                {700, 150},   // Another long jump
                {900, 250},   // Jump up
                {1100, 400},  // Final platform
            },
            collectibles = {
                {1100, 350},  // On the final platform
            },
            spawn_point = {50, 600},
            level_name = "Zigzag Challenge",
        },
        
        // Level 3 - Vertical challenge
        {
            platforms = {
                {100, 550},
                {300, 500},
                {500, 450},
                {700, 400},
                {500, 350},
                {300, 300},
                {100, 250},
                {300, 200},
                {500, 150},
                {700, 100},
            },
            collectibles = {
                {700, 50},   // At the very top
            },
            spawn_point = {25, 600},
            level_name = "Tower Ascent",
        },
    }

    // To get a specific sprite, calculate its position in the grid
    get_sprite_asset :: proc(row, col: i32, sprite_w, sprite_h: i32) -> rl.Rectangle {
        return rl.Rectangle{
            x = f32(col * sprite_w),
            y = f32(row * sprite_h), 
            width = f32(sprite_w),
            height = f32(sprite_h)
        }
    }

    rec_maker :: proc(x, y, height, width: f32) -> rl.Rectangle{
        make_rec := rl.Rectangle{
            x = x,
            y = y,
            height = height,
            width = width,
        }
        return make_rec
    }

    check_collision :: proc(rec1, rec2: rl.Rectangle, jump_sound: rl.Sound){
        if rl.CheckCollisionRecs(rec1, rec2) {
            // Check if character is mostly above the rec2
            character_center_y := rec1.y + rec1.height/2
            plat_center_y := rec2.y + rec2.height/2
            
            if character_center_y < plat_center_y {
                // Land on top of rec2
                character_pos.y = rec2.y - sprite_height_scale
                character_off_ground = false
                character_on_platform = true
                jump_velocity = 0
              
               if rl.IsKeyPressed(.SPACE) && character_on_platform {
                jump_velocity = -400
                character_off_ground = true
                rl.PlaySound(jump_sound)
            } 

            } else {
                // Side collision - push character away horizontally
                character_center_x := rec1.x + rec1.width/2
                platform_center_x := rec2.x + rec2.width/2
                
                if character_center_x < platform_center_x {
                    // Push left
                    character_pos.x = rec2.x - sprite_width_scale
                } else {
                    // Push right
                    character_pos.x = rec2.x + rec2.width
                }
            }
        }
    }

    load_level :: proc(level_index: int, levels: []Level) {
        if level_index >= len(levels) do return
        
        current_level := levels[level_index]
        character_pos = current_level.spawn_point
        character_off_ground = false
        character_on_platform = false
        character_eat = false
        jump_velocity = 0
    }

    rl.SetSoundVolume(background_sound, 0.25)
    rl.SetSoundVolume(flying_sound, 0.3)
    rl.SetSoundVolume(jump_sound, 0.3)
    rl.PlaySound(background_sound)

    rl.SetTargetFPS(60)
    
    // Load first level
    load_level(current_level_index, levels)
    
   //GAME LOOP 
    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime() // Delta time is crucial for frame-rate independent movement and animation
        
        rl.BeginDrawing()
        rl.ClearBackground(rl.GRAY)

        // Check if win conditions are met
        if game_state == .WON {
            // Draw end screen
            rl.DrawText("YOU WIN ALL LEVELS!", 300, 300, 48, rl.YELLOW)
            rl.DrawText("Press ENTER to restart or ESC to quit", 350, 400, 24, rl.WHITE)
            
            // Handle restart
            if rl.IsKeyPressed(.ENTER) {
                // Reset everything
                current_level_index = 0
                game_state = .PLAYING
                load_level(current_level_index, levels)
            }
            
            rl.EndDrawing()
            continue // Skip the rest of the game logic
        }

        if game_state == .LEVEL_COMPLETE {
            current_level := levels[current_level_index]
            rl.DrawText("LEVEL COMPLETE!", 400, 250, 48, rl.GREEN)
            level_name_cstr := strings.clone_to_cstring(current_level.level_name)
            defer delete(level_name_cstr)
            rl.DrawText(level_name_cstr, 450, 320, 32, rl.WHITE)
            rl.DrawText("Press SPACE for next level", 420, 400, 24, rl.WHITE)
            
            if rl.IsKeyPressed(.SPACE) {
                current_level_index += 1
                if current_level_index >= len(levels) {
                    // All levels completed
                    game_state = .WON
                } else {
                    // Load next level
                    load_level(current_level_index, levels)
                    game_state = .PLAYING
                }
            }
            
            rl.EndDrawing()
            continue
        }

        // Normal gameplay continues here (only when game_state == .PLAYING)
        current_level := levels[current_level_index]
        
        // Background Textures
        rl.DrawTextureEx(background_texture, {0, 0}, 0, 1280.0/f32(background_texture.width), rl.WHITE) 
        rl.DrawTextureEx(ground_texture, {0, 380}, 0, 1280.0/f32(ground_texture.width), rl.WHITE)

        // Draw level name
        level_name_cstr := strings.clone_to_cstring(current_level.level_name)
        defer delete(level_name_cstr)
        rl.DrawText(level_name_cstr, 10, 10, 24, rl.WHITE)
        level_text := fmt.aprintf("Level %d/%d", current_level_index + 1, len(levels))
        level_text_cstr := strings.clone_to_cstring(level_text)
        defer delete(level_text_cstr)
        rl.DrawText(level_text_cstr, 10, 40, 20, rl.WHITE)

        // Create sprites
        bat_sprite := get_sprite_asset(21, 21, sprite_width, sprite_height)
        platform_sprite := get_sprite_asset(1, 1, sprite_width, sprite_height)
        collectible_sprite := get_sprite_asset(30, 30, sprite_width, sprite_height)

        // Make character rectangle 
        bat_rect := rec_maker(character_pos.x, character_pos.y, sprite_width_scale, sprite_height_scale) 

        // Draw character
        rl.DrawTexturePro(spritesheet, bat_sprite, bat_rect, {0, 0}, 0, rl.WHITE)

        // Draw all platforms for current level
        for platform_pos in current_level.platforms {
            platform_rect := rec_maker(platform_pos.x, platform_pos.y, sprite_height_scale, sprite_width_scale)
            rl.DrawTexturePro(spritesheet, platform_sprite, platform_rect, {0,0}, 0, rl.WHITE)
            check_collision(bat_rect, platform_rect, jump_sound)
        }

        // Draw all collectibles for current level (if not eaten)
        if !character_eat {
            for collectible_pos in current_level.collectibles {
                collectible_rect := rec_maker(collectible_pos.x, collectible_pos.y, sprite_height_scale, sprite_width_scale)
                rl.DrawTexturePro(spritesheet, collectible_sprite, collectible_rect, {0,0}, 0, rl.WHITE)
                
                // Check collision with collectibles
                if rl.CheckCollisionRecs(bat_rect, collectible_rect) {
                    character_eat = true
                    game_state = .LEVEL_COMPLETE
                }
            }
        }

        // Jump & Jump-sound logic
        if rl.IsKeyPressed(.SPACE) && !character_off_ground {
            jump_velocity = -400
            character_off_ground = true
            rl.PlaySound(jump_sound)
        } 

       //Apply gravity and velocity 
        if character_off_ground {
            jump_velocity += 900 * dt
            character_pos.y += jump_velocity * dt
        }

        // check for landing
        if character_pos.y >= ground_y{
            character_pos.y = ground_y
            character_off_ground = false
            jump_velocity = 0
        }
        
        // Movement and sound logic with character comparison operators
        if (rl.IsKeyPressed(.L) || rl.IsKeyPressed(.H)) && !character_off_ground || character_on_platform{
            rl.PlaySound(flying_sound)
        }

        // Restart flying sound when landing while still holding movement keys
        if !character_off_ground  && (rl.IsKeyDown(.L) || rl.IsKeyDown(.H)) && !rl.IsSoundPlaying(flying_sound) {
            rl.PlaySound(flying_sound)
        }
        
        // Restart flying sound when landing while still holding movement keys
        if character_on_platform  && (rl.IsKeyDown(.L) || rl.IsKeyDown(.H)) && !rl.IsSoundPlaying(flying_sound) {
            rl.PlaySound(flying_sound)
        }
        if rl.IsKeyDown(.L) && !character_hit_wall{
            character_pos.x += move_speed * dt
            if character_pos.x > 1280 - 50 {
                character_pos.x = 1280 - 50
            }
        }
        if rl.IsKeyDown(.H) && !character_hit_wall{
            character_pos.x -= move_speed * dt  // Changed += to -=
            if character_pos.x < 0 {            // Changed boundary check
                character_pos.x = 0
            }
        }        
        if (rl.IsKeyReleased(.L) || rl.IsKeyReleased(.H)) || character_off_ground == true {
            rl.StopSound(flying_sound)
        }
        
        rl.EndDrawing() 
    }
}