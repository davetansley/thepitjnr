instructions = {
    showfor=600,
    timer=0
}

function instructions:init()
    -- set state functions
    update=function ()
        instructions:update()
    end
    draw=function ()
        instructions:draw()
    end
end

function instructions:update()

    if self.timer >= self.showfor then 
        self.timer = 0
        game:init_demo() 
    end 
    self.timer+=1
    
    if (btn(5)) livesscreen:init()
end

function instructions:draw()
    cls(0)

    utilities.print_texts("the objective of this, 0, 7,game is to dig down, 1, 7,to the bottom pit and, 2, 7,collect at least, 3, 7,one large jewel, 4, 7,then return to ship, 5, 7,thru the upper pit, 6, 7,single bonus "..scores.singlebonus.." points, 8, 10,collect one large jewel, 9, 7,double bonus "..scores.doublebonus.." points, 11, 12,collect all three large jewels, 12, 7,or all four small jewels, 13, 7,triple bonus "..scores.triplebonus.." points, 15, 8,collect all seven large jewels, 16, 7")
    screen:draw_highscores()
end

