
function rows( M )
     local row = 0
     local r, c = #M, #M[1]
     return    function()
                    row = row+1
                    if row > r then
                         return nil
                    end
                    local rTable = {}
                    for i = 1, c do
                         table.insert(rTable, M[row][i])
                    end
                    return row, rTable
               end
end

function columns( M )
     local column = 0
     local r, c = #M, #M[1]
     return    function()
                    column = column+1
                    if column > c then
                         return nil
                    end
                    local rTable = {}
                    for i = 1, r do
                         table.insert(rTable, M[i][column])
                    end
                    return column, rTable
               end
end

function entries( M )
     local r, c = #M, #M[1]
     local i, j = 1, 1
     local row, column = 1, 0
     return    function()
                    column = column+1
                    if column > c then
                         column = 1
                         row = row+1
                         if row > r then
                              return nil
                         end
                    end
                    return row, column, M[row][column]
               end
end

function doubleEntries( M, N )
     -- verify self and other are the same size
     local r, c = #M, #M[1]

     local i, j = 1, 1
     local row, column = 1, 0
     return    function()
                    column = column+1
                    if column > c then
                         column = 1
                         row = row+1
                         if row > r then
                              return nil
                         end
                    end
                    return row, column, M[row][column], N[row][column]
               end
end