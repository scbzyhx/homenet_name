
local modname =...

local luasql = require("luasql.sqlite3")
--in router, while util in model/, require("luci.model.util")
--
local util = require("luci.model.util")

--local dbfile = "/etc/db/hostdb.db"
local MAX_INT = 9876543210  -- may be a smaller integer is OK
local MAX_TTL = 256
--[[
local function connectToDB(dbFile)
	dbFile = dbFile or "/etc/db/hostdb.db"
	local env = luasql.sqlite3()
	local db = env:connect(dbFile,'wr')
	err = db:execute(
	CREATE TABLE if not exists speedTable (nw_dst TEXT PRIMARY KEY COLLATE NOCASE, delay INTEGER,ttl INTEGER,bw REAL);
	)
	
	return env,db,err
end
]]--
--local luasql = require("luasql.sqlite3")
--local dbfile = "/etc/db/hostdb.db"

local function connectToDB(dbFile)
	dbFile = dbFile or "/etc/db/hostdb.db"
	local env = luasql.sqlite3()
	local db = env:connect(dbFile,'wr')
	err = db:execute([[
	CREATE TABLE if not exists hostRecords (mac TEXT PRIMARY KEY COLLATE NOCASE, nativeName TEXT UNIQUE COLLATE NOCASE, presentName TEXT UNIQUE COLLATE NOCASE, onOff INTERGER);]])
	err = db:execute([[
	CREATE TABLE if not exists speedTable (nw_dst TEXT PRIMARY KEY COLLATE NOCASE, delay INTEGER,ttl INTEGER,bw REAL);
	
	]])
	
	return env,db,err
end

--insert a record
local function insertHost(db,mac,native,newName,onOff)
	newName = newName or 'NULL'
	if newName ~= 'NULL' then
		newName = "'"..newName.."'"
	end
	
	onOff = onOff or 0
	local err
	--more check
	if mac == nil or mac == "" or native == nil or native  == "" then 
		err = nil
		return err
	end
	err = db:execute(string.format("INSERT INTO hostRecords VALUES('%s','%s',%s,%d)",mac,native,newName or 'NULL',onOff))
	return err
end

--update a record
local function updateHost(db,mac,newName,onOff)
	onOff = onOff or 0
	local cmd = string.format("UPDATE hostRecords SET presentName = '%s' WHERE mac = '%s'",newName, mac)
	return db:execute(cmd)
	
end

--check a name
--@return true: OK, false: Not OK
local function checkName(db,mac,name)
	if name == "" or name == nil then
		return false
	end
	
	local cmd = string.format("SELECT * FROM hostRecords WHERE nativeName = '%s' or presentName = '%s'",name,name)
	local cur = db:execute(cmd)
	local result = true
	row = cur:fetch({},'a')
	
	--if row == nil then
	--	result = false
	--end
	
	while row do
		if row.mac ~= mac then
			result = false
			break
		end
		row = cur:fetch(row,'a')
		
	end
	cur:close()
	return result
	
	
end

--whether record exists
local function isExists(db,mac)
	if mac == "" or mac == nil then
		return nil
	end
	
	local cmd = string.format("SELECT * FROM hostRecords WHERE mac = '%s'",mac)
	local cur = db:execute(cmd)
	if cur:fetch({},'a') == nil then
		cur:close()
		return false
	else
		cur:close()
		return true
	end

end

--insert a record
--@return: falseName(nil,or "" or )
local function insertRecord(mac,nativeName,presentName,onOff)
	onOff = onOff or 1
	if mac == nil or mac =="" then
		return false,"MAC address is invalid"
	end
	
	local env,db, err =  connectToDB()
	if env == nil or db == nil then
		return false,"Failed to open DataBase"
	end
	--nixio.closelog()
	if isExists(db,mac) then
		--Sure that presentName is valid
		if presentName == nil or presentName == "" then
			return false,"New Name is invalid"
		end
		
		if not checkName(db,mac,presentName) then
			return false, "Error presentName"
		end
		
		--So update 
		return true, updateHost(db,mac,presentName,onOff)
	else
		
		--check nativeName and presentName
		--if checkName(db,mac,presentName) then
		
			nixio.openlog()
			if checkName(db,mac,presentName) then
				nixio.syslog("alert","YHX CHECKNAME TRUE")
			else
				nixio.syslog("alert","YHX CHECKNAME FALSE")
			end
			nixio.closelog()
		if checkName(db,mac,presentName) then --and nil ~=insertHost(db,mac,nativeName,presentName,onOff) then
		 	local inr = insertHost(db,mac,nativeName,presentName,onOff)
			nixio.openlog()
			if inr then 
				nixio.syslog("alert","YHX INSERT TRUE")
			else
				nixio.syslog("alert","YHX INSERT FALSE")
			end
			nixio.closelog()
			return true, "OK"
		else
			return false, "New Name is invalid"
		end
		
	end
	db:close()
	env:close()
	
