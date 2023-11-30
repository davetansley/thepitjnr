screen = {
    tiles = {},

    init = function (self)
        populate_map(self)
    end,
    update = function (self)
        checkcamera()
    end,
    draw = function (self)
        cls()

        -- draw map and set camera
        map(0,0,0,0,16,24)
        camera(0,view.y)
        
        -- draw dirt
        draw_dirt()
    end,
    draw_zonk = function(self)
        rectfill(player.x-9,player.y+1,player.x+14,player.y+7,1)
        print("ZONK!!", player.x-8,player.y+2,7)
    end,
    draw_scores = function(self)
        rectfill(1,1+view.y,42,7+view.y,1)
        rectfill(90,1+view.y,126,7+view.y,1)
        print("score "..padnumber(player.score),2,2+view.y,7)
        print("high "..padnumber(player.highscore), 91,2+view.y,7)
    end
}

-- Walk the map and replace any entity sprites
-- Store details about each tile in the map array, initialise any dirt tiles
function populate_map(screen)
    screen.tiles={}
    for y = 0,23 do
        screen.tiles[y]={}
        for x = 0,15 do
            local sprite = mget(x,y)

            local tile = {}
            tile.sprite=sprite
            tile.block=0
            tile.dirty=0
            tile.dirt=""

            if sprite==71 -- rock
            then
                mset(x,y,255)
                create_rock(x,y)
            elseif sprite==73 -- bomb
            then
                mset(x,y,255)
                create_bomb(x,y)
            elseif sprite==75 -- diamond
            then
                mset(x,y,255)
                create_diamond(x,y)
            elseif sprite== 70 -- dirt
            then
                -- initialise a dirt tile
                tile.dirt="11111111" -- each character represents a line of dirt, if 0 it has been removed
            elseif sprite== 64 -- dirt
            then
                tile.block=1
            end 

            screen.tiles[y][x] = tile

        end
    end
end

-- walk the map array
-- if a tile is a dirt tile and is dirty, then walk its dirt value and clear any pixels on rows set to 1
function draw_dirt()
    for y = 0,23 do
        for x = 0,15 do
            local tile=screen.tiles[y][x]
            for d = 1, #tile.dirt do 
                if sub(tile.dirt,d,d)=="0" 
                then 
                    -- set this row to black
                    local x1=x*8
                    local y1=y*8+(d-1) 
                    for p=x1,x1+7 do
                        pset(p,y1,0)
                    end
                end
            end
        end 
    end

end

function checkcamera()

    -- check for need to reset camera
    if player.y>=96 and view.y==0 then view.y=64 end
    if player.y<=88 and view.y==64 then view.y=0 end

end

function showgameover()
    printh("game over")
    cls()
    print("Game over!")
end
