local M = {}

local promise = {}
promise.__index = promise

local PENDING  = 1
local RESOLVED = 2
local REJECTED = 3

local TABLE = 1
local FUNC  = 2

local resolve
local reject

local function isPromise(value)
	return getmetatable(value) == promise
end

local function setState(promise,state,value)
	if promise.state == PENDING then
		promise.state = state
		promise.value = value
		if state == REJECTED and promise.failure then
			promise.value = promise.failure(value)
		elseif state == RESOLVED and promise.success then
			promise.value = promise.success(value)
		end

		if isPromise(promise.value) and promise.value.state == PENDING then
			promise.value.parent = promise
			return
		end

		if promise.parent then
			for k,v in ipairs(promise.parent.queue) do
				table.insert(promise.queue,v)
			end
			promise.parent.queue = {}
		end

		if #promise.queue > 0 then
			value = promise.value
			if isPromise(value) then
				value = value.value
			end
			for _ , p in ipairs(promise.queue) do
				if promise.state == REJECTED then
					reject(p)(value) 	
				else
					resolve(p)(value)
				end
			end
		end
	end
end

resolve = function (promise) 
	return function (value)
		setState(promise,RESOLVED,value)
	end
end

reject = function (promise)
	return function (err)
		setState(promise,REJECTED,err)
	end
end

local function newPromise(option,optionType)
	local p = {}
	p.state = PENDING
	p.queue = {}
	p = setmetatable(p, promise)
	if optionType == FUNC then
		local ok, err = pcall(option, resolve(p), reject(p))
		if not ok then
			reject(p)(err)
		end
	elseif optionType == TABLE then
		p.success = option.success
		p.failure  = option.failure
	end
	return p
end

--instance method

function promise:andThen(success,failure)
	local next = newPromise({success=success,failure=failure},TABLE)

	local p

	if isPromise(self.value) then
		p = self.value
	else
		p = self
	end
	
	if p.state == PENDING then
		table.insert(p.queue,next)
	else
		if p.state == RESOLVED then
			resolve(next)(p.value)
		else
			reject(next)(p.value)
		end
	end
	
	return next
end

function promise:catch(failure)
	return self:andThen(nil,failure)
end

function promise:final(final)
	return self:andThen(final,final)
end

function M.new(func)
	if type(func) ~= 'function' then
		return nil
	end
	return newPromise(func,FUNC)
end

function M.all(args)
	local d = newPromise({},TABLE)
	if #args == 0 then
		return resolve(d)({})
	end
	local pending = #args
	local results = {}

	local function synchronizer(i, resolved)
		return function(value)
			results[i] = value
			pending = pending - 1
			if pending == 0 then
				if resolved then
					resolve(d)(results)
				else
					reject(d)(results)
				end
			end
			return value
		end
	end

	for i = 1, pending do
		args[i]:andThen(synchronizer(i, true), synchronizer(i, false))
	end
	return d
end


function M.race(args)
	local d = newPromise({},TABLE)
	for _, v in ipairs(args) do
		v:andThen(function(res)
			resolve(d)(res)
		end, function(err)
			reject(d)(err)
		end)
	end
	return d	
end


function M.resolve(value)
	return M.new(function (resolve,_)
		resolve(value)
	end)
end

function M.reject(err)
	return M.new(function (_,reject)
		reject(err)
	end)	
end

return M