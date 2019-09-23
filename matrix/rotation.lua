
--------------------------------------------------------------------------------------------------
--   Implementation of the Aguilera-Perez Algorithm                                             --
--   Aguilera, Antonio, and Ricardo Perez-Aguilera. "General n-dimensional rotations." (2004)   --
--   http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.4.8662                             --
--------------------------------------------------------------------------------------------------


--
--   Due to the implementation of the Aguilera-Perez Algorithm,
--   all of these methods return a homogeneous matrix since we need
--   to allow for translations to rotate about any axis
--

function translationMatrix( vector )
     local r, c = vector:getSize()
     if r ~= 1 and c ~= 1 then
          error( "bad argument #1, vector expected", 2 )
     end

     -- identity matrix based on size of either columns or rows
     local tMatrix = identity( ((r<=c) and c+1) or r+1 )
     if r == 1 then -- row vector
          for i = 1, c do
               tMatrix[ c+1 ][ i ] = vector[ 1 ][ i ] 
          end
     elseif c == 1 then -- column vector
          for i = 1, r do
               tMatrix[ i ][ r+1 ] = vector[ i ][ 1 ] 
          end
     end
     return tMatrix
end


function mainRotationMatrix( dim, axis1, axis2, angle )
     local newMatrix = identity( dim+1 )

     for r = 1, dim+1 do
          for c = 1, dim+1 do

               if r == axis1 and c == axis1 then
                    newMatrix[r][c] = math.cos(angle)

               elseif r == axis2 and c == axis2 then
                    newMatrix[r][c] = math.cos(angle)

               elseif r == axis1 and c == axis2 then
                    newMatrix[r][c] = -math.sin(angle)

               elseif r == axis2 and c == axis1 then
                    newMatrix[r][c] = math.sin(angle)
               end

          end
     end

     return newMatrix
end


function rotationMatrix( simplex, angle )
     -- size of simplex determines the size of the matrix

     local simplexRows, n = simplex:getSize()
     local v, M, MInverse, tVec

     tVec = zero(1, n)
     for i = 1, n do
          tVec[1][i] = simplex[1][i]
     end

     -- make a copy of the simplex and convert it to homogeneous
     v = zero( simplexRows, n+1 )
     for r, c, e in entries(simplex) do
          v[r][c] = e
     end
     for i = 1, simplexRows do
          v[i][n+1] = 1
     end

     -- Initial values
     M    = translationMatrix( tVec )
     v    = v * M
     MInv = translationMatrix( -tVec )

     -- the Algorithm
     for r = 2, n-1 do
          for c = n, r, -1 do
               local Mk  = mainRotationMatrix(n, c,   c-1, math.atan2(v[r][c], v[r][c-1]) )
               M         = M * Mk
               MInv      = mainRotationMatrix(n, c-1, c,   math.atan2(v[r][c], v[r][c-1]) ) * MInv
               v         = v * Mk
          end
     end
     
     return M * mainRotationMatrix(n, n-1, n, angle) * MInverse
end