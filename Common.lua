local _istable = {
	['nil'] = function( a ) return a == nil end,
	['true'] = function( a ) return a == true end,
	['false'] = function( a ) return a == false end,
	['boolean'] = function( a ) return type( a ) == 'boolean' end,
	['number'] = function( a ) return type( a ) == 'number' end,
	['integer'] = function( a ) return type( a ) == 'number' and math.floor( a ) == a end,
	['string'] = function( a ) return type( a ) == 'string' end,
	['thread'] = function( a ) return type( a ) == 'thread' end,
	['userdata'] = function( a ) return type( a ) == 'userdata' end,
	['table'] = function( a ) return type( a ) == 'table' end,
	['func'] = function( a ) return type( a ) == 'function' end,
	['even'] = function( a ) return a % 2 == 0 end,
	['odd'] = function( a ) return a % 2 == 1 end,
	['positive'] = function( a ) return a > 0 end,
	['negative'] = function( a ) return a < 0 end,
	['zero'] = function( a ) return a == 0 end,
	['id'] = function( a ) return type( a ) == 'string' and a:match('^[%a_][%w_]*') == a end,
}

local function is( obj, tp )
	return _istable[tp] and _istable[tp]( obj )
end

local function cond( obj, ... )
	local n = select( '#', ... )
	for i = 1, n, 2 do
		if select( i, ... )( obj ) then
			return select( i + 1, ... )( obj )
		end
	end
	if n % 2 == 1 then
		return select( n, ... )( obj )
	end
end

local function gc( obj, ... )
	collectgarbage( ... )
	return obj
end

local _clocks, _mem, _nclocks = {}, {}, 0

local function pushclock( obj )
	_nclocks = _nclocks + 1
	_clocks[_nclocks] = os.clock()
	_mem[_nclocks] = 1024 * collectgarbage('count')
	return obj
end

local function popclock( obj, abs )
	if _nclocks > 0 then
		local clck, mem = _clocks[_nclocks], _mem[_nclocks]
		_clocks[_nclocks] = nil
		_mem[_nclocks] = nil
		_nclocks = _nclocks - 1
		print( 'Time:', os.clock() - (abs and 0 or clck), 'Mem:', 1024 * collectgarbage('count') - (abs and 0 or mem))
	else
		print( 'Empty clocks stack' )
	end
	return obj
end

local Common = {	
	cond = cond,
	pushclock = pushclock, 
	popclock = popclock, 
	gc = gc, 
	is = is,
}

Common.import = function()
	_G.Common = Common
	return Common
end

return Common
