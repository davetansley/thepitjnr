utilities = {
    lowest_pfr = -1
}

function utilities.pad_number(input)
    output=tostr(input)
    local l=#output
    for x=l,4 do 
        output="0"..output
    end
    return output
end


function utilities.copy_array(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[utilities.copy_array(orig_key)] = utilities.copy_array(orig_value)
        end
        setmetatable(copy, utilities.copy_array(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- Convert box coords in pixels to cells
-- Returns array of {x1,y1,x2,y2}
function utilities.box_coords_to_cells(x1,y1,x2,y2)
    local coords1 = utilities.point_coords_to_cells(x1,y1)
    local coords2 = utilities.point_coords_to_cells(x2,y2)

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
    local coords = {}
    local ymod1 = -1
    local ymod2 = 8
    if dig == 1
    then
        ymod1=-8
        ymod2=15
    else
    end

    if dir==0 then coords={x+8, x+15, y, y+7} end -- right
    if dir==1 then coords={x-8, x-1, y, y+7} end -- left
    if dir==2 then coords={x, x+7, y+ymod1, y-1} end -- up
    if dir==3 then coords={x, x+7, y+8, y+ymod2} end -- down
    
    return coords
end


function utilities:print_debug()
    if self.lowest_pfr == -1 or stat(9) < utilities.lowest_pfr
    then
        self.lowest_pfr = stat(9)
    end
    printh(" FR: "..stat(7).." TFR: "..stat(8).." PFR: "..stat(9).." LowPFR: "..utilities.lowest_pfr.." CPU: "..stat(1))
end

function utilities.print_text(text, line, colour)
    local ydelta=6
    local x = 64 - 4*(#text/2)
    print(text, x, ydelta*line,colour)
end
