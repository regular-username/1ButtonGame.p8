pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- drum game prototype

notes = {}
score = 0
lives = 3
game_over = false

hit_timer = 0
hit_color = 11

message = ""
message_timer = 0
message_color = 7

start_screen = true

anim_frame = 0
anim_timer = 0

target_x = 104
target_y = 64

-- rhythm patterns
-- 1 = drum note
-- 0 = silence

rhythm_patterns = {
    {0, 0, 0, 0}, -- 1: ----
    {1, 0, 0, 0}, -- 2: •---
    {1, 0, 1, 0}, -- 3: •-•-
    {1, 0, 0, 1}, -- 4: •--•
    {1, 1, 1, 1}  -- 5: ••••
}

rhythm_type = 1
rhythm_step = 1
last_rhythm_type = 0

-- timing at 110 bpm
beat_timer = 0
beat_length = 1800 / 110

-- hit timing settings
hit_window = 6
near_line_window = 18

-- initialize game
function _init()
    notes = {}
    score = 0
    lives = 3
    game_over = false

    hit_timer = 0
    hit_color = 11

    message = ""
    message_timer = 0
    message_color = 7

    start_screen = true

    anim_frame = 0
    anim_timer = 0

    rhythm_type = 1
    rhythm_step = 1
    last_rhythm_type = 0
    last_beat_was_hit = false
    beat_timer = 0
end

-- restart game
function restart_game()
    notes = {}
    score = 0
    lives = 3
    game_over = false

    hit_timer = 0
    hit_color = 11

    message = ""
    message_timer = 0
    message_color = 7

    anim_frame = 0
    anim_timer = 0

    rhythm_type = 1
    rhythm_step = 1
    last_rhythm_type = 0
    last_beat_was_hit = false
    beat_timer = 0

    start_screen = false
    music(0)
end

-- spawn a note
function spawn_note()
    local note_speed = 1.2

    add(notes, {
        x = target_x - note_speed * beat_length * 4,
        y = target_y,
        speed = note_speed,
        judged = false,
        color = 6
    })
end

-- lose one life
function lose_life()
    lives -= 1

    if lives <= 0 then
        lives = 0
        game_over = true
    end
end

-- choose a rhythm based on score
function choose_rhythm()
    local r = rnd(1)
    local max_type = 5

    if score < 5 then
        -- beginner: mostly simple rhythms
        max_type = 4

        if r < 0.15 then
            rhythm_type = 1
        elseif r < 0.65 then
            rhythm_type = 2
        elseif r < 0.85 then
            rhythm_type = 3
        else
            rhythm_type = 4
        end

    elseif score < 15 then
        -- intermediate: balanced variety
        if r < 0.15 then
            rhythm_type = 1
        elseif r < 0.38 then
            rhythm_type = 2
        elseif r < 0.63 then
            rhythm_type = 3
        elseif r < 0.83 then
            rhythm_type = 4
        else
            rhythm_type = 5
        end

    else
        -- advanced: all rhythms remain possible
        if r < 0.15 then
            rhythm_type = 1
        elseif r < 0.35 then
            rhythm_type = 2
        elseif r < 0.60 then
            rhythm_type = 3
        elseif r < 0.80 then
            rhythm_type = 4
        else
            rhythm_type = 5
        end
    end

    -- avoid repeating the same rhythm twice
    if rhythm_type == 5 and
    last_rhythm_type == 5 then
       rhythm_type = 3
    end

    last_rhythm_type = rhythm_type
end

