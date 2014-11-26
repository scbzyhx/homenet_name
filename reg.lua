require("os")
require("luci.model.db")
require("nixio")   -- log module of openwrt

-- split a string with specific string
string.split = function(s,p)
	local rt = {}
	string.gsub(s,'[^'..p..']+',function(w) table.insert(rt,w) end)
	return rt
end

-- Is there already specific name
function isIllegal(mac,localip,srcname,name)
	if name == nil then
		return false
	end
	
	-- lookup database
	name = string.lower(name)
	local result,_ = insertRecord(mac,srcname,name,1)
	if result == false then  return false end
	local file,err = io.open("/tmp/hosts/"..localip,'wr')
	
	file:write(""..localip.." "..srcname.." "..name)
	file:close()
	return true
	
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
mac.default = nil
ip.defalut = nil
host.default = nil
new_name.default = nil

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
	--new_name.default = ""..type(tmp_ip)
	ip.default = luci.http.getenv("REMOTE_ADDR")
	f.errmessage = translate("Static IP doesn't support to change hostname")
	
	if luci.http.getenv("REMOTE_ADDR") == tmp_ip then
	    --nixio.openlog()
	    --nixio.syslog("alert","hehe in tmpip")
	    --nixio.closelog()
	    mac.default = list[2]
	    host.default = list[4]
	    new_name.default = getPresentName(list[2])
	    f.errmessage = nil
	    break
	--else
	--	f.errmessage = translate("Static IP doesn't support to change hostname")
	end
end

--data store new_name,and the input string
function f.handle(self,state,data)
	if state == FORM_VALID then 
		-- to check is there a same name
		if not isIllegal(mac.default,ip.default,host.default,data.new_name) then
			new_name.default = string.lower(data.new_name)
			f.errmessage = translate("Error Name: Empty or Duplicate")
			return true
		end
		new_name.default = string.lower(data.new_name)
		f.message = translate("Name changed OK! Now is <h1>"..string.lower(data.new_name).."</h1>")
		reloadDNS()
	end
	--tex = tex..host.default
	--tex = tex.."\t".."hello world"
	--luci.http.write(tex)
	return true

end

return f

