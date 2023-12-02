titlescreen = {
    blocks = "1,3,2,3,3,3,4,3,5,3,6,3,9,3,10,3,11,3,12,3,13,3,14,3,"
            .."2,4,6,4,13,4,"
            .."2,5,6,5,13,5,"
            .."2,6,3,6,4,6,5,6,6,6,13,6,"
            .."2,7,9,7,13,7,"
            .."2,8,13,8,"
            .."2,9,9,9,13,9,"
            .."2,10,9,10,13,10,"
            .."2,11,9,11,13,11,"
            .."2,12,9,12,13,12",
    showfor=150,
    timer=0

}

function titlescreen:init()
    -- set state functions
    update=function ()
        titlescreen:update()
    end
    draw=function ()
        titlescreen:draw()
    end
end

function titlescreen:update()
    
    if self.timer >= self.showfor 
    then
        self.timer=0 
        instructions:init() 
    end 
    self.timer+=1

    if (btn(5)) livesscreen:init()
end

function titlescreen:draw()
    cls(1)

    local thexbase = 8
    local theybase = 14
    local jnrxbase = 86
    local jnrybase = 106
    
    spr(80,thexbase,theybase)
    spr(81,thexbase+9,theybase)
    spr(82,thexbase+18,theybase)

    spr(83,jnrxbase,jnrybase)
    spr(84,jnrxbase+9,jnrybase)
    spr(85,jnrxbase+18,jnrybase)

    local blockarray=split(titlescreen.blocks)
    for x=1,#blockarray,2 do 
        spr(78,blockarray[x]*8,blockarray[x+1]*8)
    end

    print("press ❎ to start",30,120,7)
end
