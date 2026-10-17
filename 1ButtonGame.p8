pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- drum game prototype

notes = {}
score = 0
lives = 3
game_over = false
spawn_timer = 0
hit_timer = 0
hit_color = 11

target_x = 104
target_y = 64

function _init()
    notes = {}
    score = 0
    lives = 3
    game_over = false
    spawn_timer = 0
    hit_timer = 0
    hit_color = 11
end

function spawn_note()
    add(notes, {
        x = 8,
        y = target_y,
        speed = 1.2,
        judged = false,
        color = 6
    })
end

function _update()
    if game_over then
        return
    end

    spawn_timer += 1

    -- creates a note periodically
    if spawn_timer >= 75 then
        spawn_note()
        spawn_timer = 0
    end

    -- moves notes to the target
    for n in all(notes) do
        n.x += n.speed

        -- note missed
        if not n.judged and n.x > target_x + 5 then
            n.judged = true
            n.color = 8
            lives -= 1

            if lives <= 0 then
                lives = 0
                game_over = true
            end
        end
    end

    -- pressing x
    if btnp(5) then
        hit_timer = 8
        hit_color = 11

        local best = nil
        local best_dist = 999

        for n in all(notes) do
            if not n.judged then
                local dist = abs(n.x - target_x)

                if dist < best_dist then
                    best = n
                    best_dist = dist
                end
            end
        end

        if best and best_dist <= 6 then
            best.judged = true
            best.color = 11
            score += 1
        else
            hit_color = 8
        end
    end

    -- hit indicator timer
    if hit_timer > 0 then
        hit_timer -= 1
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

    -- score
    print("drum game", 4, 4, 7)
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
    line(target_x, target_y - 12,
         target_x, target_y + 12, 7)

    -- notes
    for n in all(notes) do
        circfill(n.x, n.y, 3, n.color)
    end

    -- show hit
    if hit_timer > 0 then
        circfill(110, 96, 5, hit_color)
    end

    print("x = hit", 38, 118, 6)

    -- game over screen
    if game_over then
        rectfill(20, 45, 108, 80, 1)
        rect(20, 45, 108, 80, 8)
        print("keep practicing!", 36, 54, 8)
        print("score: "..score, 38, 65, 7)
    end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
