screen = {
    tiles = {},
    mapx = 0
}

view = {
    y = 0
}

function screen:init()
    self.mapx=16*(game.currentlevel-1)
    screen:populate_map()
    camera(0,view.y)  
end

function screen:update()
    screen:check_camera()
end

function screen:draw()
    cls()
    -- draw map and set camera
    map(self.mapx,0,0,0,16,24)
    camera(0,view.y)    
    -- draw dirt
    screen:draw_dirt()
    screen:draw_bridge()
    if (game.demo==1) utilities.print_text("demo",3.5,12,1)
end

function screen:draw_bridge()
    for x=0, game.bridge-1 do
        pset(levels.pitcoords[1][1]+x,levels.pitcoords[1][2]+8,8)
        pset(levels.pitcoords[1][1]+x,levels.pitcoords[1][2]+9,8)
    end
end

function screen:draw_zonk()
    rectfill(player.x-9,player.y+1,player.x+14,player.y+7,10)
    print("zonk!!", player.x-8,player.y+2,0)
end

function screen:draw_scores()
    rectfill(1,1+view.y,47,7+view.y,1)
    rectfill(85,1+view.y,126,7+view.y,1)
    local highscore = highscores[1].score
    if (player.score > highscore) highscore = player.score
    print("score "..utilities.pad_number(player.score),2,2+view.y,7)
    print("high "..utilities.pad_number(highscore), 86,2+view.y,7)
end

function screen:draw_highscores()
    print("best scores today",30,110+view.y,12)

    for x=1,#highscores do 
        print(highscores[x].name.." "..utilities.pad_number(highscores[x].score),4+40*(x-1),118+view.y,8+(x-1))
    end

end

-- Walk the map and replace any object sprites
-- Store details about each tile in the map array, initialise any dirt tiles
function screen:populate_map()
    self.tiles={}
    for y = 0,23 do
        self.tiles[y]={}
        for x = 0,15 do
            local sprite = mget(x+self.mapx,y)

            local tile = {}
            tile.sprite,tile.block,tile.dirty,tile.dirt=sprite,0,0,""
            
            if sprite==71 -- rock
            then
                mset(x+self.mapx,y,255)
                local r = rock:new()
                r:set_coords(x,y)
                add(rocks,r)
                add(game.objects,r)
            elseif sprite==73 -- bomb
            then
                mset(x+self.mapx,y,255)
                local b = bomb:new()
                b:set_coords(x,y)
                add(bombs,b)
                add(game.objects,b)
            elseif sprite==75 -- diamond
            then
                mset(x+self.mapx,y,255)
                local d = diamond:new()
                d:set_coords(x,y)
                add(diamonds,d)
                add(game.objects,d)
            elseif sprite==86 -- gem
            then
                mset(x+self.mapx,y,255)
                local g = gem:new()
                g:set_coords(x,y)
                add(gems,g)
                add(game.objects,g)
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
                    local x1,y1=x*8,y*8+(d-1)
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
    if player.y>=96 and player.state!=player_states.falling then view.y=64 end
    if game.state==game_states.waiting or player.y<=80 then view.y=0 end
end
