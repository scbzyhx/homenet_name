module("luci.controller.reg.index", package.seeall)
string.split = function(s,p)
	local rt = {}
	string.gsub(s,'[^'..p..']+',function(w) table.insert(rt,w) end);
	return rt
end

function index()
	local root = node()
	if not root.lock then
	    root.target = alias("admin")
	    root.index = false
	end
	
	entry({"about"},template("about"))
	local page = entry({"reg"},form("reg"),_("Register a device"),1)
	--local page = entry({"reg"},call("testAction"),_("Register a device"),1)
	-- page.sysauth = "root"
	-- page.sysauth_authenticator = "htmlauth"
	-- page.index = true
	

end


function testAction()
	luci.http.prepare_content("text/plain")
	local text = "HaHa, I am here...\n"
	--local h = luci.http.getenv()

	--for k,v in pairs(h) do
	--    text = text.."\t"..k.."\t"..v.."\n"
	--end
	local remoteip = text..luci.http.getenv("REMOTE_ADDR")
	
	
	luci.http.write(text)
end
