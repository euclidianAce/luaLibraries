
function new(...)
     local args = {...}
     -- list of numbers to determine how many neurons on each layer

     local NN = { layers = #args, layer = {} }

     for i = 2, #args do
          NN.layer[i] = 
          {
               -- rows are equal to the amount of neurons on the next layer
               -- columns are the amount of neurons on the previous layer
               W = matrix.random( args[i], args[i-1] ),
               -- vector with rows = to the amount of neurons on the next layer
               b = matrix.random( args[i], 1 )
          }
     end

     return setmetatable(NN, mt)
end