function _update()

    -- start screen
    if start_screen then
        if btnp(5) then
            start_screen = false

            rhythm_type = 1
            rhythm_step = 1
            last_rhythm_type = 0
            beat_timer = 0

            music(0)
        end

        return
    end

    -- retry after game over
    if game_over then
        if btnp(5) then
            restart_game()
        end

        return
    end

    -- animate character
    if anim_frame > 0 then
        anim_timer -= 1

        if anim_timer <= 0 then
            if anim_frame < 3 then
                anim_frame += 1
                anim_timer = 5
            else
                anim_frame = 0
            end
        end
    end

    -- rhythm clock
    beat_timer += 1

    if beat_timer >= beat_length then
        beat_timer -= beat_length

        -- choose a new rhythm every four beats
        if rhythm_step == 1 then
           if last_beat_was_hit then
           rhythm_type = 1
        else
            choose_rhythm()
        end
     end

        -- spawn notes only on active beats
        if rhythm_patterns[rhythm_type][rhythm_step] == 1 then
            spawn_note()
        end
        
        last_beat_was_hit =
           rhythm_patterns [rhythm_type]
           [rhythm_step] == 1

        rhythm_step += 1

        if rhythm_step > 4 then
            rhythm_step = 1
        end
    end

    -- move notes and check misses
    for n in all(notes) do
        n.x += n.speed

        if not n.judged and n.x > target_x + 5 then
            n.judged = true
            n.color = 8

            lose_life()

            message = "miss!"
            message_color = 8
            message_timer = 30
        end
    end

    -- pressing x plays the drum
    if btnp(5) then
        sfx(3)

        hit_timer = 8
        hit_color = 11

        anim_frame = 1
        anim_timer = 5

        local best = nil
        local best_dist = 999

        -- find the nearest unjudged note
        for n in all(notes) do
            if not n.judged then
                local dist = abs(n.x - target_x)

                if dist < best_dist then
                    best = n
                    best_dist = dist
                end
            end
        end

        if best and best_dist <= hit_window then
            -- successful hit
            best.judged = true
            best.color = 11

            score += 1

            message = "hit!"
            message_color = 11
            message_timer = 30

        else
            -- wrong timing
            hit_color = 8

            lose_life()

            message = "miss!"
            message_color = 8
            message_timer = 30

            -- prevent losing another life for the same note
            if best and best_dist <= near_line_window then
                best.judged = true
                best.color = 8
            end
        end
    end

    -- hit indicator timer
    if hit_timer > 0 then
        hit_timer -= 1
    end

    -- message timer
    if message_timer > 0 then
        message_timer -= 1
    else
        message = ""
    end

    -- delete notes outside screen
    for n in all(notes) do
        if n.x > 128 then
            del(notes, n)
        end
    end
end

function _draw()
    cls(1)

    -- start screen
    if start_screen then
        print("the drum game", 35, 32, 7)
        print("one button rhytm game", 22, 46, 6)

        line(28, 60, 100, 60, 5)

        print("press x to start", 25, 76, 11)
        print("get ready to drum!", 23, 92, 7)

        return
    end

    -- title and score
    print("the drum game", 4, 4, 7)
    print("score: "..score, 82, 4, 7)

    -- lives
    print("lives:", 4, 14, 7)

    for i = 1, 3 do
        if i <= lives then
            print("x", 42 + i * 8, 14, 7)
        else
            print("x", 42 + i * 8, 14, 8)
        end
    end

    -- target line
    line(0, target_y, 127, target_y, 5)

    line(
        target_x, target_y - 12,
        target_x, target_y + 12,
        7
    )

    -- notes
    for n in all(notes) do
        circfill(n.x, n.y, 3, n.color)
    end

    -- animated character
    local frame = 1

    if anim_frame > 0 then
        frame = anim_frame
    end

    sspr(
        frame * 8, 0, 8, 8,
        12, 82, 28, 28
    )

    -- hit indicator
    if hit_timer > 0 then
        circfill(110, 96, 5, hit_color)
    end

    print("x = hit", 38, 118, 6)

    -- hit or miss message
    if message_timer > 0 then
        print(message, 48, 96, message_color)
    end

    -- game over screen
    if game_over then
        rectfill(20, 42, 108, 86, 1)
        rect(20, 42, 108, 86, 8)

        print("keep practicing!", 27, 50, 8)
        print("score: "..score, 38, 61, 7)
        print("x = retry", 38, 73, 11)
    end
end
__gfx__
00000000114114111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000141111414441144441111114000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007004ffffff41ffffff114111141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000ffffffffffffffff1f4ff4f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700099ffff9999ffff99ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700899999988999999899ffff99000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000889889888898898889999998000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000189889811898898188988988000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00020000000502a0502a0502a0502a050000502304023040230402304000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040
000200001f0302103021030210201e020220202203022030220301f03000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030
000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002d3602a460283602546022360204601d3601a460170600006000060000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050
000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 00020202
00 01020202
00 01020202
02 01020202

