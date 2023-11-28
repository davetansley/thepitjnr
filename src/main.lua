-- init
function _init()
    initgame()

    --New stuff
    initialise_game()
end

-- update
function _update()
    -- New stuff
    for r in all(rocks) do
        r:update()
    end

    for r in all(bombs) do
        r:update()
    end

    checkplayer()
    checklocation()
    checkcamera()

end

-- draw
function _draw()

    cls()

    -- draw map and set camera
    map(0,0,0,8,16,24)
    camera(0,view.y)

    -- draw digs
    drawdigs()

    -- New stuff
    for r in all(rocks) do
        r:draw()
    end

    for r in all(bombs) do
        r:draw()
    end

    for r in all(diamonds) do
        r:draw()
    end

    -- draw player
    spr(p.sprite,p.x,p.y)

    -- if player is digging, draw effect
    if p.activity==1 and p.activityframes>0 then flashsquare(p.dir) end

    -- score panel
    drawscorepanel()

    -- zonk text
    drawzonk()

    --printdebug()
end