function initialise_game()
    local level = levels[1]
    
    -- Populate rocks
    rocks={}
    for i=1,#level.rocks,2 do
        add_rock(level.rocks[i],level.rocks[i+1])
    end
end