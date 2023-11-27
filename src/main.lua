-- init
function _init()
    initgame()
end

-- update
function _update()
    checkrocks()
    checkbombs()
    checkplayer()
    checklocation()
    checkcamera()
end

-- draw
function _draw()
    drawscreen()
end