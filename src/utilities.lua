utilities = {}

function utilities.pad_number(input)
    output=tostr(input)
    local l=#output
    for x=l,4 do 
        output="0"..output
    end
    return output
end

-- Convert box coords in pixels to cells
-- Returns array of {x1,y1,x2,y2}
function utilities.box_coords_to_cells(x1,y1,x2,y2)
    local coords1,coords2 = utilities.point_coords_to_cells(x1,y1),utilities.point_coords_to_cells(x2,y2)
    return {coords1[1],coords1[2],coords2[1],coords2[2]}
end

-- Convert a point in pixels to cells
-- Returns {x,y} array
function utilities.point_coords_to_cells(x,y)
    -- Subtract one from the y value to account for score panel
    return {flr(x/8),flr(y/8)}
end

-- get range of spaces adjacent to the place in the direction specified
-- if dig is 1, get the square vertically, otherwise just 8 pixels (horiz is always a square)
function utilities:get_adjacent_spaces(dir, dig, x, y)
    local coords,ymod1,ymod2 = {},-1,8
    if dig == 1
    then
        ymod1,ymod2=-8,15
    else
    end

    if dir==0 then coords={x+8, x+15, y, y+7} end -- right
    if dir==1 then coords={x-8, x-1, y, y+7} end -- left
    if dir==2 then coords={x, x+7, y+ymod1, y-1} end -- up
    if dir==3 then coords={x, x+7, y+8, y+ymod2} end -- down
    
    return coords
end

-- get range of spaces adjacent to the place in the direction specified
function utilities:get_adjacent_or_current_space(dir, x, y)
    local coords = {}

    if dir==0 then coords={x+1, y} end -- right
    if dir==1 then coords={x-1, y} end -- left
    if dir==2 then coords={x, y-1} end -- up
    if dir==3 then coords={x, y+8} end -- down
    
    return coords
end

-- checks for an overlap of two boxes
-- coords = {x1,x2,y1,y2} describing a shape with corners at x1,y1 and x2,y2
-- return 1 if overlap
function utilities:check_overlap(coords1,coords2)
    if coords1[1] < coords2[2] and coords2[1] <= coords1[2] and coords1[3] < coords2[4] and coords2[3] <= coords1[4]
    then
        return 1
    end           
    return 0
end

-- check a range of pixels that the object is about to move into
-- if can't move return 0
-- if can move return 1
function utilities:check_can_move(dir, coords, bullet)

    bullet=bullet or false
    
    -- if rock, can't move
    for r in all(rocks) do
        local coords2,overlap = {r.x,r.x+8,r.y,r.y+8}
        local overlap = utilities:check_overlap(coords,coords2)
        
        if (overlap==1) return 0
    end

    -- if bomb, can't move
    for b in all(bombs) do
        local coords2 = {b.x,b.x+8,b.y,b.y+8}
        local overlap = utilities:check_overlap(coords,coords2)
        
        if (overlap==1) return 0
    end

    -- if contains block or sky, can't move
    local cellcoords = utilities.box_coords_to_cells(coords[1],coords[3],coords[2],coords[4])
    local s1,s2=mget(cellcoords[1]+screen.mapx, cellcoords[2]),mget(cellcoords[3]+screen.mapx,cellcoords[4])
    if s1==64 or s2==64 or s1==65 or s2==65
    then
        return 0
    end

    -- if contains dirt, can't move
    local dirtfound=game:check_for_dirt(coords[1],coords[3],coords[2],coords[4],bullet)
    if (dirtfound==1) return 0
    -- otherwise, can move
    return 1
end

function utilities.print_text(text, line, colour, bgcolor)
    local ydelta,x,w=6,64 - 4*(#text/2),4*#text
    local y=ydelta*line
    if bgcolor
    then
        rectfill(x-1,y-1,x+w-1,y+5,bgcolor)
    end
    print(text,x,y,colour)
end

function utilities.print_texts(text)
    local items=split(text)
    for x=1,#items,3 do 
        utilities.print_text(items[x],tonum(items[x+1]),tonum(items[x+2]))
    end
end

-- generates a palette of three random colours from a selection passed as a parameter
function utilities.generate_pallete(possiblecolors)
    local i1,i2,i3,found = 0,0,0,0

    while found == 0 do 
        i1,i2,i3 = flr(rnd(#possiblecolors))+1,flr(rnd(#possiblecolors))+1,flr(rnd(#possiblecolors))+1
        if (i1 != i2 and i1 != i3) found = 1
    end
    return {possiblecolors[i1],possiblecolors[i2],possiblecolors[i3]}
end

function utilities:sfx(sound)
    if (game.demo==0) sfx(sound)
end

function utilities:contains (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end
    

