------------------------------------------------------------------------------
-- Rotary HTTP Web Services
--
-- Sergio Marcelo Couto Figueiredo <smarcelo_br@yahoo.com.br>
------------------------------------------------------------------------------
local svc
do
	local MEDIA_TYPES = {}
	MEDIA_TYPES["js"] = "application/javascript"
	MEDIA_TYPES["json"] = "application/json"
	MEDIA_TYPES["css"] = "application/javascript"
	MEDIA_TYPES["jpeg"] = "image/jpeg"
	MEDIA_TYPES["ico"] = "image/x-icon"
	MEDIA_TYPES["txt"] = "text/plain"
	MEDIA_TYPES["css"] = "text/css"
	MEDIA_TYPES["html"] = "text/html"

	-- mapa com os web resources e seus handlers
	local webResources = {}
	webResources["/"] = function (req, res)
		return {
			onheader = function(self, name, value)
				print("+H", name, value)
			end,
			ondata = function(self, chunk)
				print("+B", chunk and #chunk, node.heap())
				if not chunk then
					print("H")
					res:send(nil, 200)
					res:send_header("Content", "text/plain")
					res:send_header("Connection", "close")
					res:send("Home\n")
					res:finish()
					print("f")
				end
			end
		}
	end

	webResources["/teste"] = function (req, res)
		return {
			onheader = function(self, name, value)
			end,
			ondata = function(self, chunk)
				if not chunk then
					print("T:")
					res:send(nil, 200)
					res:send_header("Content", "text/plain")
					res:send_header("Connection", "close")
					res:send("Teste\n")
					res:finish()
					print("f")
				end
			end
		}
	end
	
	local fileController = function  (req, res)
	
		local httpStatus = 200 -- ok, se algo não der errado...
		-- Verifica se tem um arquivo com este nome
		local filename,ok = string.gsub(req.url, "/?(%w+%.%w+)", "%1", 1)
		if (ok and file.exists(filename)) then 
			local ext = string.gsub(filename, "%w+%.(%w+)", "%1")
			-- envia o arquivo encontrado, caso ele termine com as extensões válidas.
			local mediaType = MEDIA_TYPES[ext]
			if (not mediaType) then
				httpStatus = 403 -- forbidden
			end
		else 
			httpStatus = 404 -- not found
		end
				
		return {
			onheader = function(self, name, value)
			end,
			ondata = function(self, chunk)
				if not chunk then
					res:send(nil, httpStatus)
					res:send_header("Content", mediaType)
					res:send_header("Connection", "close")
					
					local fd = file.open(filename, "r")
					if fd then
						local fileChunk = fd:read(50)
						while (fileChunk) do
							res:send(fileChunk)
							fileChunk = fd:read(50)
						end
						fd:close(); fd = nil
					end
					res:finish()
				end
			end				
			}, httpStatus
	end


	local init = function ()
		-- configura o http server
		httpserver = require("httpserver")
		httpserver.createServer(10041, function( req, res ) 

			print("+R", req.method, req.url, node.heap())

			local resource = '/'
			if (#req.url>0) then 
				resource = req.url
			end

			local webResource = webResources[resource];
			local httpStatus = 200
			if (not webResource) then
				webResource, httpStatus = fileController
			end 
			
			if (httpStatus ~= 200) then
				-- retorna o erro.
				res:send(nil, httpStatus) 
				res:send_header("Content", "text/plain")
				res:send_header("Connection", "close")
				res:send("Fail ", resource, " status: ", httpStatus, "\n")
				res:finish()
			else
				local webController = webResource(req, res)
				req.onheader = webController.onheader
				req.ondata = webController.ondata
			end
		end)
		
	end
	
	svc = {
		init = init
	}
end
return svc
