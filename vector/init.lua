local P = {} --package
--namespace
if _REQUIREDNAME == nil then
     vector = P
else
     _G[_REQUIREDNAME] = P
end

-- Imports:
local math     = require "math"
local table    = require "table"

math.randomseed( os.time() )

--error messages
local errs = {
     wrongDim = "",
     nonInteger = "n must be a positive integer",
}

--local vars
local defaultDim = 3
local mt

local function isValidVector(t)
     if #t == 0 then return false end
     for i, v in ipairs(t) do
          if type(v) ~= "number" then
               return false
          end
     end
     return true
end

local function sameDim(v1, v2)
     return #v1 == #v2
end

local function checkMeta(a, b)
     return getmetatable(a) == getmetatable(b)
end

local function doubleipairs(a, b)
     local i = 0
     return    function()
                    i = i + 1
                    if not a[i] and not b[i] then
                         return nil
                    end
                    return i, a[i], b[i]
               end
end

local function isPosInteger(n)
     return (n == math.floor(n) and n > 0)
end

function P.new(...)
     local args = {...}
     if not args[1] then 
          for i = 1, defaultDim do
               args[i] = 0 
          end
     end
     if isValidVector(args) then
          setmetatable( args, mt )
          return args
     else
          error( "not a valid vector", 2 )
     end
end

function P.random(n)
     --gives a random n dimensional unit vector
     n = n or P.getDefaultDim()
     if not isPosInteger(n) then
          error( err.notInteger, 2 )
     end
     local newV = {}
     for i = 1, n do
          newV[i] = math.random()
     end
     newV = P.new( table.unpack(newV) )
     return newV:normalize()
end

function P.getDefaultDim()
     return defaultDim
end

function P.setDefaultDim(n)
     if type(n) == "number" then
          if n > 0 and isPosInteger(n) then
               defaultDim = n
               return true
          end
     end
     error( err.notInteger, 2 )
end

function P.e(n, dim)
     --returns the unit vector in the nth dimension
     dim = dim or P.getDefaultDim()
     if n > dim then
          error( n.." is out of range ("..dim..")", 2 )
     end
     local newV = {}
     for i = 1, dim do
          newV[i] = 0
     end
     newV[n] = 1
     return P.new( table.unpack( newV ) )
end

--metatable stuffs
mt = {
     __metatable = "vector",
     __index = {
          dot = function(self, other)
               if not checkMeta(self, other) then
                    error( "attempt to dot vector with non-vector", 2 )
               elseif not sameDim(self, other) then
                    error( "attempt to dot vectors of different dimension", 2 )
               end
               local sum = 0
               for i, selfVal, otherVal in doubleipairs(self, other) do
                    sum = sum + selfVal * otherVal
               end
               return sum
          end,
          cross = function(self, other)
               if not checkMeta(self, other) then
                    error( "attempt to cross vector and non-vector", 2 )
               elseif not (sameDim(self, other) and #self == 3) then
                    error( "attempt to cross vectors of dimension other than 3", 2 )
               end
               return    P.new(
                              self[2] * other[3] - self[3] * other[2],
                              self[3] * other[1] - self[1] * other[3],
                              self[1] * other[2] - self[2] * other[1]
                         )
          end,
          magnitude = function(self)
               return math.sqrt( self:dot(self) )
          end,
          norm = magnitude,
          normalize = function(self)
               return self / self:magnitude()
          end,
          distance = function(self, other)
               if not checkMeta(self, other) then
                    error( "attempt to find distance between vector and non-vector", 2 )
               elseif not sameDim(self, other) then
                    error( "attempt to find distance between vectors of different dimension", 2 )
               end
               local sum = 0
               for i, v1, v2 in doubleipairs(self, other) do
                    sum = sum + (v1-v2)^2
               end
               return math.sqrt( sum )
          end,
     },
     __add = function(self, other)
          if not checkMeta(self, other) then
               error( "attempt to __add vector and non-vector", 2)
          end
          local newV = {}
          for i, v1, v2 in doubleipairs(self, other) do
               newV[i] = v1 + v2
          end
          return P.new( table.unpack(newV) )
     end,
     __sub = function(self, other)
          if not checkMeta(self, other) then
               error( "attempt to __sub vector and non-vector", 2)
          end
          local newV = {}
          for i, v1, v2 in doubleipairs(self, other) do
               newV[i] = v1 - v2
          end
          return P.new( table.unpack(newV) )
     end,
     __mult = function(self, other)
          --other must be a number
          if getmetatable(self) ~= mt.__metatable and getmetatable(other) == mt.__metatable then
               self, other = other, self
          end
          if getmetatable(self) == mt.__metatable and type(other) ~= "number" then
               error("attempt to __mult vector by non-number", 2)
          end
          local newV = {}
          for i, v in pairs(self) do
               newV[i] = v * other
          end
          return P.new( table.unpack(newV) )
     end,
     __div = function(self, other)
          --other must be a number
          if getmetatable(self) == mt.__metatable and type(other) ~= "number" then
               error("attempt to __div vector by non-number", 2)
          elseif getmetatable(self) ~= mt.__metatable then
               error("attempt to __div "..type(self).." by vector", 2)
          end
          local newV = {}
          for i, v in pairs(self) do
               newV[i] = v / other
          end
          return P.new( table.unpack(newV) )
     end,
     __unm = function(self)
          local newV = {}
          for i, v in ipairs(self) do
               newV[i] = -v
          end
          return P.new( table.unpack(newV) )
     end,
     __eq = function(self, other)
          if not checkMeta(self, other) then
               error( "attempt to compare vector and non-vector", 2 )
          end
          for i, v1, v2 in doubleipairs(self, other) do
               if v1 ~= v2 then
                    return false
               end
          end
          return true
     end,
     __tostring = function(self)
          local str = "<"
          local sep = ""
          for i, v in ipairs(self) do
               str = str .. sep .. v
               sep = ", "
          end
          return str..">"
     end
}

return vector