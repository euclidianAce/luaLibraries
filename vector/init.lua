local P = {}   -- package
--namespace
local _REQUIREDNAME = tostring(...)
if _REQUIREDNAME == nil then
     vector = P
else
     _G[_REQUIREDNAME] = P
end

-- dependencies:
local math          = require "math"
local table         = require "table"
local os            = os
local print         = print
local ipairs        = ipairs
local type          = type
local setmetatable  = setmetatable
local getmetatable  = getmetatable
local error         = error

-- Set the environment to the package, no more external access (hence the previous section)
local _ENV = P

math.randomseed( os.time() )

--error messages
local errs = {
     wrongDim       = "",
     nonInteger     = "n must be a positive integer",
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

function new(...)
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

function random(n)
     --gives a random n dimensional unit vector
     n = n or getDefaultDim()
     if not isPosInteger(n) then
          error( err.notInteger, 2 )
     end
     local newV = {}
     for i = 1, n do
          newV[i] = math.random()
     end
     newV = new( table.unpack(newV) )
     return newV:normalize()
end

function getDefaultDim()
     return defaultDim
end

function setDefaultDim(n)
     if type(n) == "number" then
          if n > 0 and isPosInteger(n) then
               defaultDim = n
               return true
          end
     end
     error( err.notInteger, 2 )
end

function e(n, dim)
     --returns the unit vector in the nth dimension
     dim = dim or getDefaultDim()
     if n > dim then
          error( n.." is out of range ("..dim..")", 2 )
     end
     local newV = {}
     for i = 1, dim do
          newV[i] = 0
     end
     newV[n] = 1
     return new( table.unpack( newV ) )
end

--metatable stuffs
mt = {}
do
     local new = new
     local _ENV = mt
     __metatable = "vector"
     function __add(self, other)
          if not checkMeta(self, other) then
               error( "attempt to __add vector and non-vector", 2)
          elseif not sameDim(self, other) then
               error( "attempt to __add vectors of different dimension", 2 )
          end
          local newV = {}
          for i, v1, v2 in doubleipairs(self, other) do
               newV[i] = v1 + v2
          end
          return new( table.unpack(newV) )
     end
     function __sub(self, other)
          if not checkMeta(self, other) then
               error( "attempt to __sub vector and non-vector", 2)
          elseif not sameDim(self, other) then
               error( "attempt to __sub vectors of different dimension", 2 )
          end
          local newV = {}
          for i, v1, v2 in doubleipairs(self, other) do
               newV[i] = v1 - v2
          end
          return new( table.unpack(newV) )
     end
     function __mult(self, other)
          --other must be a number
          if getmetatable(self) ~= mt.__metatable and getmetatable(other) == mt.__metatable then
               self, other = other, self
          end
          if getmetatable(self) == mt.__metatable and type(other) ~= "number" then
               error("attempt to __mult vector by non-number", 2)
          end
          local newV = {}
          for i, v in ipairs(self) do
               newV[i] = v * other
          end
          return new( table.unpack(newV) )
     end
     function __div(self, other)
          --other must be a number
          if getmetatable(self) == mt.__metatable and type(other) ~= "number" then
               error("attempt to __div vector by non-number", 2)
          elseif getmetatable(self) ~= mt.__metatable then
               error("attempt to __div "..type(self).." by vector", 2)
          end
          local newV = {}
          for i, v in ipairs(self) do
               newV[i] = v / other
          end
          return new( table.unpack(newV) )
     end
     function _unm(self)
          local newV = {}
          for i, v in ipairs(self) do
               newV[i] = -v
          end
          return new( table.unpack(newV) )
     end
     function __eq(self, other)
          if not checkMeta(self, other) then
               error( "attempt to compare vector and non-vector", 2 )
          end
          for i, v1, v2 in doubleipairs(self, other) do
               if v1 ~= v2 then
                    return false
               end
          end
          return true
     end
     function __tostring(self)
          local str = "<"
          local sep = ""
          for i, v in ipairs(self) do
               str = str .. sep .. v
               sep = ", "
          end
          return str..">"
     end
     __index = {}
     do
          local _ENV = __index
          function dot(self, other)
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
          end
          function cross(self, other)
               if not checkMeta(self, other) then
                    error( "attempt to cross vector and non-vector", 2 )
               elseif not (sameDim(self, other) and #self == 3) then
                    error( "attempt to cross vectors of dimension other than 3", 2 )
               end
               return    new(
                              self[2] * other[3] - self[3] * other[2],
                              self[3] * other[1] - self[1] * other[3],
                              self[1] * other[2] - self[2] * other[1]
                         )
          end
          function magnitude(self)
               return math.sqrt( self:dot(self) )
          end
          norm = magnitude
          function normalize(self)
               return self / self:magnitude()
          end
          function distance(self, other)
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
          end
          function decimalPlaces(self, places)
               places = places or 2 --decimal places
               newV = {}
               for i, v in ipairs(self) do
                    newV[i] = math.floor(v * (10^places) ) / (10^places)
               end
               return new( table.unpack(newV) )
          end
          function round(self)
               newV = {}
               for i, v in ipairs(self) do
                    newV[i] = math.floor( v + 0.5 )
               end
               return new( table.unpack(newV) )    
          end
     end
end


return P