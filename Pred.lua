local Pred = {
	n = function( a ) return a == nil end,
	t = function( a ) return a == true end,
	f = function( a ) return a == false end,
	boolean = function( a ) return type( a ) == 'boolean' end,
	number = function( a ) return type( a ) == 'number' end,
	integer = function( a ) return type( a ) == 'number' and math.floor( a ) == a end,
	string = function( a ) return type( a ) == 'string' end,
	thread = function( a ) return type( a ) == 'thread' end,
	userdata = function( a ) return type( a ) == 'userdata' end,
	table = function( a ) return type( a ) == 'table' end,
	func = function( a ) return type( a ) == 'function' end,
	even = function( a ) return a % 2 == 0 end,
	odd = function( a ) return a % 2 == 1 end,
	positive = function( a ) return a > 0 end,
	negative = function( a ) return a < 0 end,
	zero = function( a ) return a == 0 end,
	id = function( a ) return type( y ) == 'string' and y:match('[%a_][%w_]*') == y end,
}

Pred.export = function()
	_G.Pred = Pred
	return Pred
end

return Pred
