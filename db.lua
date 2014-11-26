require("luasql.sqlite3")
local dbfile = "/etc/db/hostdb.db"

function connectToDB(dbFile)
	dbFile = dbFile or "/etc/db/hostdb.db"
	local env = luasql.sqlite3()
	local db = env:connect(dbFile,'wr')
	err = db:execute([[
	CREATE TABLE if not exists hostRecords (mac TEXT PRIMARY KEY, nativeName TEXT UNIQUE, presentName TEXT UNIQUE, onOff INTERGER);
	]])
	
	return env,db,err
end

--insert a record
function insertHost(db,mac,native,newName,onOff)
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
function updateHost(db,mac,newName,onOff)
	onOff = onOff or 0
	local cmd = string.format("UPDATE hostRecords SET presentName = '%s' WHERE mac = '%s'",newName, mac)
	return db:execute(cmd)
	
end

--check a name
--@return true: OK, false: Not OK
function checkName(db,mac,name)
	if name == "" or name == nil then
		return false
	end
	
	local cmd = string.format("SELECT * FROM hostRecords WHERE nativeName = '%s' or presentName = '%s'",name,name)
	local cur = db:execute(cmd)
	local result = true
	row = cur:fetch({},'a')
	if row == nil then
		result = false
	end
	
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
function isExists(db,mac)
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
function insertRecord(mac,nativeName,presentName,onOff)
	onOff = onOff or 1
	if mac == nil or mac =="" then
		return false,"MAC address is invalid"
	end
	
	local env,db, err =  connectToDB()
	if env == nil or db == nil then
		return false,"Failed to open DataBase"
	end
	nixio.openlog()
	nixio.syslog("alert","before Exists")
	nixio.closelog()
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
		if checkName(db,mac,presentName) and  nil ~=  insertHost(db,mac,nativeName,presentName,onOff) then
			return true, "OK"

			
		else
			return false, "New Name is invalid"
		end
		
	end
	
	db:close()
	env:close()
	
end





--local env,db,err = connectToDB()

--cur = db:execute("SELECT * FROM hostRecords")
--row = cur:fetch({},"a")
--while row do
--	print(string.format("mac = %s, nativeName = %s, presentName = %s, onOff = %d",row.mac,row.nativeName,row.presentName or 'NULL',row.onOff))
--	row = cur:fetch(row,"a")
--end
--cur:close()
--db:close()
--env:close()
