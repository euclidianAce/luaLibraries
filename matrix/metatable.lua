
mt = { __metatable = "matrix" }
mt.__index = {}
local ind = mt.__index

----
---- getters
----

function ind:getSize()
     return #self, #self[1] -- rows, columns
end

function ind:getRows()
     return #self
end

function ind:getColumns()
     return #self[1]
end

function ind:sameSize( other )
     local r1, c1 = self:getSize()
     local r2, c2 = other:getSize()
     return (r1 == r2) and (c1 == c2)
end

function ind:makeString( padding )
     padding = padding or 1
     local c = self:getColumns()
     local p = table.concat{"% .", padding, "f"}
     local strTable = {}
     for r, row in rows(self) do
          table.insert(strTable, (r > 1 and "\n") or nil)
          table.insert(strTable, "[ ")
          table.insert(strTable, (string.rep(p.." ", c)):format( table.unpack(row) ))
          table.insert(strTable, "]")
     end
     return table.concat(strTable)
end

function ind:transpose()
     local newMatrix = zero( self:getColumns(), self:getRows() )
     for r, c, e in entries(self) do
          newMatrix[c][r] = e
     end
     return newMatrix
end

----
---- arithmetic
----

function mt:__add( other )
     assert( self:sameSize(other) )

     local t = {}
     for row, column, a, b in doubleEntries(self, other) do
          table.insert(t, a+b)
     end
     return new(t, self:getRows())
end

function mt:__sub( other )
     assert( self:sameSize(other) )

     local t = {}
     for row, column, a, b in doubleEntries(self, other) do
          table.insert(t, a-b)
     end
     return new(t, self:getRows())
end

function mt:__unm()
     local t = {}
     for row, column, a in entries(self) do
          table.insert(t, -a)
     end
     return new(t, self:getRows())
end


local function dot( t1, t2 )
     -- takes two lists and gives their dot product
     local sum = 0
     for i = 1, #t1 do
          sum = sum+t1[i]*t2[i]
     end
     return sum
end
-- the important one
function mt:__mul( other )
     if type(self) == "number" then
          self, other = other, self
     end

     local t = {}

     if type(other) == "number" then
          -- matrix scalar product
          for i, j, e in entries(self) do
               table.insert(t, e*other)
          end
     else
          -- matrix matrix product
          for i, row in rows(self) do
               for j, column in columns(other) do
                    table.insert(t, dot(row, column))
               end
          end
     end

     return new(t, self:getRows())
end


function mt:__div( other )
     local t = {}
     for i, j, e in entries(self) do
          table.insert(t, e/other)
     end
     return new(t, self:getRows())
end

mt.__tostring = mt.__index.makeString