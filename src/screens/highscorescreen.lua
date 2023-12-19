highscorescreen = {
    scoretext = "",
    scorepos=0,
    initials={"a","a","a"},
    currentinitial=1,
    allcharsarray=split "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,1,2,3,4,5,6,7,8,9,0, ,!,?",
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
    
    -- determine position
    local scorepos,scoretext=3,"3rd best"
    if player.score>highscores[1].score
    then
        scorepos, scoretext = 1,"greatest"
    elseif player.score>=highscores[2].score
    then
        scorepos, scoretext = 2,"2nd best"
    end

    self.initials,self.currentinitial,self.currentchar,self.scorepos,self.scoretext = 
        {"a","a","a"},1,1,scorepos,scoretext
end

function highscorescreen:update()

    if self.cooldown > 0
    then 
        self.cooldown-=1
        return
    end

    if btn(2)
    then 
        self.currentchar+=1
        if (self.currentchar>#self.allcharsarray) self.currentchar=1
        self.initials[self.currentinitial],self.cooldown=self.allcharsarray[self.currentchar],10
    elseif btn(3) then 
        self.currentchar-=1
        if (self.currentchar<1) self.curre,ntchar=#self.allcharsarray
        self.initials[self.currentinitial],self.cooldown=self.allcharsarray[self.currentchar],10
    elseif btn(5) 
    then
        self.currentinitial+=1
        self.currentchar,self.cooldown=1,30
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
        -- save scores
        self:save_scores()
        gameoverscreen:init()
    end
end

function highscorescreen:load_scores()
    -- load high score table
    local savedscores = dget(0)
    if (savedscores!=0)
    then
        for x=0,8,4 do
            highscores[(x+4)/4]={
                score=dget(x),
                name=self.allcharsarray[dget(x+1)]..self.allcharsarray[dget(x+2)]..self.allcharsarray[dget(x+3)]
            } 
        end
    end
end

function highscorescreen:save_scores()
    local mem=0
    for r in all(highscores) do 
        dset(mem,r.score)
        local namearray=self:encode_name(r.name)
        for x=1,3 do 
            dset(mem+x,namearray[x])
        end
        mem+=4
    end
end

function highscorescreen:encode_name(name)
    local result = {}
    for x=1, 3 do 
        for y=1,#self.allcharsarray do 
            if (self.allcharsarray[y]==sub(name,x,x)) add(result,y)
        end
    end
    return result
end

function highscorescreen:draw()
    cls(0)
    screen:draw_scores()
    screen:draw_highscores()

    utilities.print_texts("congratulations,4,14,player 1,6,14,you have earned,9,8,the "..self.scoretext.." score,11,8,record your initials below,13,10")
    for x=1,3 do
        local col=10
        if (self.currentinitial==x) col=11
        print(self.initials[x], 50+6*x, 90, col) 
    end
end

