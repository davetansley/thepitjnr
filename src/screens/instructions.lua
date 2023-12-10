instructions = {
    showfor=300,
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

    utilities.print_texts("the object, 0, 7,of this game, 1, 7,is to dig down, 2, 7,to the bottom pit, 3, 7,and, 4, 7,collect at least, 5, 7,one large jewel, 6, 7,then, 7, 7,return to ship, 8, 7,thru upper pit, 9, 7,single bonus "..scores.singlebonus.." points, 11, 10,collect one large jewel, 12, 7,and return to ship, 13, 7,double bonus "..scores.doublebonus.." points, 15, 12,collect all three large jewels, 16, 7,or all four small jewels, 17, 7,triple bonus "..scores.triplebonus.." points, 19, 8,collect all seven large jewels, 20, 7")
end

