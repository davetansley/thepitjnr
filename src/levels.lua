-- robotspeed,robots,tankspeed,missilespeed,bridgespeed,robotspawnrate,rockwobbletime
-- robotspeed - 1 fastest
-- robots - number spawned at one time
-- tankspeed - frames before next shot (divide by 60 for seconds, 28 total shots - tankspeed 60 = 28 seconds)
-- missilespeed - percentage chance of falling per frame
-- bridgespeed - 1 fastest
-- robotspawnrate - frames till next spawn
-- rock wobble time - frames that rock will wobble
levels={
    caverncoords={{40,144},{80,184}},
    pitcoords={{8,64},{24,104}}, 
    {
        settings="6,2,18000,0.5,3,300,80,welcome"  
    },
    {
        settings="5,3,180,0.6,2,300,80,traps"  
    },
    {
        settings="4,3,150,0.6,2,200,80,shafts"  
    },
    {
        settings="3,3,150,0.6,2,200,90,chimney"  
    },
    {
        settings="3,4,150,0.7,1,200,80,name"  
    },
    {
        settings="2,4,120,1.0,1,150,80,name"  
    },
    { 
        settings="2,4,120,1.5,1,150,80,name"  
    },
    {
        settings="1,4,120,0.5,1,100,80,name" 
    }
}
