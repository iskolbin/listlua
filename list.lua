local PairMt

local Nil 

local function cons ( head, lst ) return setmetatable( {head, lst}, PairMt ) end
local function rcons( head, lst ) return cons( lst, head ) end
local function car( lst )  return lst[1] end
local function cdr( lst )  return lst[2] end
local function cadr( lst ) return lst[2][1] end
local function caar( lst ) return lst[1][1] end
local function cdar( lst ) return lst[1][2] end
local function cddr( lst ) return lst[2][2] end
local function isNil( lst ) return lst == Nil end
local function isPair( lst ) return lst ~= Nil and getmetatable( lst ) == PairMt end
local function isList( lst ) return isNil( lst ) or ( isPair( lst ) and (isPair( lst:cdr()) or isNil(lst:cdr()))) end
local function isProperList( lst ) 
	if isNil( lst ) then
		return true
	elseif not isPair( lst ) then
		return false
	else
		return isProperList( lst:cdr())
	end
end

local function foldl( lst, f, acc )
	if isNil( lst ) then
		return acc
	else
		return foldl( lst:cdr(), f, f( lst:car(), acc ))
	end
end

local function foldr( lst, f, acc )
	if isNil( lst ) then
		return acc
	else
		return f( lst:car(), foldr( lst:cdr(), f, acc ))
	end
end

local function tail( lst, i )
	if i > 0 then
		return tail( lst:cdr(), i - 1 )
	else
		return lst
	end
end

local function nth( lst, n ) return lst:tail( n-1 ):car() end

local function map( lst, f )
	local function doMap( v, acc )
		return cons( f( v ), acc )
	end
	
	return foldr( lst, doMap, Nil )
end

local function filter( lst, p )
	local function doFilter( v, acc )
		if p( v ) then
			return cons( v, acc )
		else
			return acc
		end
	end 

	return foldr( lst, doFilter, Nil )
end

local function list( vs )
	local lst = Nil
	for i = #vs, 1, -1 do
		if type( vs[i] ) == 'table' then
			lst = cons( list( vs[i] ), lst )
		else
			lst = cons( vs[i], lst )
		end
	end
	return lst
end

local function reverse( lst ) return foldl( lst, cons, Nil ) end
local function copy( lst ) return foldr( lst, cons, Nil ) end

local function append( lst, lstTail ) 
	return foldl( lst, cons, isList( lstTail ) and lstTail or list(lstTail) )
end

local function each( lst, f )
	local function doEach( v, acc ) 
		f( v ) 
	end

	foldr( lst, doEach, Nil )
end

local function count( lst, p )
	local function doCount( v, acc )
		if p( v ) then
			acc = acc + 1
		end
		return acc
	end

	return foldl( lst, doCount, 0 )
end

local function partition( lst, p )
	local function doPartition( v, acc )
		if p( v ) then
			return cons( cons( v, acc:car() ), acc:cdr() )
		else
			return cons( acc:car(), cons( v, acc:cdr() ))
		end
	end

	return foldr( lst, doPartition, cons( Nil, Nil ))
end

-- BROKEN
local function flatten( lst )
	local function doFlatten( v, acc )
		if isNil( v ) then
			return acc
		elseif isPair( v ) then
			return acc:append( v )
		else
			return acc:rcons( v )
		end
	end
	return foldr( lst, doFlatten, Nil )
end

local function toString( lst )
	if isPair( lst ) then
		local acc = {}
		while not isNil( lst ) do
			if isList( lst ) then
				acc[#acc+1] = toString( lst:car())
				lst = lst:cdr()	
			elseif isPair( lst ) then
				acc[#acc+1] = toString( lst:car())
				acc[#acc+1] = '.'
				acc[#acc+1] = toString( lst:cdr())
				break
			else
				acc[#acc+1] = tostring( lst )
				break
			end
		end
		acc[1] = '(' .. acc[1]
		acc[#acc] = acc[#acc] .. ')'
		return table.concat( acc, ' ')
	else
		return tostring(lst)
	end
end

local function display( lst ) 
	print( lst ) 
end

local List = {
	cons = cons, rcons = rcons, car = car, cdr = cdr, cadr = cadr, caar = caar, cdar = cdar, cddr = cddr,
	foldl = foldl, foldr = foldr, map = map, filter = filter, reverse = reverse, each = each, list = list,
	nth = nth, tail = tail, append = append, copy = copy, partition = partition, flatten = flatten,
	isList = isList, isProperList = isProperList, isPair = isPair, isNil = isNil, toString = toString, display = display,
}

PairMt = { 
	__index = List,
	__tostring = List.toString
}

Nil = setmetatable( {}, PairMt )

return setmetatable( List, { __call = function( self, vs ) 
	return list(vs) 
end } )

