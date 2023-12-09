levelendscreen = {
    showfor=180,
    timer=0,
    score=0,
    scoretext="",
    fullscore=0,
    frame=0
}

function levelendscreen:init()
    -- set state functions
    update=function ()
        levelendscreen:update()
    end
    draw=function ()
        levelendscreen:draw()
    end

    -- work out score to give
    if player.diamonds==3 and player.gems==4
    then
        self.score=scores.triplebonus
        self.fullscore=scores.triplebonus
        self.scoretext="triple bonus"
    elseif player.diamonds==3
    then
        self.score=scores.doublebonus
        self.scoretext="double bonus"
        self.fullscore=scores.doublebonus
    else
        self.score=scores.singlebonus
        self.scoretext="single bonus"
        self.fullscore=scores.singlebonus
    end
end

function levelendscreen:update()

    if self.timer >= self.showfor then 
        self.timer = 0
        game:switchto()   
    end 
    if self.score==0
    then
        self.timer+=1
    else
        -- allocate score
        if self.frame%20==0 
        then
            local toadd=0
            if self.score<100 then toadd=self.score else toadd=100 end
            player.score+=toadd
            self.score-=toadd
            sfx(5) 
        end
    end

    self.frame+=1
end

function levelendscreen:draw()
    cls(11)

    screen:draw_scores()
    local linebase = 5
    utilities.print_text("congratulations", linebase, 1)
    utilities.print_text("player 1", linebase+2, 1)
    utilities.print_text("you have earned", linebase+5, 2)
    utilities.print_text(self.scoretext, linebase+7, 10)
    utilities.print_text(""..self.fullscore.." points", linebase+9, 2)
    utilities.print_text("have another go", linebase+11, 8)

end

