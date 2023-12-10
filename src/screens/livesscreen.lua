livesscreen = {
    showfor=90,
    timer=0
}

function livesscreen:init()
    -- set state functions
    update=function ()
        livesscreen:update()
    end
    draw=function ()
        livesscreen:draw()
    end
    if game.state==game_states.waiting
    then
        player:init()
    end
    utilities:sfx(6)
end

function livesscreen:update()

    if self.timer >= self.showfor then 
        self.timer = 0
        if game.state==game_states.waiting
        then
            game:init()
        else
            game:switchto()     
        end 
    end
    self.timer+=1
end

function livesscreen:draw()
    cls(1)

    rectfill(46,11,79,17,0)
    local livestext = "last man"
    if (player.lives != 0) livestext = ""..(player.lives+1).." men left"
    utilities.print_texts("player 1,2,7,"..livestext..",5,10")
    
end

