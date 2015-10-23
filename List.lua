local PairMt

local Nil 

local Wild = setmetatable( {}, {__index = error, __newindex = error, __tostring = function()return '_' end} )

local function cons ( head, lst ) return setmetatable( {head, lst}, PairMt ) end
local function add( head, lst ) return cons( lst, head ) end
local function car( lst )  return lst[1] end
local function cdr( lst )  return lst[2] end
local function cadr( lst ) return lst[2][1] end
local function caar( lst ) return lst[1][1] end
local function cdar( lst ) return lst[1][2] end
local function cddr( lst ) return lst[2][2] end
local function iswild( lst ) return lst == Wild end
local function isnil( lst ) return lst == Nil end
local function ispair( lst ) return lst ~= Nil and getmetatable( lst ) == PairMt end
local function islist( lst ) return isnil( lst ) or ( ispair( lst ) and (ispair( lst:cdr()) or isnil(lst:cdr()))) end
local function isproper( lst ) 
	if isnil( lst ) then
		return true
	elseif not ispair( lst ) then
		return false
	else
		return isproper( lst:cdr())
	end
end

local function foldl( lst, f, acc )
	if isnil( lst ) then
		return acc
	else
		return foldl( lst:cdr(), f, f( lst:car(), acc ))
	end
end

local function sum( lst, acc )
	if isnil( lst ) then
		return acc
	else
		return sum( lst:cdr(), acc + lst:car())
	end
end

local function foldr( lst, f, acc )
	return lst:reverse():foldl( f, acc )
end

local function tail( lst, i )
	if i > 0 then
		return tail( lst:cdr(), i - 1 )
	else
		return lst
	end
end

local function ref( lst, n ) 
	return lst:tail( n-1 ):car() 
end

local function indexof( lst, x )
	local function doIndex( i, lst, x )
		if isnil( lst ) then
			return -1
		elseif lst:car() == x then
			return i
		else
			return doIndex( i + 1, lst:cdr(), x )
		end
	end

	return doIndex( 0, lst, x )
end

local function exists( lst, x ) 
	return lst:indexof( x ) ~= -1 
end

local function map( lst, f )
	local function doMap( v, acc )
		return cons( f( v ), acc )
	end
	
	return lst:foldr( doMap, Nil )
end

local function filter( lst, p )
	local function doFilter( v, acc )
		if p( v ) then
			return cons( v, acc )
		else
			return acc
		end
	end 

	return lst:foldr( doFilter, Nil )
end

local function del( lst, v )
	local function doDel( lst, acc )
		if isnil( lst ) then
			return acc
		elseif lst:car() == v then
			return acc:reverse():append( lst:cdr() )
		else
			return doDel( lst:cdr(), acc:add( lst:car()))
		end
	end

	return doDel( lst, Nil )
end

local function unique( lst )
	local function doUnique( lst, acc, cont )
		if isnil( lst ) then
			return acc:reverse()
		else
			local v = lst:car()
			if not cont:exists( v ) then
				return doUnique( lst:cdr(), acc:add( v ), cont:add( v ))
			else
				return doUnique( lst:cdr(), acc, cont )
			end
		end
	end

	return doUnique( lst, Nil, Nil )
end

local function filtermap( lst, p, f )
	local function doFilterMap( v, acc )
		if p( v ) then
			return cons( f( v ), acc )
		else
			return acc
		end
	end 

	return lst:foldr( doFilterMap, Nil )
end

local function mapfilter( lst, f, p )
	local function doMapFilter( v, acc )
		local v_ = f( v )
		if p( v_ ) then
			return cons( v_, acc )
		else
			return acc
		end
	end 

	return lst:foldr( doFilterMap, Nil )
end

local function list( vs )
	local lst = Nil
	if type( vs ) == 'table' and not isnil( vs ) and not iswild( vs ) then
		for i = #vs, 1, -1 do
			if type( vs[i] ) == 'table' then
				lst = lst:add( list( vs[i] ))
			else
				lst = lst:add( vs[i] )
			end
		end
		return lst
	else
		return lst:add( vs )
	end
end

local function alist( vs )
	local lst = Nil
	if type( vs ) == 'table' and not isnil( vs ) and not iswild( vs ) then
		for k, v in pairs( vs ) do
			if type( k ) == 'table' then
				k = alist( k )
			end
			if type( v ) == 'table' then
				v = alist( v )
			end
			
			lst = lst:add( cons( k, v ) )
		end
		return lst
	else
		return lst:add( vs )
	end
end

local function range( from, to, step )
	local function doForwardRange( lr, index, from, step )
		if index < from then
			return lr
		else
			return doForwardRange( lr:add( index ), index - step, from, step )
		end
	end

	local function doBackwardRange( lr, index, from, step )
		if index > from then
			return lr
		else
			return doBackwardRange( lr:add( index ), index - step, from, step )
		end
	end

	if to == nil and step == nil then
		to = from
		from = to > 0 and 1 or to < 0 and -1 or 0 
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

local function reverse( lst ) return lst:foldl( cons, Nil ) end
local function copy( lst ) return lst:foldr( cons, Nil ) end
local function append( lst, lstTail )
	return lst:reverse():foldl( cons, islist( lstTail ) and lstTail or list(lstTail) )
end

local function length( lst ) 
	local function doLength( lst, acc )
		if lst:isnil() then
			return acc
		else
			return doLength( lst:cdr(), acc + 1 )
		end
	end

	return doLength( lst, 0 )
end

local function each( lst, f )
	local function doEach( v, acc ) 
		f( v ) 
	end

	lst:foldr( doEach, Nil )
end

