monster = {
    x = 12,
    y = 96,
    sprites = {128,130},
    delay=60,
    currentcolor=1,
    frames=12,
    currentframe=1,
    xmod=-1,
    ymod=-1,
    colors={8,10,14},
    newcolors={8,10,14},
    possiblecolors={2,3,4,5,6,8,9,10,11,12,13,14,15}
}

function monster:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function monster:update()
    if self.delay > 0
    then
        self.delay-=1
        return
    end

    if game.frame%2==0
    then
        -- work out new coords here
        self.x+=self.xmod
        if self.x<=game.level.pitcoords[1][1] or self.x>=game.level.pitcoords[2][1]-16
        then
            self.xmod=-1*self.xmod
        end

        -- slow down rise above certain point
        if self.y<=game.level.pitcoords[1][2]+15 then self.y += self.ymod else self.y+=self.ymod*3 end

        if self.y<=game.level.pitcoords[1][2]+10 or self.y>=game.level.pitcoords[2][2]-4
        then
            self.ymod=-1*self.ymod
        end
    end
    if game.frame%self.frames==0 
    then 
        self.currentframe=self.currentframe%2+1 
    end

    if (game.frame%30==0) self.currentcolor+=1
    if (self.currentcolor>4) self.currentcolor=1
end

function monster:draw()
    local height=1

    -- generate new colors
    if self.y >= game.level.pitcoords[2][2]-8 and self.delay == 0
    then
        self:generate_pallete()
    end 

    -- swap palette
    pal(self.colors[1],self.newcolors[1])
    pal(self.colors[2],self.newcolors[2])
    pal(self.colors[3],self.newcolors[3])
    
    if self.y < game.level.pitcoords[2][2]-8
    then
        height=2
    end

    spr(self.sprites[self.currentframe],self.x,self.y,2,height)

    -- draw the green gunge over the sprite
    local cellcoords=utilities.point_coords_to_cells(game.level.pitcoords[2][1],game.level.pitcoords[2][2])

    for x=1,3 do
        spr(68,game.level.pitcoords[2][1]-32+x*8,game.level.pitcoords[2][2]) 
    end
    pal()
    
end

function monster:generate_pallete()
    local i1,i2,i3,found = 0,0,0,0

    while found == 0 do 
        i1 = flr(rnd(#self.possiblecolors))+1
        i2 = flr(rnd(#self.possiblecolors))+1
        i3 = flr(rnd(#self.possiblecolors))+1
        if (i1 != i2 and i1 != i3) found = 1
    end
    self.newcolors={self.possiblecolors[i1],self.possiblecolors[i2],self.possiblecolors[i3]}
end

