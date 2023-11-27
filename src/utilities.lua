
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


function printdebug()
    printh("CPU: "..stat(1))
end
