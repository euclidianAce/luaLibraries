local function getRow( M )
	for i = 1, #M do
		coroutine.yield(i, M[i])
	end
end
function rows( M )
	local co = coroutine.create(function() getRow(M) end)
	return function()
		local state, r, row = coroutine.resume(co)
		return r, row
	end

end

local function getColumn( M )
	for i = 1, #M[1] do
		-- make a new list with the contents of column i
		local t = {}
		for j = 1, #M do
			t[#t + 1] = M[j][i]
		end
		coroutine.yield(i, t)
	end
end
function columns( M )
	local co = coroutine.create(function() getColumn(M) end)
	return function()
		local status, c, col = coroutine.resume(co)
		return c, col
	end
end


local function getEntries( M )
	for i = 1, #M do
		for j = 1, #M[1] do
			coroutine.yield(i, j, M[i][j])
		end
	end
end
function entries( M )
	local co = coroutine.create(function() getEntries(M) end)
	return function()
		local status, r, c, e = coroutine.resume(co)
		return r, c, e
	end
end
function doubleEntries(M, N)
	local coM = coroutine.create(function() getEntries(M) end)
	local coN = coroutine.create(function() getEntries(N) end)
	return function()
		local _, _, _, eM = coroutine.resume(coM)
		local _, r, c, eN = coroutine.resume(coN)
		return r, c, eM, eN
	end
end

-- general entries function for any number of matrices
function genEntries( ... )
	local mTable = {...}
	local threads = {}
	for i = 1, #mTable do
		threads[i] = coroutine.create(function() getEntries(mTable[i]) end)
	end
	return function()
		local eTable = {}
		local status, r, c
		for i = 1, #threads do
			status, r, c, eTable[ mTable[i] ] = coroutine.resume(threads[i])
			-- each entry is indexed by the matrix that it's from
		end
		return r, c, eTable
	end
end

