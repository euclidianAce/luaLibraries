
-- input training data

-- for each training example
     -- feedforward (neuralNetwork:compute)
     -- compute the \error delta^{x, L} = \nabla_a (C_x) \odot \sigma^\prime ( w^l a^{x,l-1} + b^l )
     -- backpropagate: for each l = L-1, L-2, ..., 2 
          -- compute \delta^{x, l} = ( (w^{l+1})^T \delta^{x, l+1} ) \odot \sigma^\prime ( w^l a^{x,l-1} + b^l )

-- Gradient descent
     -- for each l = L, L-1, ..., 2
          -- update weights and biases according to 
               -- w^l \rightarrow w^l - \frac{\eta}{m} \sum_x \delta^{x, l} ( a^{x,l-1} )^T
               -- b^l \rightarrow b^l - \frac{\eta}{m} \sum_x \delta^{x, l}


local function sigmoid(x)
     return 1/(1+math.exp(-x))
end
local function sigmoidPrime(x)
     return math.exp(-x)/(1+math.exp(-x))^2
end

local function costFunction(input, expectedOutput)
     -- just a simple quadratic cost thing
     return 0.5 * (expectedOutput - lastOutput):magnitudeSquared()

end

local eta = 0.01

function computeError(NN, input, expectedOutput)

     -- feedforward
     local lastOutput, output = NN:compute( input )

     local L = NN.layers

     -- compute error
     local delta = {}

     local function z( l )
          if l == 1 then
               return output[1]
          end
          return NN.layer[ l ].W * output[ l-1 ] + NN.layer[ l ].b
     end
     local function sigmaPrimeZ( l )
          return z( l ):apply( sigmoidPrime )
     end

     -- for quadratic cost function
     local gradCost = lastOutput - expectedOutput
     delta[ L ] = gradCost:schur( sigmaPrimeZ(L) )

     -- backpropagate error
     for l = L-1, 2, -1 do
          delta[l] = ( NN.layer[ l+1 ].W:transpose() * delta[ l+1 ] ):schur( sigmaPrimeZ(l) )
     end

     -- update weights and biases
     for l = L, 2, -1 do
          NN.layer[l].W = NN.layer[l].W - eta * delta[l] * (z(l-1):apply( sigmoid )):transpose()
          NN.layer[l].b = NN.layer[l].b - eta * delta[l]
     end
end