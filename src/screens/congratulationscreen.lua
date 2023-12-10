congratulationsscreen = {
    showfor=300,
    timer=0
}

function congratulationsscreen:init()
    -- set state functions
    update=function ()
        congratulationsscreen:update()
    end
    draw=function ()
        congratulationsscreen:draw()
    end
end

function congratulationsscreen:update()

    if self.timer >= self.showfor then 
        self.timer = 0
        if player.score > 0 and player.score >= highscores[3].score
        then
            highscorescreen:init()
        else
            gameoverscreen:init()
        end  
    end 
    self.timer+=1
end

function congratulationsscreen:draw()
    cls(0)

    screen:draw_scores()
    screen:draw_highscores()
    utilities.print_texts("congratulations!,7,12,you beat the pit,9,10,try again for a higher score,11,8")

end

