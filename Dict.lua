local Common = require'Common'
local List = require'List'

local DictMt

local KEY, VALUE, LEFT, RIGHT, LEVEL = 1, 2, 3, 4, 5

local Nil = {false,false,false,false,0}

local function setmt( dct )
	return setmetatable( dct, DictMt )
end

local function skew( bst )
	if bst ~= Nil then
		local lbst = bst[LEFT]
		if lbst ~= Nil then
			local level = bst[LEVEL]
			local llevel = lbst[LEVEL]
			if level == llevel then
				return setmt{lbst[KEY], lbst[VALUE], lbst[LEFT], setmt{bst[KEY], bst[VALUE], lbst[RIGHT], bst[RIGHT], level}, level}
			end
		end
	end
	return bst
end

local function split( bst )
	if bst ~= Nil then
		local rbst = bst[RIGHT]
		if rbst ~= Nil then
			local rrbst = rbst[RIGHT]
			if rrbst ~= Nil then
				local level = bst[LEVEL]
				local rrlevel = rrbst[LEVEL]
				if level == rrlevel then
					return setmt{rbst[KEY], rbst[VALUE], setmt{bst[KEY], bst[VALUE], bst[LEFT], rbst[LEFT], level}, rrbst, level+1}
				end
			end
		end
	end
	return bst
end

local function ref( bst, key )
	if bst == Nil then
		return false
	elseif key == bst[KEY] then
		return bst[VALUE]
	elseif key < bst[KEY] then
		return ref( bst[LEFT], key )
	else
		return ref( bst[RIGHT], key )
	end
end

local function add( bst, key, value )
	local function rebalance( bst )
		return split( skew ( bst ))
	end

	if bst == Nil then
		return setmt{key, value, Nil, Nil, 1}
	else
		local selfkey = bst[KEY]
		if key == selfkey then
			return setmt{key, value, bst[LEFT], bst[RIGHT], bst[LEVEL]}
		elseif key < selfkey then
			return rebalance( setmt{selfkey, bst[VALUE], add( bst[LEFT], key, value ), bst[RIGHT], bst[LEVEL]})
		else
			return rebalance( setmt{selfkey, bst[VALUE], bst[LEFT], add( bst[RIGHT], key, value ), bst[LEVEL]})
		end
	end
end

local function del( bst, key )
	local function rebalance( bst )
		local function decrease( bst )
			local function min( a, b )
				return a > b and b or a
			end
			local shouldbe = min( bst[LEFT][LEVEL], bst[RIGHT][LEVEL] + 1 )
			if shouldbe < bst[LEVEL] then
				return setmt{bst[KEY], bst[VALUE], bst[LEFT], bst[RIGHT], shouldbe}
			elseif shouldbe < bst[RIGHT][LEVEL] then
				return setmt{bst[KEY], bst[VALUE], bst[LEFT], setmt{bst[RIGHT][KEY], bst[RIGHT][VALUE], bst[RIGHT][LEFT], bst[RIGHT][RIGHT], shouldbe}, bst[LEVEL]}
			else
				return bst
			end
		end

		local bst1 = skew( decrease( bst ))
		local bst2 = setmt{bst1[KEY], bst1[VALUE], bst1[LEFT], skew( bst1[RIGHT] ), bst1[LEVEL]}
		local bst3 = bst2
		local bst2r = bst2[RIGHT]
		if bst2r ~= Nil then
			local bst3rr = skew( bst2r[RIGHT] )
			local bst3r = setmt{bst2r[KEY], bst2r[VALUE], bst2r[LEFT], bst3rr, bst2r[LEVEL]}
			bst3 = setmt{bst2[KEY], bst2[VALUE], bst2[LEFT], bst3r, bst2[LEVEL]}
		end
		local bst4 = split( bst3 )
		return setmt{bst4[KEY], bst4[VALUE], bst4[LEFT], split( bst4[RIGHT] ), bst4[LEVEL]}
	end

	local function predecessor( bst )
		local bst_ = bst[LEFT]
		while bst_[RIGHT] ~= Nil do
			bst_ = bst_[RIGHT]
		end
		return bst_
	end

	local function successor( bst )
		local bst_ = bst[RIGHT]
		while bst_[LEFT] ~= Nil do
			bst_ = bst_[LEFT]
		end
		return bst_
	end

	if bst ~= Nil then
		local selfkey = bst[KEY]
		if selfkey == key then
			if bst[LEFT] == Nil and bst[RIGHT] == Nil then
				return Nil
			else
				if bst[LEFT] == Nil then
					local bsts = successor( bst )
					return setmt{bsts[KEY], bsts[VALUE], Nil, del( bst[RIGHT], bsts[KEY] ), bst[LEVEL]}
				else
					local bstp = predecessor( bst )
					return setmt{bstp[KEY], bstp[VALUE], del( bst[LEFT], bstp[KEY] ), bst[RIGHT], bst[LEVEL]}
				end
			end
		elseif key < selfkey then
			return rebalance( setmt{selfkey, bst[VALUE], del( bst[LEFT], key ), bst[RIGHT], bst[LEVEL]} )
		else
			return rebalance( setmt{selfkey, bst[VALUE], bst[LEFT], del( bst[RIGHT], key ), bst[LEVEL]} )
		end
	else
		return bst
	end
