robot = {
    x = 112,
    y = 16,
    dir = 1, -- 0 right, 1, left, 2 up, 3 down
    flipx = true,
    sprites = {132,133,134,135},
    currentframe=1,
    colors={8,11,12},
    newcolors={8,11,12},
    possiblecolors={7,8,9,10,11,12,13,14}
}

function robot:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self:generate_pallete()

    return o
end

function robot:update()
    if self.dir == 0 
    then
        self.flipx = false 
    else
        self.flipx = true 
    end

    if game.frame%15 == 0
    then
        self.currentframe+=1
        if (self.currentframe > 4) self.currentframe = 1
    end
end

function robot:draw()
    
    pal(self.colors[1],self.newcolors[1])
    pal(self.colors[2],self.newcolors[2])
    pal(self.colors[3],self.newcolors[3])

    spr(self.sprites[self.currentframe], self.x, self.y, 1, 1, self.flipx )
    
    pal()
end

function robot:generate_pallete()
    local i1,i2,i3,found = 0,0,0,0

    while found == 0 do 
        i1 = flr(rnd(#self.possiblecolors))+1
        i2 = flr(rnd(#self.possiblecolors))+1
        i3 = flr(rnd(#self.possiblecolors))+1
        if (i1 != i2 and i1 != i3) found = 1
    end
    self.newcolors={self.possiblecolors[i1],self.possiblecolors[i2],self.possiblecolors[i3]}
end

