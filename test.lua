-- FastCGI Test Program

local fcgi = require 'fcgi'

-- Create a local socket, make sure the FastCGI enabled webserver
-- has r/w access to it, might need a chmod call here

local socket = fcgi.openSocket('/var/run/.s.luafcgi', 4)

local request = fcgi.initRequest(socket)

-- Accept requests in a loop
while request:accept() == 0 do
	print('Incoming request')

	local data = request:parse()

	print('request parsed', type(data))

	for k, v in pairs(data) do
		print('decoded', k .. ':')
		if type(v) == 'table' then
			-- uploaded files have a __isFile boolean set to true
			if v.__isFile == true then
				for a, b in pairs(v) do
					print(a)
					if a ~= 'filedata' then
						print(b)
					end
				end
				local f = io.open(v.filename, 'w')
				f:write(v.filedata)
				f:close()
			else
				-- not a file, must be a selection multiple
				for a, b in pairs(v) do
					print(a, b)
				end
			end
		else
			print(string.format('%s', v))
		end
	end

	-- Send some HTML to the client
	request:putStr('Content-Type: text/html\n')

	request:putStr('\n')
	request:putStr('<h1>Hello from Lua</h1>\n')
	request:putStr([[
	<form method="POST" enctype="multipart/form-data" action="/cgi/abc">
	<input type="file" name="imagefile" value="">
	<input type="text" name="name">
	<input type="text" name="id">
	<select multiple name="selection">
		<option value="a">AAA</option>
		<option value="b">BBB</option>
		<option value="c">CCC</option>
	</select>
	<input type="submit" value="OK">
	</form>
	]])

	-- finish this request
	request:finish()
end
print('ending')
