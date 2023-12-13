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
    colors=split "8,10,14",
    newcolors=split "8,10,14",
    possiblecolors=split "2,3,4,5,6,8,9,10,11,12,13,14,15"
}

monster=entity:new(monster)

function monster:update()
    if self.delay > 0
    then
        self.delay-=1
        return
    end

    if game.frame%2==0
    then
        -- work out new coords here
        if game.frame%4==0
        then
            self.x+=self.xmod
            if self.x<=levels.pitcoords[1][1] or self.x>=levels.pitcoords[2][1]-8
            then
                self.xmod=-1*self.xmod
            end
        end
        -- slow down rise above certain point
        if self.y<=levels.pitcoords[1][2]+15 then self.y += self.ymod else self.y+=self.ymod*3 end

        if self.y<=levels.pitcoords[1][2]+10 or self.y>=levels.pitcoords[2][2]-4
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
    if self.y >= levels.pitcoords[2][2]-8 and self.delay == 0
    then
        self.newcolors = utilities.generate_pallete(self.possiblecolors)
    end 

    -- swap palette
    for x=1,3 do
        pal(self.colors[x],self.newcolors[x])
    end
    
    if self.y < levels.pitcoords[2][2]-8
    then
        height=2
    end

    spr(self.sprites[self.currentframe],self.x,self.y,2,height)

    -- draw the green gunge over the sprite
    local cellcoords=utilities.point_coords_to_cells(levels.pitcoords[2][1],levels.pitcoords[2][2])

    for x=1,3 do
        spr(68,levels.pitcoords[2][1]-24+x*8,levels.pitcoords[2][2]) 
    end
    pal()
    
end


