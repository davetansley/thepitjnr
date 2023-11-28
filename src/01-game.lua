function initialise_game()

    local level = levels[1]
    
    -- reload the map
    reload(0x1000, 0x1000, 0x2000)

    -- Populate entities
    rocks={}
    bombs={}
    diamonds={}

    populate_map()
end