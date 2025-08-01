package main
import "core:fmt"
import rl "vendor:raylib"

// Game states
GameState :: enum {
    PLAYING,
    LEVELCOMPLETE,
    WON,
}

sprite_width: i32 = 16   // Adjust based on your spritesheet
sprite_height: i32 = 16
character_pos := rl.Vector2{90, 600}
platform_pos:= rl.Vector2{300, 575} 
plat_pos:= rl.Vector2{1050, 400}
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
            //fall off platform if not standing on it
            if character_pos.x < platform_pos.x || character_pos.x > platform_pos.x && character_on_platform == true{
                character_off_ground = true
            }
        }
    }

    rl.SetSoundVolume(background_sound, 0.25)
    rl.SetSoundVolume(flying_sound, 0.3)
    rl.SetSoundVolume(jump_sound, 0.3)
    rl.PlaySound(background_sound)

    rl.SetTargetFPS(60)
    
   //GAME LOOP 
    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime() // Delta time is crucial for frame-rate independent movement and animation
        
        rl.BeginDrawing()
        rl.ClearBackground(rl.GRAY)

        // Check game state
        if game_state == .WON {
            // Draw end screen
            rl.DrawText("YOU WIN!", 400, 300, 72, rl.YELLOW)
            rl.DrawText("Press ENTER to restart or ESC to quit", 350, 400, 24, rl.WHITE)
            
            // Handle restart
            if rl.IsKeyPressed(.ENTER) {
                // Reset game state
                game_state = .PLAYING
                character_eat = false
                character_pos = rl.Vector2{90, 600}
                character_off_ground = false
                character_on_platform = false
                jump_velocity = 0
            }
            
            rl.EndDrawing()
            continue // Skip the rest of the game logic
        }

        if game_state == .LEVELCOMPLETE{

            rl.DrawTextureEx(background_texture, {0, 0}, 0, 1280.0/f32(background_texture.width), rl.WHITE) 
            rl.DrawTextureEx(ground_texture, {0, 380}, 0, 1280.0/f32(ground_texture.width), rl.WHITE)
            bat_sprite := get_sprite_asset(21, 21, sprite_width, sprite_height)
            platform_sprite := get_sprite_asset(1, 1, sprite_width, sprite_height)
            plat_sprite := get_sprite_asset(30, 30, sprite_width, sprite_height)

            // Make Rectangle 
            bat_rect := rec_maker(character_pos.x, character_pos.y, sprite_width_scale, sprite_height_scale) 
            platform := rec_maker(platform_pos.x, platform_pos.y, sprite_height_scale, sprite_width_scale)
            plat := rec_maker(plat_pos.x, plat_pos.y, sprite_height_scale, sprite_width_scale)

            rl.DrawTexturePro(spritesheet, bat_sprite, bat_rect, {0, 0}, 0, rl.WHITE)
            rl.DrawTexturePro(spritesheet, platform_sprite, platform, {0,0}, 0, rl.WHITE)
            
            rl.EndDrawing()
            continue
        }

        // Normal gameplay continues here (only when game_state == .PLAYING)
        // Background Textures
        rl.DrawTextureEx(background_texture, {0, 0}, 0, 1280.0/f32(background_texture.width), rl.WHITE) 
        rl.DrawTextureEx(ground_texture, {0, 380}, 0, 1280.0/f32(ground_texture.width), rl.WHITE)

        // Create a specific sprite for a RECTANGLE (row 0, column 3 for example)
        bat_sprite := get_sprite_asset(21, 21, sprite_width, sprite_height)
        platform_sprite := get_sprite_asset(1, 1, sprite_width, sprite_height)
        plat_sprite := get_sprite_asset(30, 30, sprite_width, sprite_height)

        // Make Rectangle 
        bat_rect := rec_maker(character_pos.x, character_pos.y, sprite_width_scale, sprite_height_scale) 
        platform := rec_maker(platform_pos.x, platform_pos.y, sprite_height_scale, sprite_width_scale)
        plat := rec_maker(plat_pos.x, plat_pos.y, sprite_height_scale, sprite_width_scale)

        // Add Texture to Rectangles
        rl.DrawTexturePro(spritesheet, bat_sprite, bat_rect, {0, 0}, 0, rl.WHITE)
        rl.DrawTexturePro(spritesheet, platform_sprite, platform, {0,0}, 0, rl.WHITE)

        // Edible-textures
        if !character_eat{
            rl.DrawTexturePro(spritesheet, plat_sprite, plat, {0,0}, 0, rl.WHITE)
        }
        if rl.CheckCollisionRecs(bat_rect, plat) {
            character_eat = true
            game_state = .LEVELCOMPLETE // Change game state instead of calling end_screen
        }

        // Draw and handle collision for multiple platforms
        base_platform2 := rec_maker(platform_pos.x + 100, platform_pos.y - 100, sprite_height_scale, sprite_width_scale)

        for i := 0; i < 10; i += 1 {
            current_platform := base_platform2
            current_platform.x += f32(i) * 50  // Place platforms side by side
            
            // Draw this platform
            rl.DrawTexturePro(spritesheet, platform_sprite, current_platform, {0,0}, 0, rl.WHITE)
            
            // Check collision with this platform
            check_collision(bat_rect, current_platform, jump_sound)
        }

        // COLLISION
        check_collision(bat_rect, platform, jump_sound)

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