end

local function is( dct, what )
	if what == 'dict' then
		return getmetatable( dct ) == DictMt
	elseif what == 'nildict' then
		return dct == Nil
	else
		return Common.is( dict, what )
	end
end

local function isdict( dct )
	return getmetatable( dct ) == DictMt 
end

local function isnil( dct )
	return dct == Nil
end

local function update( dct, t )
	for k, v in pairs( t ) do
		if v == Nil then
			dct = del( dct, k )
		else
			dct = add( dct, k, v )
		end
	end
	return dct
end

local function dict( t, ... )
	local dct = Nil
	if type( t ) == 'table' then
		for k, v in pairs( t ) do
			dct = add( dct, k, v )
		end
		return dct
	elseif type( t ) == 'function' then
		for k, v in t, ... do
			dct = add( dct, k, v )
		end
		return dct
	elseif t == nil then
		return dct 
	else
		error( 'Dict can be initialized from table or iterator or from nil')
	end
end

local function set( t )
	local dct = Nil
	for i = 1, #t do
		dct = add( dct, t[i], true )
	end
	return dct
end

local function length( dct )
	if not dct then
		return 0
	else
		return 1 + length( dct[LEFT] ) + dct( dct[RIGHT] )
	end
end

local function height( dct )
	local function max( a, b )
		return a > b and a or b
	end
	
	if not dct then
		return 0
	else
		return 1 + max( height( dct[LEFT] ), height( dct[RIGHT] ))
	end
end

local function each( dct, f ) 
	if dct then
		each( dct[LEFT] )
		f( dct[VALUE], dct[KEY] )
		each( dct[RIGHT] ) 
	end 
end

local function map( dct, f ) 
	if isdict( dct ) then
		return setmt{dct[KEY], f( dct[VALUE], dct[KEY] ), map( dct[LEFT], f ), map( dct[RIGHT], f ), dct[LEVEL]}
	end
end

local function filter( dct, p )
	if isdict( dct ) then
		if p( dct[VALUE], dct[KEY] ) then
			return setmt{dct[KEY], dct[VALUE], filter( dct[LEFT], p ), filter( dct[RIGHT], p ), dct[LEVEL]}
		else
			return filter( del( dct, dct[KEY] ), p )
		end
	end
end

local function filtermap( dct, p, f )
	if isdict( dct ) then
		if p( dct[VALUE], dct[KEY] ) then
			return setmt{dct[KEY], f( dct[VALUE] ), filtermap( dct[LEFT], p, f ), filtermap( dct[RIGHT], p, f ), dct[LEVEL]}
		else
			return filtermap( del( dct, dct[KEY] ), p, f )
		end
	end
end

