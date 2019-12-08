-- Naming Conventions: 
-- lower case under_scores denote external files 
-- camelCase is default
-- _ALLCAPS are constants, (but not actual <const> for compatability)

local P = {} -- package to be returned
local _REQUIREDNAME, packagePath = ...
do
    local _, c = packagePath:find(_REQUIREDNAME)
    packagePath = packagePath:sub(1, c+1)
end

-- Read version.info
local version_info, errMsg = loadfile( packagePath.."/version.info", "t",
{
     Information = function(t)
          for i, v in pairs(t) do
               local index = "_"..i:upper()
               P[ index ] = v
          end
     end
})
if not version_info then
     error( errMsg )
end

version_info()

-- check compatability
if not P._LUA_VERSIONS[ _VERSION ] then
     error( ("%s library not compatable with current Lua version (%s)"):format(_REQUIREDNAME, _VERSION) )
end

-- read files.aux

-- metatable for the sandboxes to catch global declarations
local aux_metatable = 
{
     __index = function(tab, key) 
          -- allow access to the package
          if not P[ key ] then
               error( key.." is not defined, perhaps files.aux doesn\'t give access to it?", 2 )
          end
          return P[ key ]
     end,
     __newindex = function(tab, key, value) 
          -- catch all new global declarations and put them in the package
          P[ key ] = value
     end
}
-- set up auxillary file lookup tables and sandboxes
local aux_table
local auxiliary_file, errMsg = loadfile( packagePath.."/files.aux", "t",
{
     Auxiliary = function(t)
          for _, v in pairs(t) do
               -- make var names easy to lookup
               for i = #v, 1, -1 do
                    local name = v[i]
                    v[name] = true
                    v[i] = nil
               end

               -- go through dependencies for each sandbox
               for i = #v.dependencies, 1, -1 do
                    local name = v.dependencies[i]
                    v.dependencies[name] = _G[name]
                    v.dependencies[i] = nil
               end
               for _, lib in pairs( P._DEPENDENCIES ) do
                    v.dependencies[ lib ] = require( lib )
               end
               setmetatable(v.dependencies, aux_metatable)
          end
          aux_table = t
     end
})

if not auxiliary_file then
     error( errMsg )
end
auxiliary_file()

local packageMetatable = 
{
     __index = function(t, name)
          -- use aux_table to autoload <name>

          -- find the file that <name> is in
          local fileName
          for fName, info in pairs( aux_table ) do
               if info[name] then
                    fileName = fName
                    break
               end
          end
          if not fileName then
               error( name.." not found in lookup", 3 )
          end

          local fullPath = ("%s%s.lua"):format( packagePath, fileName )
          
          -- load that file in its sandbox so any global declarations are put into the package
          local def_file, errMsg = loadfile( fullPath, "t", aux_table[fileName].dependencies )
          if not def_file then
               error( errMsg, 2 )
          end
          def_file()
          
          -- return the result
          if rawget(P, name) == nil then
               error( name.." not defined in "..fullPath, 1 )
          end
          return P[name]
     end
}

return setmetatable(P, packageMetatable)
