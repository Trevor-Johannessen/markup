args = {...}
objects = {} -- storage for all objects
screen_width, screen_height = term.getSize() -- dimensions of screen
x_offset = 0
y_offset = 0
end_of_page = 0
background = colors.black


-- open file and lex lines into tables

function main()
	-- initalize to load apis
	initalize()
	
	-- open file and get line iterator
	local text = get_file_iterator()

	-- parse lines to create objects and insert them into the objects list
	line_num = 1
	for str in text do
		local new_obj = parse(str, line_num)
		if new_obj ~= -1 then
			if new_obj.y+new_obj.height > end_of_page then end_of_page = new_obj.y+new_obj.height end -- adjust total page height
			table.insert(objects, new_obj)
			line_num = line_num + 1
		end
	end
	
	
	redraw()
	interaction_loop()
end


function get_file_iterator()
	if not fs.exists(args[1]) then error("file not found") end -- if file doesn't exist, error
	return io.lines(args[1])
end


function parse(text, line_num)
	-- find what object type line is
	local colon_pos = string.find(text, ":") -- position of colon used to mark a command
	if not colon_pos then return -1 end -- if a colon is missing then ignore
	local object_type = string.sub(text, 1, colon_pos-1)
	text = string.sub(text, colon_pos+1)
	
	
	-- create arguments in table
	local args = {}
	text = trim_input(text)	
	
	text = string.gmatch(text, "([^,]*),*")
	
	-- turn arguments into parameters for the objects
	for term in text do
			--print("term = ", term)
			local equals_pos = string.find(term, "=")
			args[string.sub(term, 0, equals_pos-1)] = string.sub(term, equals_pos+1) -- args[var_name] = var_value
	end
	
	local obj = loadstring("return " .. object_type .. ".create")
	
	
	return obj()(args)
end


-- removes spaces from arguments (ignores spaces and removes commas inside quotes)
function trim_input(text)
	-- I want to find a way to do this with regex
	
	local in_quotes = false
	
	for i=0, string.len(text) do
		if string.sub(text, i, i) == "\"" and string.sub(text, i-1, i-1) ~= "\\" then in_quotes = not in_quotes -- check if in quotes
		elseif string.sub(text, i, i) == " " and not in_quotes then text = string.sub(text, 0, i-1) .. string.sub(text, i+1) -- remove spaces
		elseif string.sub(text, i, i) == "," and in_quotes then text = string.sub(text, 0, i-1) .. string.char(9) .. string.sub(text, i+1) end -- remove commas
	end
	
	return text
end


function initalize()
	if not fs.exists("/markup_apis/") then error("apis folder does not exist, try reinstalling") end
	
	apis = fs.list("/markup_apis/")
	
	for i=1, table.getn(apis) do
		--print("apis[".. i .. "] = ", apis[i])
		if not fs.isDir(apis[i]) then
			os.loadAPI("/markup_apis/" .. apis[i])
		end
	end
end


 -- INTERPRETING FUNCTIONS
 
function interaction_loop()
	local tick = 1
	local event, event_id, x, y
	local obj_args = {}
	
	obj_args["x_offset"] = x_offset
	obj_args["y_offset"] = y_offset
	obj_args["screen_height"] = screen_height
	
	
	while true do
		obj_args["tick"] = tick
		
		-- update all dynamic objects
		for index, data in ipairs(objects) do
			if data.dynamic then data:update(obj_args) end
		end
		
		-- update interactive elements
		local timer = os.startTimer(0.05)
		while true do
			event, event_id, x, y = os.pullEvent()

			obj_args["event"] = event
			obj_args["event_id"] = event_id
			obj_args["mouse_x"] = x
			obj_args["mouse_y"] = y
			
			-- give input to all objects that request it
			for index, data in ipairs(objects) do
				if data.interactive then data:update(obj_args) end
			end
			
			-- handels scrolling of page
			if event == "mouse_scroll" then
				if event_id == -1 and y_offset+screen_height < end_of_page-1 then -- scroll up
					y_offset = y_offset + 1
					redraw()
				elseif event_id == 1 and y_offset >= 1 then -- scroll down
					y_offset = y_offset - 1
					redraw() -- we call redraw twice because it messes with dynamic objects when scrolling at top or bottom of page
				end
				obj_args["y_offset"] = y_offset
				--message("y_offset = " ..  y_offset .. "\t" .. "end_page = " .. end_of_page)
			end
			
			if event == "timer" then break end
		end
		
		tick = tick + 1
	end
end


function redraw()
	
	fill_screen()
	
	for index, data in ipairs(objects) do
		data:draw(x_offset, y_offset, screen_height)
	end
end


function fill_screen()
	local x, y = term.getCursorPos()
	local keep_background_color = term.getBackgroundColor()
	term.setBackgroundColor(background)
	term.setCursorPos(1,1)
	for i = 1, screen_height do
		print(string.rep(" ", screen_width))
	end
	term.setCursorPos(x, y)
	term.setBackgroundColor(keep_background_color)
end


-- HELPER FUNCTIONS
function printarr(arr, substr)
   for i in pairs(arr) do
      print("arr[" .. i .. "] = ", arr[i])
	  if substr then printarr(arr[i]) end
   end
end


function message(message)
	local orgx, orgy = term.getCursorPos()
	term.setCursorPos(1, screen_height)
	term.clearLine()
	io.write(message)
	term.setCursorPos(orgx, orgy)
end

main()