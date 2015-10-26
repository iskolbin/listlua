local ImmuTableMt = {}

local Nil = {}

local _tables = setmetatable( {}, {__mode = 'k'} )

local function new( t )
	local self = setmetatable( {}, ImmuTableMt )
	local t_ = {}
	_tables[self] = t_
	if type( t ) == 'table' then
		for k, v in pairs( t ) do
			t_[k] = v
		end
	end
	return self
end

local function add( t, key, value )
	local self = setmetatable( {}, ImmuTableMt )
	local t_ = {}
	_tables[self] = t_
	for k, v in pairs( _tables[t] ) do
		t_[k] = v
	end

	if value == Nil then
		t_[key] = nil
	else
		t_[key] = value
	end

	return self
end

local function del( t, key )
	return add( t, key, Nil )
end

local function update( t, vs )
	local self = setmetatable( {}, ImmuTableMt )
	local t_ = {}
	_tables[self] = t_
	for k, v in pairs( _tables[t] ) do
		t_[k] = v
	end

	for k, v in pairs( vs ) do
		if v == Nil then
			t_[k] = nil
		else
			t_[k] = v
		end
	end

	return self
end

local function isimmutable( t )
	return _tables[t]
end

ImmuTableMt.__index = function( self, k ) 
	return _tables[self][k]
end

ImmuTableMt.__newindex = function()
	error[[

Unfortunatly, changing value in table is a statement, so it's pointless in case of immutable tables, since you cannot aquire updated version. So you cannot directly change immutable.

Use function call notation instead: 
 t("foo",42) for addition;
 t("baz") or t("baz", ImmuTable.Nil) for deletion
]]
end

ImmuTableMt.__call = function( self, k, v )
	if v == nil then
		return del( self, k )
	else
		return add( self, k, v )
	end
end

ImmuTableMt.__concat = function( self, other )
	return update( self, _tables[other] )
end

ImmuTableMt.__len = function( self )
	return #_tables[self]
end

ImmuTableMt.__pairs = function( self )
	return pairs( _tables[self] )
end

ImmuTableMt.__ipairs = function( self )
	return ipairs( _tables[self] )
end

return setmetatable( {
	Nil = Nil,
	new = new,
	add = add,
	del = del,
	update = update,
	parent = function( t ) return _tables[t] end,
	isimmutable = isimmutable,
}, {__call = function( self, t )
	return new( t )
end } )
