entity = {} 

-- the entity class constructor
function entity:new(o) 
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function entity:draw()
    spr(self.sprite,self.x,self.y)
end
