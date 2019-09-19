local matrix = {} -- package

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
               matrix[ index ] = v
          end
     end
})
if not version_info then
     error( errMsg )
end
version_info()
if not matrix._LUA_VERSIONS[ _VERSION ] then
     error( ("%s library not compatable with current Lua version (%s)"):format(_REQUIREDNAME, _VERSION) )
end

local auxillary = {
     constructors = {
          "new", "zero", "identity",

          dependencies = {
               "setmetatable","print","error",
               "type","ipairs","math","table",
          }
     },
     rotation = {
          "translationMatrix", "mainRotationMatrix",
          "rotationMatrix",

          dependencies = {
               "math", "error"
          }
     },
     metatable = {
          "mt",

          dependencies = {
               "ipairs", "table", "assert", "getmetatable", "type",
               "string",
          }
     },
     iterators = {
          "rows", "columns", "entries", "doubleEntries",

          dependencies = {
               "assert","table",
          }
     }
}

for _, v in pairs(auxillary) do
     -- make var names easy to lookup
     local name = table.remove(v)
     repeat
          v[name] = true
          name = table.remove(v)
     until not name

     -- go through dependencies
     local name = table.remove(v.dependencies)
     while name do
          v.dependencies[name] = _G[name]
          name = table.remove(v.dependencies)
     end
end


return setmetatable(matrix, {
     __index = function(t, name)
          -- find the file that <name> is in
          local fileName
          for fName, info in pairs(auxillary) do
               if info[name] then
                    fileName = fName
                    break
               end
          end
          if not fileName then
               error( name.." not found in lookup", 3 )
          end

          local fullPath = table.concat{ packagePath, fileName, ".lua"}
          
          -- load that file in a sandbox
          local file, err = loadfile( fullPath, "t", 
               setmetatable(auxillary[fileName].dependencies,
                    {
                         __index = function(tab, key) -- allow access to the package
                              if not matrix[ key ] then
                                   error( key.." is not defined", 2 )
                              end
                              return matrix[ key ]
                         end,
                         __newindex = function(tab, key, value) -- catch all new global definitions and put them in the package
                              t[ key ] = value
                         end
                    }
               ) 
          )
          if not file then
               error( err, 2 )
          end
          file()
          
          -- return the result
          if rawget(t, name) == nil then
               error( name.." not defined in "..fileName, 2 )
          end
          return t[name]
     end
})