local function count( lst, p )
	local function doCount( v, acc )
		if p( v ) then
			acc = acc + 1
		end
		return acc
	end

	return lst:foldl( doCount, 0 )
end

local function all( lst, p )
	if lst:isnil() then
		return true
	elseif p( lst:car()) then
		return all( lst:cdr(), p )
	else
		return false
	end
end

local function any( lst, p )
	if lst:isnil() or p( lst:car()) then
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

local function flatten( lst )
	local function doFlatten( v, acc )
		if ispair( v ) then
			return v:foldr( doFlatten, acc )
		else
			return acc:add( v )
		end
	end
	
	return lst:foldr( doFlatten, Nil )
end

local function mergeReverse( lst1, lst2, cmp )	
	local function doMerge( lst1, lst2, cmp, acc )
		if lst1:isnil() then
			return lst2:foldl( cons, acc )
		elseif lst2:isnil() then
			return lst1:foldl( cons, acc )
		else
			local car1, car2 = lst1:car(), lst2:car()
			if cmp( car1, car2 ) then
				return doMerge( lst1:cdr(), lst2, cmp, acc:add( car1 ))
			else
				return doMerge( lst1, lst2:cdr(), cmp, acc:add( car2 ))
			end
		end
	end

	return doMerge( lst1, lst2, cmp, Nil )
end

local function merge( lst1, lst2, cmp )
	return mergeReverse( lst1, lst2, cmp ):reverse()
end

local function lt( a, b )
	return a < b
end

local function sort( lst, cmp )
	local function doSort( lr, part, cmp )
		if isnil( part ) then
			if isnil( lr:cdr()) then
				return lr:car()
			else
				return doSort( part, lr, cmp )
			end
		elseif isnil( part:cdr()) then
			return doSort( lr:add( part:car()), part:cdr(), cmp )
		else
			return doSort( lr:add( part:car():merge( part:cadr(), cmp )), part:cddr(), cmp )
		end
	end

	return doSort( Nil, lst:map( list ), cmp or lt )
end

local function totable( lst )
	if ispair( lst ) then
		local acc = {}
		while not lst:isnil() do
			if lst:islist() then
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

local function tostring_( lst )
	if ispair( lst ) then
		local acc = {}
		while not lst:isnil() do
			if lst:islist() then
				acc[#acc+1] = tostring_( lst:car())
				lst = lst:cdr()	
			elseif lst:ispair() then
				acc[#acc+1] = tostring_( lst:car())
				acc[#acc+1] = '.'
				acc[#acc+1] = tostring_( lst:cdr())
				break
			else
				acc[#acc+1] = tostring( lst )
				break
			end
		end
		acc[1] = '(' .. acc[1]
		acc[#acc] = acc[#acc] .. ')'
		return table.concat( acc, ' ')
	elseif isnil( lst ) then
		return '()'
	else
		return tostring( lst )
	end
end

local function display( lst, index )
	if index then
		print( lst:ref( index ))
	else
		print( lst ) 
	end
	return lst or Nil
end

local unpack = table.unpack or unpack

local function eval( lst )
	local v = lst:car()( unpack( lst:cdr():totable()))
	return v
end

local function shuffle( lst )
	error( 'Not implemented' )
	
	local function doShuffle( lst, acc, len )
		
	end

	return doShuffle( lst, Nil, lst:length() )
end

local _clocks, _mem, _nclocks = {}, {}, 0

local function pushclock( lst )
	_nclocks = _nclocks + 1
	_clocks[_nclocks] = os.clock()
	_mem[_nclocks] = 1024 * collectgarbage('count')
	return lst or Nil
end

local function popclock( lst, abs )
	if _nclocks > 0 then
		local clck, mem = _clocks[_nclocks], _mem[_nclocks]
		_clocks[_nclocks] = nil
		_mem[_nclocks] = nil
		_nclocks = _nclocks - 1
		print( 'Time:', os.clock() - (abs and 0 or clck), 'Mem:', 1024 * collectgarbage('count') - (abs and 0 or mem))
	else
		print( 'Empty clocks stack' )
	end
	return lst or Nil
end

local function equal( lst, lst2 )
	if lst == lst2 or lst == Wild or lst2 == Wild then
		return true
	elseif islist( lst ) and islist( lst2 ) then
		if not equal( lst:car(), lst2:car()) then
			return false
		else
			return equal( lst:cdr(), lst2:cdr())
		end
	else
		return false
	end
end

local function gc( lst, ... )
	collectgarbage( ... )
	return lst
end

local List = {
	Nil = Nil, Wild = Wild, _ = Wild,
	cons = cons, add = add, del = del, car = car, cdr = cdr, cadr = cadr, caar = caar, cdar = cdar, cddr = cddr,
	foldl = foldl, foldr = foldr, map = map, filter = filter, mapfilter = mapfilter, filtermap = filtermap, reverse = reverse, each = each, unique = unique, 
	list = list, range = range, length = length,
	indexof = indexof, exists = exists, ref = ref, tail = tail, append = append, copy = copy, partition = partition, flatten = flatten,
	count = count, all = all, any = any, alist = alist,
	islist = islist, isproperlist = isproperlist, ispair = ispair, isnil = isnil, iswild = iswild, 
	tostring = tostring_, display = display, totable = totable,
	sort = sort, merge = merge, equal = equal,
	pushclock = pushclock, popclock = popclock, gc = gc, eval = eval,
}

PairMt = { 
	__index = List,
	__tostring = List.tostring,
	__len = List.length,
	__concat = List.append,
}

Nil = setmetatable( {}, PairMt )

List.export = function()
	_G.List = List
	return List
end

return setmetatable( List, { __call = function( self, vs ) 
	return list(vs) 
end } )

