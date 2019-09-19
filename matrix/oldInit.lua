local P = {} -- package
-- Namespace
local _REQUIREDNAME = ...
if _REQUIREDNAME == nil then
     matrix = P
else
     _G[_REQUIREDNAME] = P
end

-- Read version.info
function Information(t)
     for i, v in next, t do
          local index = "_"..i:upper()
          P[ index ] = v
     end
end
local infoGot, errMsg = pcall(dofile, _REQUIREDNAME.."/version.info")
if infoGot then
     if not P["_LUA_VERSIONS"][ _VERSION ] then
          error( _REQUIREDNAME..(" library not compatable with current Lua version (%s)"):format(_VERSION), 2 )
     end
end


-- Dependencies:

local math          = math
local ipairs        = ipairs
local setmetatable  = setmetatable
local table         = table
local type          = type
local error         = error
local print         = print
local setfenv       = setfenv
local tostring      = tostring

-- Set the environment to the package, no more external access (hence the previous section)
local _ENV
if setfenv then
     setfenv(1, P)
else
     _ENV = P
end

-- The actual package

-----
-----     Constructors
-----

     --------
     --------  Matrices are stored as 1 dimensional arrays with strings to index them
     --------  

local metatable = {}
local keys = {} --store string values so we dont have to keep concatenating new ones
local function getKey(row, column)
     if not keys[row] and row then
          keys[row] = {}
     end
     if not keys[row][column] and column then 
          keys[row][column] = tostring(row)..":"..tostring(column)
     end
     return keys[row][column]
end

function new( tab )
     -- tab is a list of lists
     -- indexed from 1 to some constant n
     
     local newMatrix = {}
     
     local columns = #tab[1]
     for i, v in ipairs(tab) do
          if #v ~= columns then
               error( "Matrix must be rectangular", 2 )
          end
          for j, val in ipairs(v) do
               newMatrix[ getKey(i, j) ] = val
          end
     end
     
     setmetatable( newMatrix, metatable )
     return newMatrix
end

function zero(rows, columns)
     columns = columns or rows
     local newMatrix = {}
     for i = 1, rows do
          for j = 1, columns do
               newMatrix[ getKey(i, j) ] = 0
          end
     end
     setmetatable( newMatrix, metatable )
     return newMatrix
end

function identity(size)
     local newMatrix = {}
     setmetatable( newMatrix, metatable )
     for i = 1, size do
          for j = 1, size do
               if i == j then
                    newMatrix(i, j, 1)
               else
                    newMatrix(i, j, 0)
               end
          end
     end
     return newMatrix
end

function newRowVec( tab )
     return new( {tab} )
end

function newColumnVec( tab )
     return new( {tab} ):transpose()
end

--translation matrix using homogeneous coordinates
function translationMatrix( vector )
     local r, c = vector:getSize()
     if r ~= 1 and c ~= 1 then
          error( "bad argument #1, vector expected", 2 )
     end
     local tMatrix = identity( ((r<=c) and c+1) or r+1 )
     if r == 1 then -- row vector
          for i = 1, c do
               tMatrix( c+1, i, vector(i) )
          end
     elseif c == 1 then -- column vector
          for i = 1, r do
               tMatrix( i, r+1, vector(i) )
          end
     end

     return tMatrix
end


--rotation matrix about 2 axes
function mainRotationMatrix( dim, axis1, axis2, theta )
     -- returns a HOMOGENEOUS rotation matrix of size dim+1
     local newMatrix = {}
     setmetatable( newMatrix, metatable )
     for r = 1, dim+1 do
          for c = 1, dim+1 do
               if r == c and r ~= axis1 and c ~= axis2 then --along diagonal
                    newMatrix(r, c, 1)
                    
               elseif r == axis1 and c == axis1 then
                    newMatrix(r, c, math.cos(theta))
                    
               elseif r == axis2 and c == axis2 then
                    newMatrix(r, c, math.cos(theta))
                    
               elseif r == axis1 and c == axis2 then
                    newMatrix(r, c, math.sin(theta))
                    
               elseif r == axis2 and c == axis1 then
                    newMatrix(r, c,  -math.sin(theta))
                    
               else
                    newMatrix(r, c, 0)
               end
          end
     end
     return newMatrix
end


function rotationMatrix( simplex, theta )
     --------------------------------------------------------------------------------------------------
     --   Implementation of the Aguilera-Perez Algorithm                                             --
     --   Aguilera, Antonio, and Ricardo Perez-Aguilera. "General n-dimensional rotations." (2004)   --
     --------------------------------------------------------------------------------------------------
     
     local sRow, n = simplex:getSize()
     local v, M, MInverse, tVec

     tVec = zero(1, n)
     for i = 1, n do
          tVec(1, i, simplex(1, i))
     end
     
     v = simplex:copy()
     for i = 1, sRow do  --convert to homogeneous
          v(i, n+1, 1)
     end
     
     M         = translationMatrix( tVec )
     v         = v * M
     MInverse  = translationMatrix( -tVec )
     
     -- main loop
     for r = 2, n-1 do
          for c = n, r, -1 do
               Mk = mainRotationMatrix(n, c, c-1, math.atan2(v(r,c), v(r,c-1)) )
               M = M * Mk
               MInverse = mainRotationMatrix(n, c-1, c, math.atan2(v(r,c), v(r,c-1)) ) * MInverse
               v = v * Mk
          end
     end
     
     return M * mainRotationMatrix(n, n-1, n, theta) * MInverse

