local PairMt

local Nil 

local Op = {
	add = function( a, b ) return a + b end,
	sub = function( a, b ) return a - b end,
	div = function( a, b ) return a / b end,
	mod = function( a, b ) return a % b end,
	mul = function( a, b ) return a * b end,
	pow = function( a, b ) return a ^ b end,
	concat = function( a, b ) return a .. b end,

	lt = function( a, b ) return a <  b end,
	le = function( a, b ) return a <= b end,
	eq = function( a, b ) return a == b end,
	ne = function( a, b ) return a ~= b end,
	gt = function( a, b ) return a >  b end,
	ge = function( a, b ) return a >= b end,
}

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

local function sum( lst, acc )
	if isNil( lst ) then
		return acc
	else
		return sum( lst:cdr(), acc + lst:car())
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

local function nth( lst, n ) 
	return lst:tail( n-1 ):car() 
end

local function indexOf( lst, x )
	local function doIndex( i, lst, x )
		if isNull( lst ) then
			return -1
		elseif lst:car() == x then
			return i
		else
			return doIndex( i + 1, lst:cdr(), x )
		end
	end

	return doIndex( 0, lst, x )
end

local function exists( lst, x ) return lst:indexOf( x ) ~= -1 end

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

local function filterMap( lst, p, f )
	local function doFilterMap( v, acc )
		if p( v ) then
			return cons( f( v ), acc )
		else
			return acc
		end
	end 

	return foldr( lst, doFilterMap, Nil )
end

local function mapFilter( lst, f, p )
	local function doMapFilter( v, acc )
		local v_ = f( v )
		if p( v_ ) then
			return cons( v_, acc )
		else
			return acc
		end
	end 

	return foldr( lst, doFilterMap, Nil )
end

local function list( vs )
	local lst = Nil
	if type( vs ) == 'table' then
		for i = #vs, 1, -1 do
			if type( vs[i] ) == 'table' then
				lst = lst:rcons( list( vs[i] ))
			else
				lst = lst:rcons( vs[i] )
			end
		end
		return lst
	else
		return lst:rcons( vs )
	end
end

local function range( from, to, step )
	local function doForwardRange( lr, index, from, step )
		if index < from then
			return lr
		else
			return doForwardRange( lr:rcons( index ), index - step, from, step )
		end
	end

	local function doBackwardRange( lr, index, from, step )
		if index > from then
			return lr
		else
			return doBackwardRange( lr:rcons( index ), index - step, from, step )
		end
	end

	local step = step or ( from <= to and 1 or -1 )


	if from <= to and step > 0 then
		return doForwardRange( Nil, to, from, step )
	elseif from > to and step < 0 then
		return doBackwardRange( Nil, to, from, step )
	else
		return Nil
	end
end

local function reverse( lst ) return foldl( lst, cons, Nil ) end
local function copy( lst ) return foldr( lst, cons, Nil ) end
local function append( lst, lstTail ) return foldr( lst, cons, isList( lstTail ) and lstTail or list(lstTail) )end

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

local function all( lst, p )
	if isNil( lst ) then
		return true
	elseif p( lst:car()) then
		return all( lst:cdr(), p )
	else
		return false
	end
end

local function any( lst, p )
	if isNil( lst ) or p( lst:car()) then
		return true
	else
		return any( lst:cdr(), p )
	end
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
		if isPair( v ) then
			return v:foldr( doFlatten, acc )
		else
			return acc:rcons( v )
		end
	end
	
	return lst:foldr( doFlatten, Nil )
end

local function merge( lst1, lst2, cmp )
	if isNil( lst1 ) then
		return lst2
	elseif isNil( lst2 ) then
		return lst1
	else
		local car1, car2 = lst1:car(), lst2:car()
		if cmp( car1, car2 ) then
			return cons( car1, merge( lst1:cdr(), lst2, cmp ))
		else
			return cons( car2, merge( lst1, lst2:cdr(), cmp ))
		end
	end
end

local function sort( lst, cmp )
	local function doSort( lr, part, cmp )
		if isNil( part ) then
			if isNil( lr:cdr()) then
				return lr:car()
			else
				return doSort( part, lr, cmp )
			end
		elseif isNil( part:cdr()) then
			return doSort( lr:rcons( part:car()), part:cdr(), cmp )
		else
			return doSort( lr:rcons( part:car():merge( part:cadr(), cmp )), part:cddr(), cmp )
		end
	end

	return doSort( Nil, lst:map( list ), cmp or Op.lt )
end

local function toTable( lst )
	if isPair( lst ) then
		local acc = {}
		while not isNil( lst ) do
			if isList( lst ) then
				acc[#acc+1] = lst:car()
				lst = lst:cdr()	
			elseif isPair( lst ) then
				acc[#acc+1] = lst:car()
				acc[#acc+1] = lst:cdr()
				break
			else
				acc[#acc+1] = lst
				break
			end
		end
		return acc
	else
		return lst
	end
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
	elseif isNil( lst ) then
		return '()'
	else
		return tostring(lst)
	end
end

local function display( lst ) 
	print( lst ) 
end

local unpack = table.unpack or unpack

local function eval( lst )
	return lst:car()( unpack( lst:cdr():toTable()))
end

local List = {
	Op = Op, Nil = Nil,
	cons = cons, rcons = rcons, car = car, cdr = cdr, cadr = cadr, caar = caar, cdar = cdar, cddr = cddr,
	foldl = foldl, foldr = foldr, map = map, filter = filter, mapFilter = mapFilter, filterMap = filterMap, reverse = reverse, each = each, 
	list = list, range = range,
	nth = nth, tail = tail, append = append, copy = copy, partition = partition, flatten = flatten,
	isList = isList, isProperList = isProperList, isPair = isPair, isNil = isNil, toString = toString, display = display,
	sort = sort, merge = merge, eval = eval,
}

PairMt = { 
	__index = List,
	__tostring = List.toString
}

Nil = setmetatable( {}, PairMt )

return setmetatable( List, { __call = function( self, vs ) 
	return list(vs) 
end } )

