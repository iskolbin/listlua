local unpack = table.unpack or unpack

local Op = {
	add = function( a, b ) return a + b end,
	sub = function( a, b ) return a - b end,
	div = function( a, b ) return a / b end,
	idiv = function( a, b ) return a >= 0 and math.floor( a / b ) or math.ceil( a / b ) end,
	mod = function( a, b ) return a % b end,
	mul = function( a, b ) return a * b end,
	pow = function( a, b ) return a ^ b end,
	concat = function( a, b ) return a .. b end,
	len = function( a ) return #a end,
	neg = function( a ) return -a end,

	lor = function( x, y ) return x or y end,
	land = function( x, y ) return x and y end,
	lnot = function( x ) return not x end,
	lxor = function( x, y ) return (x and not y) or (y and not x) end,

	lt = function( a, b ) return a <  b end,
	le = function( a, b ) return a <= b end,
	eq = function( a, b ) return a == b end,
	ne = function( a, b ) return a ~= b end,
	gt = function( a, b ) return a >  b end,
	ge = function( a, b ) return a >= b end,

	inc = function( a ) return a + 1 end,
	dec = function( a ) return a - 1 end,

	const = function( a ) return a end,

	curry = function( f, ... )
		local n = select( '#', ... )
		if n == 0 then return f
		elseif n == 1 then local b = ...; return function( a ) return f( a, b ) end
		elseif n == 2 then local b, c = ...; return function( a ) return f( a, b, c ) end
		elseif n == 3 then local b, c, d = ...; return function( a ) return f( a, b, c, d ) end
		else local vs = {...}; return function( a ) return f( a, unpack( vs )) end 
		end
	end,
}

local _cacheOpC = {}

Op.C = setmetatable( {}, {
	__index = function( _, k )
		local f = _cacheOpC[k]
		if not f then
			f = function( a )
				return Op.curry( Op[k], a )
			end
			_cacheOpC[k] = f
		end
		return f
	end} )

Op.import = function()
	_G.Op = Op
	return Op
end

return Op