end


-----
-----     Metamethods
-----

do
     local _ENV
     if setfenv then
          setfenv(1, metatable)
     else
          _ENV = metatable
     end
     
     function __add( self, other )
          local newMatrix = {}
          for row, column, sEntry, oEntry in self:entries(other) do
               newMatrix[ keys[row][column] ] = sEntry + oEntry
          end
          setmetatable( newMatrix, metatable )
          return newMatrix
     end
     function __sub( self, other )
          local newMatrix = {}
          for row, column, sEntry, oEntry in self:entries(other) do
               newMatrix[ keys[row][column] ] = sEntry - oEntry
          end
          setmetatable( newMatrix, metatable )
          return newMatrix
     end
     function __mul( self, other )
          local newMatrix = {}
          if type(other) == "number" then
               newMatrix = self:copy()
               for r, c, e in newMatrix:entries() do
                    newMatrix[ getKey(r, c) ] = e*other
               end
               return newMatrix
          else
               for r, row in self:rows() do
                    for c, column in other:columns() do
                         k = getKey(r, c)
                         newMatrix[ k ] = 0
                         for i = 1, #column do
                              newMatrix[ k ] = newMatrix[ k ] + row[i]*column[i]
                         end
                    end
               end
               setmetatable( newMatrix, metatable )
               if newMatrix:getRows() == 1 and newMatrix:getColumns() == 1 then
                    return newMatrix(1,1)
               end
               return newMatrix
          end
     end
     function __div( self, other )
          local newMatrix = {}
          if type(other) == "number" then
               newMatrix = self:copy()
               for r, c, e in newMatrix:entries() do
                    newMatrix(r, c, e/other)
               end
               return newMatrix
          end
     end
     function __unm( self )
          local newMatrix = {}
          setmetatable( newMatrix, metatable )
          for row, column, entry in self:entries() do
               newMatrix(row, column, -entry)
          end
          return newMatrix
     end
     function __call( self, row, column, value )
          -- use matrix like a function to get entries out or set entries
          if not value then
               if not column then
                    return self[ getKey(row, 1) ] or self[ getKey(1, row) ] or nil
               else
                    return self[ getKey(row, column) ] or nil
               end
          else
               self[ getKey(row, column) ] = value
               return true
          end
     end
     
     function __tostring(self)
          local str, sep = "", ""
          local first, last = "| ", " |"
          for r, row in self:rows() do
               str = str..sep..first..table.concat( row, "    " )..last
               sep = "\n"
          end
          return str..'\n'
     end
     
     function __len(self)
          return self:getSize()
     end
     
end


-----
-----     Prototype
-----

metatable.__index = {}
do
     local _ENV
     if setfenv then
          setfenv(1, metatable.__index)
     else
          _ENV = metatable.__index
     end

     function getRows(self)
          local r = 0
          while self(r+1, 1) do
               r = r+1
          end
          return r
     end
     function getColumns(self)
          local c = 0
          while self(1, c+1) do
               c = c+1
          end
          return c
     end
     function getSize(self)
          return self:getRows(), self:getColumns()
     end
     function copy(self)
          local newMatrix = {}
          setmetatable( newMatrix, metatable )
          for r, c, entry in self:entries() do
               newMatrix(r, c, entry)
          end
          return newMatrix
     end
     
     function transpose(self)
          local newMatrix = {}
          setmetatable( newMatrix, metatable )
          for r, c in self:entries() do
               newMatrix( c, r, self(r, c) )
          end
          return newMatrix
     end

     
     
-----
-----     Vector functions
-----
     function isVector(self)

     end
     
     function cross( self, other )
          
     end
     function magnitude(self)
          
     end
     function normalize()
          
     end
     
     
-----
-----     Iterators
-----
     
     function rows(self)
          local row = 0
          local rowCount, columnCount = self:getRows(), self:getColumns()
          return    function()
                         row = row+1
                         if row > rowCount then
                              return nil
                         end
                         local rTable = {}
                         for i = 1, columnCount do
                              table.insert(rTable, self( row, i ))
                         end
                         return row, rTable
                    end
     end
     
     function columns(self)
          local column = 0
          local rowCount, columnCount = self:getRows(), self:getColumns()
          return    function()
                         column = column+1
                         if column > columnCount then
                              return nil
                         end
                         local rTable = {}
                         for i = 1, rowCount do
                              table.insert(rTable, self( i, column ))
                         end
                         return column, rTable
                    end
     end
     
     function entries(self, other)
          local row, column = 1, 0
          local rows, columns = self:getRows(), self:getColumns()
          return    function()
                         column = column + 1
                         if column > columns then
                              column = 1
                              row = row + 1
                              if row > rows then
                                   return nil
                              end
                         end
                         local val
                         if other then
                              val = other(row, column)
                         end
                         return row, column, self(row, column), val
                    end
     end
     
end


-- Return the package for require
return P