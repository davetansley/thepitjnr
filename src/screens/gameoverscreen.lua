gameoverscreen = {
    showfor=300,
    timer=0
}

function gameoverscreen:init()
    -- set state functions
    update=function ()
        gameoverscreen:update()
    end
    draw=function ()
        gameoverscreen:draw()
    end
end

function gameoverscreen:update()

    if self.timer >= self.showfor then 
        self.timer = 0
        titlescreen:init()   
    end 
    self.timer+=1
    
end

function gameoverscreen:draw()
    cls(0)

    screen:draw_scores()
    screen:draw_highscores()
    local linebase = 7
    utilities.print_text("game over", linebase, 12)

end

