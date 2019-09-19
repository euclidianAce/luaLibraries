
---- 
---- 
---- This file defines most of the constructors
---- 
---- 

local function assert( exp, errMsg, level )
     if not exp then
          error( errMsg, (level and level+1) or 1 )
     end
end

local function assertType( val, typeStr, errMsg, level )
     if type(val) ~= typeStr then
          error( errMsg, (level and level+1) or 1)
     end
     return val
end

function new( tab, rows )
     -- tab is a list, rows is how many rows the matrix is
     -- tab can either be a list of lists or a one dimensional list with a number to denote when to go to the next row

     assertType(tab, "table")
     if type(tab[1]) == "table" then
          local t = {}
          rows = #tab
          for i = 1, #tab do
               for j = 1, #tab[i] do
                    table.insert(t, tab[i][j])
               end
          end
          tab = t
     else
          assertType(rows, "number")
     end
     -- check that tab can be made into a valid matrix
     local cols = #tab/rows
     assert(math.floor(cols) == cols, "table cannot be split into "..rows.." rows", 2)
     

     local newMatrix = {{}}
     local row, col = 1, 0
     for i, v in ipairs( tab ) do
          col = col+1
          if col > cols then
               col = 1
               row = row+1
               newMatrix[row] = {}
          end
          newMatrix[row][col] = assertType(v, "number", "Bad table value, number expected, got "..type(v), 2)
     end

     return setmetatable(newMatrix, mt) -- mt defined in metatable.lua
end

function zero( rows, columns )
     local t = {}
     for i = 1, rows*columns do
          table.insert(t, 0)
     end
     return new( t, rows )
end

function identity( size )
     local t = {}
     for i = 1, size*size do
          table.insert(t, (((i-1)%size == (i-1)//size and 1) or 0 ) )
     end
     return new( t, size )
end