local function mapfilter( dct, f, p )
	if dct then
		local v = f( dct[VALUE], dct[KEY] )
		if p( v ) then
			return setmt{dct[KEY], v, mapfilter( dct[LEFT], p ), mapfilter( dct[RIGHT], p ), dct[LEVEL]}
		else
			return mapfilter( del( dct, dct[KEY] ), f, p )
		end
	end
end

local function foldl( dct, f, acc ) 
	if dct then
		return foldl( dct[RIGHT], f, foldl( dct[LEFT], f, f( dct[VALUE], acc, dct[KEY] )))
	else 
		return acc 
	end
end

local function foldr( dct, f, acc ) 
	if dct then
		return foldr( dct[LEFT], f, foldr( dct[RIGHT], f, f( dct[VALUE], acc ))) 
	else
		return acc
	end
end

local function count( dct, p )
	local function addif( v, acc, k )
		return p( v, k ) and acc + 1 or acc
	end
	return foldl( dct, addif, 0 )
end

local function copy( dct )
	if isdict( dct ) then
		return setmt{copy( dct[KEY] ), copy( dct[VALUE] ), copy( dct[LEFT] ), copy( dct[RIGHT] ), dct[LEVEL]}
	else
		return dct
	end
end

local function indexof( dct, value )
	if isdict( dct ) then
		if dct[VALUE] == value then
			return dct[KEY]
		else
			local leftKey = indexof( dct[LEFT], value )
			if leftKey ~= nil then
				return leftKey
			else
				return indexof( dct[RIGHT], value )
			end
		end
	end
end

local function totable( dct, mode )
	local function doToTable( dct, t )
		if isdict( dct ) and not isnil( dct ) then doToTable( dct[LEFT], t ); t[dct[KEY]] = dct[VALUE]; doToTable( dct[RIGHT], t ) end; return t
	end
	
	local function kdoToTable( dct, t )
		if isdict( dct ) and not isnil( dct ) then kdoToTable( dct[LEFT], t ); t[#t+1] = dct[KEY]; kdoToTable( dct[RIGHT], t ) end; return t
	end

	local function vdoToTable( dct, t )
		if isdict( dct ) and not isnil( dct ) then vdoToTable( dct[LEFT], t ); t[#t+1] = dct[VALUE]; vdoToTable( dct[RIGHT], t ) end; return t
	end
	
	local function kvdoToTable( dct, t )
		if isdict( dct ) and not isnil( dct ) then kvdoToTable( dct[LEFT], t ); t[#t+1] = {dct[KEY], dct[VALUE]}; kvdoToTable( dct[RIGHT], t ) end; return t
	end
	
	if mode == nil or mode == 't' then
		return doToTable( dct, {} )
	elseif mode == 'k' then
		return kdoToTable( dct, {} )
	elseif mode == 'v' then
		return vdoToTable( dct, {} )
	elseif mode == 'kv' then
		return kvdoToTable( dct, {} )
	else
		error( 'Mode should be nil or "t", "k", "v" or "kv"')
	end
end

local function tolist( dct, mode )
	return List.list( totable( dct, mode or 'kv' ))
end

local function tostring_( dct, sep )
	return dct:tolist('kv'):tostring( sep )
end

local function display( dct, sep )
	print( tostring_(dct, sep) )
	return dct
end

local Dict = {
	Nil = Nil, 
	is = is, isdict = isdict, isnil = isnil,
	add = add, del = del, ref = ref, update = update, length = length, copy = copy, 
	indexof = indexof, tolist = tolist, totable = totable, toarray = toarray, 
	set = set, dict = dict, tostring = tostring_, display = display,
	map = map, filter = filter, foldl = foldl, foldr = foldr, count = count, each = each,
	filtermap = filtermap, mapfilter = mapfilter, cond = List.cond,
}

Dict.Nil = setmt( Nil )

DictMt = {
	__index = Dict,
	__len = length,
	__tostring = tostring_,
}

Dict.import = function( dct )
	_G.Dict = Dict
	return dct
end

return setmetatable( Dict, { __call = function( self, ... )
	return dict( ... )
end, __index = Common } )
