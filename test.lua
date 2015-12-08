-- FastCGI Test Program

local fcgi = require 'fcgi'

-- The unix module is needed for a Unix dup2 function, replace it with
-- luaposix if you want.

local unix = require 'unix'

-- Create a local socket, make sure the FastCGI enable webserver
-- has r/w access to it, might need a chmod call here

socket = fcgi.openSocket('/tmp/.s.luafcgi', 4)

-- Now dup2 the socket to filedes 0, stdin, so the FastCGI library can
-- use it (need to find a better way to specify the socket, though...)
unix.dup2(socket, 0)

local sessions = {}
local sessionTimeout = 0

function timeoutSessions()
	local now = os.time()

	for k, v in pairs(sessions) do
		if now - v.access >= sessionTimeout then
			print('timeout session ' .. k)
			sessions[k] = nil
		end
	end
end

-- Accept requests in a loop
while fcgi.accept() == 0 do

	if sessionTimeout > 0 then
		timeoutSessions()
	end

	print('Incoming ' .. fcgi.getParam('REQUEST_METHOD') .. ' request')
	len = fcgi.getParam('HTTP_CONTENT_LENGTH')
	if len ~= nil then
		print('HTTP_CONTENT_LENGTH: ' .. len)
		content = fcgi.getStr(tonumber(len))
		print('Content:\n' .. content)
	end
	print('URI: ' .. fcgi.getParam('REQUEST_URI'))

	local session = {}
	local cookie = fcgi.getParam('HTTP_COOKIE')
	if cookie ~= nil then
		print('Cookie: ' .. cookie)
		if string.find(cookie, 'authid=') == 1 then
			local authid = string.sub(cookie, 8)
			print('authid: ' .. authid)
			session = sessions[authid]
			if session == nil then
				print('no session found')
				cookie = nil
			else
				print('session found')
				session.access = os.time()
				print(string.format('C: %d, A: %d',
					session.created, session.access))
			end
		end
	end

	-- Send some HTML to the client
	fcgi.putStr('Content-Type: text/html\n')

	if cookie == nil then
		local a = unix.arc4random()
		local b = unix.arc4random()
		local c = unix.arc4random()
		local d = unix.arc4random()

		local authid = string.format('%08x%08x%08x%08x', a, b, c, d)

		sessions[authid] = {
			created = os.time(),
			access = os.time()
		}

		print('Set cookie')
		fcgi.putStr('Set-Cookie: authid=' .. authid .. ';\n')
		fcgi.putStr('\tPath=/fcgi.html\n')
	end
	fcgi.putStr('\n')
	fcgi.putStr('<h1>Hello from Lua</h1>\n')
	fcgi.putStr([[
	<form method="POST" action="/fcgi.html">
	<input type="text" name="name">
	<input type="text" name="id">
	<input type="submit" value="OK">
	</form>
	]])

	-- finish this request
	fcgi.finish()
end
print('ending')
