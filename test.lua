local Promise = require("Promise")

function getPendingResolve(r) 
	return Promise.new(function(resolve,reject)
		r.resolve=resolve
	end)
end

function getPendingReject(r) 
	return Promise.new(function(resolve,reject)
		r.reject=reject
	end)
end

function test1()

	local p1 = Promise.resolve(1)
	local p2 = p1:andThen(function (s)
		print(s)
		return Promise.reject(2)
	end)
	local p3 = p2:andThen(function (s)
		print(s)
		return Promise.resolve(3)
	end,function (err)
		print("on reject 1")
		return err
	end)

	local p4 = p3:andThen(function (s)
		print(s)
	end,function (err)
		print("on reject 2")
	end)
end

function test2()
	local p1 = Promise.resolve(1)
	local p2 = p1:andThen(function (s)
		print(s)
		return 2*s
	end)
	local p3 = p2:andThen(function (s)
		print(s)
		return 3*s
	end)

	local p4 = p3:andThen(function (s)
		print(s)
	end)	

end

function test3()
	local p1 = Promise.resolve(1)
	local r1 = {}
	local r2 = {}
	local r3 = {}	
	local p2 = p1:andThen(function (s)
		print("p1",s)
		return getPendingResolve(r1)
	end)
	local p3 = p2:andThen(function (s)
		print("p2",s)
		return getPendingResolve(r2)
	end)

	local p4 = p3:andThen(function (s)
		print("p3",s)
		return Promise.resolve(4)--]]getPendingResolve(r3)
	end)

	local p5 = p4:andThen(function (s)
		print("p4",s)
	end)

	r1.resolve(2)
	r2.resolve(3)
	--r3.resolve(4)
end


function test4()
	local p1 = Promise.resolve(1)
	local r1 = {}
	local r2 = {}	
	local r3 = {}
	local p2 = p1:andThen(function (s)
		print("p1",s)
		return getPendingResolve(r1):andThen(function (s)
				print("nest andThen")
				return s
			end)
	end)
	local p3 = p2:andThen(function (s)
		print("p2",s)
		return getPendingReject(r2)
	end)
	local p4 = p3:catch(function (s)
		print("p3",s)
		return getPendingReject(r3)
	end)
	local p5 = p4:andThen(function (s)
		print("p4",s)
	end)
	p5:final(function (s)
		print("final",s)
	end)


	r1.resolve(2)
	r2.reject("error")
	r3.reject("r3")
end

function test5()

	local p1 = Promise.resolve(1)
	local p2 = Promise.resolve(2)
	local p3 = Promise.reject(3)

	Promise.all({p1,p2,p3}):andThen(function (s)
		print(s[1],s[2],s[3])
	end,function (s)
		print(s[1],s[2],s[3])
	end)
end

function test6()

	local r1 = {}
	local r2 = {}

	local p1 = getPendingResolve(r1) --Promise.resolve(1)
	local p2 = getPendingResolve(r2) --Promise.resolve(2)
	local p3 = Promise.reject(3)

	Promise.race({p1,p2,p3}):andThen(function (s)
		print(s)
	end,function (s)
		print(s)
	end)
end

function test7()

	local p1 = Promise.resolve(1)
	local r1 = {}
	local r2 = {}	
	local r3 = {}
	local p2 = p1:andThen(function (s)
		print("p1",s)
		return getPendingResolve(r1)
	end)


	local p3 = p2:andThen(function (s)
		print("p2",s)
		return s
	end)
	r1.resolve(getPendingResolve(r2))
	r2.resolve(Promise.new(function(resolve,reject)
		print("here")
		resolve(10)
	end))
end

function test8()

	Promise.reject("error"):andThen(function (s)
		print("1")
	end,function (err)
		print("on failed:" .. err)
		return Promise.reject("reject2")		
	end):andThen(function (s)
		print("on success")
	end,function (err)
		print(err)
	end)


end

function test9()
	local r = {}
	getPendingReject(r):andThen(function (s)
		print("success")
	end,function (err)
		print("on failed:" .. err)
		return Promise.throw("reject2")
	end):andThen(function (s)
		print("on success")
	end,function (err)
		print(err)
	end)

	r.reject("error")


end

function test10()
	local p = {}
	table.insert(p,Promise.resolve("resolve1"))
	table.insert(p,Promise.resolve("resolve2"))
	table.insert(p,Promise.reject("reject3"))

	Promise.all(p):andThen(function (r)
		print(r[1],r[2],r[3])
	end,function (r)
		print(r[1].state,r[2].state,r[3].state)
		print(r[1].value,r[2].value,r[3].value)		
	end)

end


print("-----------test1-------------------")
test1()
print("-----------test2-------------------")
test2()
print("-----------test3-------------------")
test3()
print("-----------test4-------------------")
test4()
print("-----------test5-------------------")
test5()
print("-----------test6-------------------")
test6()
print("-----------test7-------------------")
test7()
print("-----------test8-------------------")
test8()
print("-----------test9-------------------")
test9()
print("-----------test10-------------------")
test10()

