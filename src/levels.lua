-- robotspeed,robots,tankspeed,missilespeed,bridgespeed,robotspawnrate,rockwobbletime
-- robotspeed - 1 fastest
-- robots - number spawned at one time
-- tankspeed - frames before next shot (divide by 60 for seconds, 28 total shots - tankspeed 60 = 28 seconds)
-- missilespeed - chance of falling per frame, out of 60
-- bridgespeed - 1 fastest
-- robotspawnrate - frames till next spawn
-- rock wobble time - frames that rock will wobble
levels={
    caverncoords={{40,144},{80,184}},
    pitcoords={{8,64},{24,104}}, 
    {
        settings="6,2,180,1,3,300,80,first dig"  
    },
    {
        settings="5,3,180,1,2,300,80,greed trap"  
    },
    {
        settings="4,3,150,2,2,200,80,dark shaft"  
    },
    {
        settings="3,3,150,2,2,200,90,rock run"  
    },
    {
        settings="4,2,150,3,2,200,80,unstable"  
    },
    {
        settings="4,2,150,3,2,150,80,plan ahead"  
    },
    { 
        settings="3,3,150,4,2,350,80,dirt maze"  
    },
    {
        settings="2,2,150,8,2,150,80,robo shrine" 
    }
}
