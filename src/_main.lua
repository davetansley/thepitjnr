cart_id="thepitjnrv1"

-- init
function _init()
    cartdata(cart_id)

    highscorescreen:load_scores()

    titlescreen:init()
end

-- update
function _update60()
    update()
    --utilities:print_debug()
end

-- draw
function _draw()
    draw()
end
