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
        self.score,self.scoretext,self.fullscore=scores.triplebonus,"triple bonus",scores.triplebonus
    elseif player.diamonds==3
    then
        self.score,self.scoretext,self.fullscore=scores.doublebonus,"double bonus",scores.doublebonus
    else
        self.score,self.scoretext,self.fullscore=scores.singlebonus,"single bonus",scores.singlebonus
    end
end

function levelendscreen:update()

    if self.timer >= self.showfor then 
        self.timer = 0
        if game.currentlevel>8
        then
            congratulationsscreen:init()
        else
            game:switchto()  
        end 
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
            utilities:sfx(5) 
        end
    end

    self.frame+=1
end

function levelendscreen:draw()
    cls(11)

    screen:draw_scores()
    utilities.print_texts("congratulations,5,1,player 1,7,1,you have earned,10,2,"..self.scoretext..",12,10,"..self.fullscore.." points,14,2,have another go,16, 8")

end

