
------------------------------------------
-- Utilities
------------------------------------------
function padnumber(input)
    output=tostr(input)
    local l=#output
    for x=l,3 do 
        output="0"..output
    end
    return output
end


function copyarray(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[copyarray(orig_key)] = copyarray(orig_value)
        end
        setmetatable(copy, copyarray(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- Convert box coords in pixels to cells
-- Returns array of {x1,y1,x2,y2}
function box_coords_to_cells(x1,y1,x2,y2)
    local coords1 = point_coords_to_cells(x1,y1)
    local coords2 = point_coords_to_cells(x2,y2)

    return {coords1[1],coords1[2],coords2[1],coords2[2]}
end

-- Convert a point in pixels to cells
-- Returns {x,y} array
function point_coords_to_cells(x,y)
    -- Subtract one from the y value to account for score panel
    return {flr(x/8),flr(y/8)}
end

function printdebug()
    printh("CPU: "..stat(1))
end