end

--get presentName
local function getPresentName(mac)
	local env,db,err = connectToDB()
	local cmd = string.format("select presentName from hostRecords where mac = '%s'",mac)
	local cur = db:execute(cmd)
	local name
	row = cur:fetch({},'a')
	while row do
		name = row.presentName
		break
		--row = cur:fetch(row,'a')
	end
	--return name
	cur:close()
	db:close()
	env:close()
	return name
end

local M = {


}
--[[local modname = ...
--if modname == nil then
--    db = M
--else
    _G[modname] = M
end
return M
]]--
--
--delay time : an interger , 1/1000 millisecond
--           : (0,MAXINT) : delay time ----------in fact it's impossible be such a big number
--           : -1: NO DATA
--           : 0: unreachable
--TTL : integer
--bw is bandwidth value, REAL , KB/s 
--
local function insertSpeed(db,ip,delay,ttl,bw)
    ttl = ttl or MAX_TTL
    bw = bw or 0
    delay = delay or MAX_INT
    local cmd = string.format("INSERT INTO speedTable VALUES('%s',%d,%d,%f)",ip,delay,ttl,bw)
    local err = db:execute(cmd)
    return err
end

--args is a table, just delay ttl or bw is promised
local function updateSpeed(db,ip,args)
    if not util.isValidIP(ip) then
        print("invalid IP address")
        return nil
    end
    -- table mustn't be empty
    -- TO 
    if type(args) ~= 'table' then
        print("args must be a table")
    end
    local delay = args.delay
    local ttl = args.ttl
    local bw = args.bw
    local cmd = "UPDATE speedTable SET "
    if delay ~= nil then
        cmd = string.format(cmd.."delay = %d ",delay)
    end
    if ttl ~= nil then
        cmd = string.format(cmd.."ttl = %d ",ttl)
    end
    if bw ~= nil then
        cmd = string.format(cmd.."bw = %f ",bw)
    end

    cmd = string.format(cmd .. "WHERE ip = '%s'",ip)
    return db:execute(cmd)

end
local function delSpeed(db,ip)
    if not util.isValid(ip) then
        print("invalide IP address")
        return nil
    end
    local cmd = string.format("delete from speedTable where ip = '%s'",ip)
    return db:execute(cmd)
end
local function execute(db,cmd)
    return db:execute(cmd)
end
local function lookup(db,ip)
    --env,db,err = connectToDB()
    if lookup == nil or db == nil or util.isValidIP(ip) == false then
        print("invalid IP address or didn't connect to database")
    end
    local cmd = string.format("SELECT * FROM speedTable WHERE nw_dst = '%s'",ip)
    local cursor,err = db:execute(cmd)
    row = cursor:fetch({},'a')
    local d = nil
    local t = nil
    local b = nil
    -- in fact only one row
    while row do
        --print(string.format("%s %d %d %d",row.nw_dst,row.delay,row.ttl,row.bw))
        --row = cursor:fetch(row,"a")
        d,t,b =  row.delay,row.ttl,row.bw
        break

    end
    cursor:close()
    return d,t,b

end

local function insert(ip,delay,ttl,bw)
    local env,db,err = connectToDB('tmp.db')
    insertSpeed(db,ip,delay,ttl,bw)
    db:close()
    env:close()
end

--test
--insert("192.168.1.1",1,1,1)
--env,db,err = connectToDB('tmp.db')
--print(lookup(db,'192.168.1.1'))

local M = {
    connectToDB = connectToDB,
    insertSpeed = insertSpeed,
    updateSpeed = updateSpeed,
    delSpeed = delSpeed,
    insert = insert,
    execute = execute,
    lookup = lookup,
    
    --connectToDB = connectToDB,
    insertHost = insertHost,
    updateHost = updateHost,
    checkName = checkName,
    isExists = isExists,
    insertRecord = insertRecord,
    getPresentName = getPresentName
}
if modname == nil then
    spdb = M
else
    _G[modname] = M
end

return M
