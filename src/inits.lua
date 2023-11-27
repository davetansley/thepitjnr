
-------------------------------------------
-- inits
-------------------------------------------
function initgame()

    -- config variables
    score={}
    score.diamond=10

    -- player variables
    p={}   --the player table
    p.score=0 -- key for storing score
    p.highscore=9999 -- key for storing high score
    p.lives=3 -- key for storing lives

    -- viewport variables
    view={}
    view.y=0 -- key for tracking the viewport

    -- general variables
    animframes=6

    -- dig array
    digarray={}

    -- rockarrays - {x, y, falling state, sprite}
    rockarray={{32,32,0,71},{48,48,0,71},{48,64,0,71},{48,72,0,71},{56,80,0,71}
        ,{80,80,0,71},{88,80,0,71},{72,72,0,71},{88,56,0,71},{56,104,0,71},{40,112,0,71}
        ,{72,120,0,71}
        ,{24,168,0,71},{8,160,0,71}}
    --    rockarray={{32,32,0,71}}
    currentrockarray={}

    -- bombarrays - {x, y, falling state, sprite}
    bombarray={{40,160,0,73},{48,160,0,73},{56,160,0,73},{64,160,0,73},{72,160,0,73},
                {80,160,0,73},}

    currentbombarray={}

    -- diamondarrays - {x, y, sprite, offset}
    diamondarray={{40,184,0,75,0,0},{56,184,0,75,1,0},{64,184,0,75,2,0},{80,184,0,75,0,0}}

    currentdiamondarray={}

    caverncoords={{40,160},{80,184}}
    pitcoords={{8,72},{32,104}}

    initlife()
end

-- Reset after life is lost
function initlife()
    p.x=16 --key for the x variable
    p.y=24 --key for the y variable
    p.dir=0 --key for the direction: 0 right, 1 left, 2 up, 3 down
    p.sprite=0 -- key for the sprite
    p.oldsprite=0 -- key for storing the old sprite
    p.framecount=0 -- key for frame counting
    p.framestomove=0 -- key for frames left in current move
    p.activity=0 -- key for player activity. 0 moving, 1 digging, 2 shooting, 3 squashing
    p.activityframes=0 -- key for frames in current activity
    p.incavern=0 -- key for whether player is in the diamond cavern
    p.inpit=0 -- key for whether player is in the pit

    view.y=0

    digarray={}
    initdirtarray()

    currentbombarray=copyarray(bombarray)
    currentdiamondarray=copyarray(diamondarray)
    currentrockarray=copyarray(rockarray)
end