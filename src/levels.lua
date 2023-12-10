-- robotspeed,robots,tankspeed,missilespeed,bridgespeed,robotspawnrate
-- robotspeed - 1 fastest
-- robots - number spawned at one time
-- tankspeed - frames before next shot (divide by 60 for seconds, 28 total shots - tankspeed 60 = 28 seconds)
-- missilespeed - percentage chance of falling per frame
-- bridgespeed - 1 fastest
-- robotspawnrate - frames till next spawn
levels={
    caverncoords={{40,144},{80,184}},
    pitcoords={{8,64},{24,104}}, 
    {
        settings="6,2,180,0.5,4,300"  
    },
    {
        settings="5,3,180,0.6,3,300"  
    },
    {
        settings="4,3,150,0.7,3,200"  
    },
    {
        settings="3,3,150,0.8,3,200"  
    },
    {
        settings="3,4,150,0.9,2,200"  
    },
    {
        settings="2,4,120,1.0,2,150"  
    },
    { 
        settings="2,4,120,1.5,1,150"  
    },
    {
        settings="1,4,120,0.5,1,100" 
    }
}
