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
    utilities.print_text("player 1",2,7)

    if player.lives==0 
    then
        utilities.print_text("last man", 5, 10)
    else
        utilities.print_text(""..(player.lives+1).." men left", 5, 10)
    end
    
end

