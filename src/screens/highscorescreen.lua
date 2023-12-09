highscorescreen = {
    scoretext = "",
    scorepos=0,
    initials={"a","a","a"},
    currentinitial=1,
    allchars="a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,1,2,3,4,5,6,7,8,9,0, ,!,?",
    currentchar=1,
    cooldown=0
}

function highscorescreen:init()
    -- set state functions
    update=function ()
        highscorescreen:update()
    end
    draw=function ()
        highscorescreen:draw()
    end

    self.initials = {"a","a","a"}
    self.currentinitial = 1
    self.currentchar = 1

    -- determine position
    if player.score>highscores[1].score
    then
        self.scorepos, self.scoretext = 1,"greatest"
    elseif player.score>=highscores[2].score
    then
        self.scorepos, self.scoretext = 2,"2nd best"
    else
        self.scorepos, self.scoretext = 3,"3rd best"
    end
end

function highscorescreen:update()

    if self.cooldown > 0
    then 
        self.cooldown-=1
        return
    end

    local chars = split(self.allchars)
    if btn(2)
    then 
        self.currentchar+=1
        if (self.currentchar>#chars) self.currentchar=1
        self.initials[self.currentinitial]=chars[self.currentchar]
        self.cooldown=10
    elseif btn(3) then 
        self.currentchar-=1
        if (self.currentchar<1) self.currentchar=#chars
        self.initials[self.currentinitial]=chars[self.currentchar]
        self.cooldown=10
    elseif btn(5) 
    then
        self.currentinitial+=1
        self.currentchar=1
        self.cooldown=30
    end

    if self.currentinitial > 3
    then
        local score = {
            name = self.initials[1]..self.initials[2]..self.initials[3],
            score = player.score
        }
        if self.scorepos == 1
        then
            highscores[3]=highscores[2]
            highscores[2]=highscores[1]
            highscores[1]=score
        elseif self.scorepos == 2
        then
            highscores[3]=highscores[2]
            highscores[2]=score
        else
            highscores[3]=score
        end
        gameoverscreen:init()
    end
end

function highscorescreen:draw()
    cls(0)
    screen:draw_scores()
    screen:draw_highscores()
    local linebase = 4
    utilities.print_text("congratulations", linebase, 14)
    utilities.print_text("player 1", linebase+2, 14)
    utilities.print_text("you have earned", linebase+5, 8)
    utilities.print_text("the "..self.scoretext.." score", linebase+7, 8)
    utilities.print_text("record your initials below", linebase+9, 10)

    for x=1,3 do
        local col=10
        if (self.currentinitial==x) col=11
        print(self.initials[x], 50+6*x, 90, col) 
    end
end

