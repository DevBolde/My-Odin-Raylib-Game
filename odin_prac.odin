package main
import "core:fmt"
import rl "vendor:raylib"

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

    // Define the size of each sprite (you need to measure/count pixels)
    sprite_width: i32 = 16   // Adjust based on your spritesheet
    sprite_height: i32 = 16
    // To get a specific sprite, calculate its position in the grid
    get_sprite_asset :: proc(row, col: i32, sprite_w, sprite_h: i32) -> rl.Rectangle {
        return rl.Rectangle{
            x = f32(col * sprite_w),
            y = f32(row * sprite_h), 
            width = f32(sprite_w),
            height = f32(sprite_h)
        }
    }
    rl.SetSoundVolume(background_sound, 0.25)
    rl.SetSoundVolume(flying_sound, 0.3)
    rl.PlaySound(background_sound)

    rl.SetTargetFPS(60)
    character_pos := rl.Vector2{90, 600}
    platform_pos:= rl.Vector2{300, 575} 
    move_speed: f32 = 200 // Made this faster for testing
    character_off_ground: bool 
    ground_y: f32 = 600  // Ground level
    jump_velocity: f32 
    scale: f32 = 3.0 // Scale factor (3x larger)
    sprite_height_scale:f32 = f32(sprite_height) * scale
    sprite_width_scale:f32 = f32(sprite_width) * scale
    character_hit_wall: bool
    character_on_platform: bool
    
    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime() // Delta time is crucial for frame-rate independent movement and animation
        rl.BeginDrawing()
        rl.ClearBackground(rl.GRAY)

        // Background Textures
        rl.DrawTextureEx(background_texture, {0, 0}, 0, 1280.0/f32(background_texture.width), rl.WHITE) 
        rl.DrawTextureEx(ground_texture, {0, 380}, 0, 1280.0/f32(ground_texture.width), rl.WHITE)

        // Draw a specific sprite (row 0, column 3 for example)
        bat_sprite := get_sprite_asset(21, 21, sprite_width, sprite_height)
        dest_rect := rl.Rectangle{
            x = character_pos.x,
            y = character_pos.y,
            width = sprite_width_scale,
            height = sprite_height_scale
        }
       rl.DrawTexturePro(spritesheet, bat_sprite, dest_rect, {0, 0}, 0, rl.WHITE)

       platform_sprite := get_sprite_asset(1, 1, sprite_width, sprite_height)
       platform := rl.Rectangle{
            x = platform_pos.x,
            y = platform_pos.y, 
            width = sprite_width_scale,
            height = sprite_height_scale
       }
       rl.DrawTexturePro(spritesheet, platform_sprite, platform, {0,0}, 0, rl.WHITE)

       // reset collision
       character_hit_wall = false

        // }// Alternative simpler approach if you prefer:
        if rl.CheckCollisionRecs(dest_rect, platform) {
            // Check if character is mostly above the platform
            character_center_y := dest_rect.y + dest_rect.height/2
            platform_center_y := platform.y + platform.height/2
            
            if character_center_y < platform_center_y {
                // Land on top of platform
                character_pos.y = platform.y - sprite_height_scale
                character_off_ground = false
                character_on_platform = true
                jump_velocity = 0
            } else {
                // Side collision - push character away horizontally
                character_center_x := dest_rect.x + dest_rect.width/2
                platform_center_x := platform.x + platform.width/2
                
                if character_center_x < platform_center_x {
                    // Push left
                    character_pos.x = platform.x - sprite_width_scale
                } else {
                    // Push right
                    character_pos.x = platform.x + platform.width
                }
            }
            if character_pos.x < platform_pos.x || character_pos.x > platform_pos.x && character_on_platform == true{
                character_off_ground = true
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
        
        // Movement and sound logic with corcharacter comparison operators
        if rl.IsKeyPressed(.L) || rl.IsKeyPressed(.H) && character_off_ground == false {
            rl.PlaySound(flying_sound)
        }

        // Restart flying sound when landing while still holding movement keys
        if !character_off_ground && (rl.IsKeyDown(.L) || rl.IsKeyDown(.H)) && !rl.IsSoundPlaying(flying_sound) {
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
        if rl.IsKeyReleased(.L) || rl.IsKeyReleased(.H) || character_off_ground == true {
            rl.StopSound(flying_sound)
        }
        
        // Only one DrawRectangleV call needed
        // rl.DrawRectangleV(character_pos, {50, 50}, rl.BLACK)
        rl.EndDrawing()
    }
}