monster = {
    x = 12,
    y = 96,
    sprites = {128,129,144,145},
    delay=60,
    currentcolor=1,
    frames=12,
    currentframe=1,
    xmod=-1,
    ymod=-1,
    anims={
        {
            {128,129,144,145},{130,131,146,147}
        },
        {
            {132,133,148,149},{134,135,150,151}
        },
        {
            {160,161,176,177},{162,163,178,179}
        },
        {
            {164,165,180,181},{166,167,182,183}
        }
    }
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

        self.y+=self.ymod
        if self.y<=game.level.pitcoords[1][2]+11 or self.y>=game.level.pitcoords[2][2]-4
        then
            self.ymod=-1*self.ymod
        end
    end
    if game.frame%self.frames==0 
    then 
        self.sprites=self.anims[self.currentcolor][self.currentframe]
        self.currentframe=self.currentframe%2+1 
    end

    if (game.frame%30==0) self.currentcolor+=1
    if (self.currentcolor>4) self.currentcolor=1
end

function monster:draw()
    spr(self.sprites[1], self.x, self.y)
    spr(self.sprites[2], self.x+8, self.y)
    if self.y < game.level.pitcoords[2][2]-8
    then
        spr(self.sprites[3], self.x, self.y+8)
        spr(self.sprites[4], self.x+8, self.y+8)
    end

    -- draw the green gunge over the sprite
    local cellcoords=utilities.point_coords_to_cells(game.level.pitcoords[2][1],game.level.pitcoords[2][2])

    for x=1,3 do
        spr(68,game.level.pitcoords[2][1]-32+x*8,game.level.pitcoords[2][2]) 
    end
    
end

