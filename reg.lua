require("os")
require("luci.model.db")

-- split a string with specific string
string.split = function(s,p)
	local rt = {}
	string.gsub(s,'[^'..p..']+',function(w) table.insert(rt,w) end)
	return rt
end

-- Is there already specific name
function isIllegal(mac,localip,srcname,name)
	--hh = ""..name
	--more check to name
	if name == nil then
		return false
	end
	
	--luci.http.write("What")
	-- lookup database
	local result,_ = insertRecord(mac,srcname,name,1)
	if result == false then  return false end
	--luci.http.write("What happend" )
	
	--
	local file,err = io.open("/tmp/hosts/"..localip,'wr')
	
	--if file == nil then
		--
	--	file = io.open("/tmp/hosts/"..localip,"w")
	file:write(""..localip.." "..srcname.." "..name)
	file:close()
	return true
	--end
	--return true
	
end

--read pid from /var/dnsmasq.pid and kill -HUP pid
function reloadDNS()
	local pid = 0
	local file = io.open("/var/run/dnsmasq.pid",'r')
	if file ~= nil then
		for line in file:lines() do
		
			pid = tonumber(line)
			break
		end
		-- now kill 
		os.execute("kill -HUP "..pid)
	end
end



f = SimpleForm("passwd",translate("Register Your Host"),translate("Change Your Host Name"))

mac = f:field(DummyValue,"MAC",translate("MAC"))
ip =  f:field(DummyValue,"IP",translate("IP"))
host = f:field(DummyValue,"Hostname",translate("Hostname"))
new_name = f:field(Value,"new_name",translate("Newname"))
mac.default = "hehe"
ip.defalut = "ip"
host.default = "hostname"

mac.rmempty = false
ip.rmempty = false
host.rmempty = false
local file,err = io.open("/tmp/dhcp.leases","r")
if file == nil then
	host.default = "nil".."  "..err
	return f
end

for line in file:lines() do
	local list = string.split(line,' ')
	tmp_ip = list[3]
	new_name.default = ""..type(tmp_ip)
	if luci.http.getenv("REMOTE_ADDR") == tmp_ip then

	    mac.default = list[2]
	    ip.default = list[3]
	    host.default = list[4]
	end
end

--data store new_name,and the input string
function f.handle(self,state,data)
	if state == FORM_VALID then 
		-- to check is there a same name
		if not isIllegal(mac.default,ip.default,host.default,data.new_name) then
			new_name.default = data.new_name
			f.errmessage = translate(data.new_name)--translate("Error Name: Empty or Duplicate")
			return true
		end
		f.message = translate("Name changed OK! Now is <h1>"..data.new_name.."</h1>")
		reloadDNS()
	end
	--tex = tex..host.default
	--tex = tex.."\t".."hello world"
	--luci.http.write(tex)
	return true

end

return f

