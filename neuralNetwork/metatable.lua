
mt = {}

mt.__index = {}
local ind = mt.__index


local function sigmoid(x)
     return 1/(1+math.exp(-x))
end
local function sigmoidPrime(x)
     return math.exp(-x)/(1+math.exp(-x))^2
end

function ind:compute(...)
     local args = {...}
     local output
     if getmetatable( args[1] ) ~= "matrix" then
          output = {matrix.new( {...}, #{...} )}
     else
          output = {args[1]}
     end

     for i = 2, self.layers do
          --forward propagation according to weights and biases
          output[i] = (self.layer[i].W * output[i-1] + self.layer[i].b):apply(sigmoid)
     end

     return output[ #output ], output
end