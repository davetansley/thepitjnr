screen = {
    tiles = {}
}

function screen:init()
    screen:populate_map()
    camera(0,view.y)  
end

function screen:update()
    screen:check_camera()
end

function screen:draw()
    cls()
    -- draw map and set camera
    map(0,0,0,0,16,24)
    camera(0,view.y)    
    -- draw dirt
    screen:draw_dirt()
end

function screen:draw_zonk()
    rectfill(player.x-9,player.y+1,player.x+14,player.y+7,10)
    print("zonk!!", player.x-8,player.y+2,0)
end

function screen:draw_scores()
    rectfill(1,1+view.y,47,7+view.y,1)
    rectfill(85,1+view.y,126,7+view.y,1)
    print("score "..utilities.pad_number(player.score),2,2+view.y,7)
    print("high "..utilities.pad_number(game.highscore), 86,2+view.y,7)
end

-- Walk the map and replace any entity sprites
-- Store details about each tile in the map array, initialise any dirt tiles
function screen:populate_map()
    self.tiles={}
    for y = 0,23 do
        self.tiles[y]={}
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
                local r = rock:new()
                r:set_coords(x,y)
                add(rocks,r)
            elseif sprite==73 -- bomb
            then
                mset(x,y,255)
                local b = bomb:new()
                b:set_coords(x,y)
                add(bombs,b)
            elseif sprite==75 -- diamond
            then
                mset(x,y,255)
                local d = diamond:new()
                d:set_coords(x,y)
                add(diamonds,d)
            elseif sprite==86 -- gem
            then
                mset(x,y,255)
                local g = gem:new()
                g:set_coords(x,y)
                add(gems,g)
            elseif sprite== 70 -- dirt
            then
                -- initialise a dirt tile
                tile.dirt="11111111" -- each character represents a line of dirt, if 0 it has been removed
            elseif sprite== 64 -- dirt
            then
                tile.block=1
            end 

            self.tiles[y][x] = tile

        end
    end
end

-- walk the map array
-- if a tile is a dirt tile and is dirty, then walk its dirt value and clear any pixels on rows set to 1
function screen:draw_dirt()
    for y = 0,23 do
        for x = 0,15 do
            local tile=self.tiles[y][x]
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

function screen:check_camera()
    -- check for need to reset camera
    if player.y>=96 and view.y==0 then view.y=64 end
    if player.y<=88 and view.y==64 then view.y=0 end
end
