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
        titlescreen:init() 
    end 
    self.timer+=1
    
    if (btn(5)) livesscreen:init()
end

function instructions:draw()
    cls(0)
    utilities.print_text("the object", 0, 7)
    utilities.print_text("of this game", 1, 7)
    utilities.print_text("is to dig down", 2, 7)
    utilities.print_text("to the bottom pit", 3, 7)
    utilities.print_text("and", 4, 7)
    utilities.print_text("collect at least", 5, 7)
    utilities.print_text("one large jewel", 6, 7)
    utilities.print_text("then", 7, 7)
    utilities.print_text("return to ship", 8, 7)
    utilities.print_text("thru upper pit", 9, 7)
    utilities.print_text("single bonus "..scores.singlebonus.." points", 11, 10)
    utilities.print_text("collect one large jewel", 12, 7)
    utilities.print_text("and return to ship", 13, 7)
    utilities.print_text("double bonus "..scores.doublebonus.." points", 15, 12)
    utilities.print_text("collect all three large jewels", 16, 7)
    utilities.print_text("or all four small jewels", 17, 7)
    utilities.print_text("triple bonus "..scores.triplebonus.." points", 19, 8)
    utilities.print_text("collect all seven large jewels", 20, 7)
     
end

