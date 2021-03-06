function create(args)
	
	local button = {}
	
	
	button.x = tonumber(args.x) or 0
	button.y = tonumber(args.y) or 0
	pcall(function () button.func = loadstring(args.func) end)
	button.locked = args.locked or false
	button.singleClick = args.singleClick or false
	button.spriteFile = args.sprite
	button.hoverSpriteFile = args.hoverSprite
	button.showingHover = false
	button.dynamic = false
	button.interactive = true
	button.name = args.name
	button.type = "button"
	button.text = args.text or ""
	button.textColor = args.color or colors.black
	button.backgroundColor = args.background or colors.white
	button.hoverTextColor = args.hoverColor or colors.white
	button.hoverBackgroundColor = args.hoverBackground or colors.black
	button.sticky = args.sticky or false
	
	local sprite_args = {}
	sprite_args["x"] = button.x
	sprite_args["y"] = button.y
	sprite_args["src"] = button.spriteFile
	button.sprite = sprite.create(sprite_args)
	button.height = button.sprite.height
	
	-- draws the button
	function button:draw(x_offset, y_offset)
		x_offset = x_offset or 0
		y_offset = y_offset or 0
		
		if button.sticky then 
			x_offset = 0
			y_offset = 0 
		end
		
		button.sprite:draw(x_offset, y_offset)
		
		local midpoint = math.floor(button.sprite.height / 2)
		local saved_1 = term.getTextColor()
		local saved_2 = term.getBackgroundColor()
		term.setCursorPos(math.floor(button.x + (button.sprite.width - string.len(button.text))/2), button.y+midpoint-y_offset)
		
		if button.showingHover then
			term.setTextColor(button.hoverTextColor)
			term.setBackgroundColor(button.hoverBackgroundColor)
		else
			term.setTextColor(button.textColor)
			term.setBackgroundColor(button.backgroundColor)
		end
		
		io.write(button.text)
		term.setTextColor(saved_1)
		term.setBackgroundColor(saved_2)
	end
	
	-- implements functionality of button
	function button:update(obj_args)
		if button.sticky then 
			obj_args["x_offset"] = 0
			obj_args["y_offset"] = 0 
		end
		
		obj_args["x_offset"] = obj_args["x_offset"] or 0
		obj_args["y_offset"] = obj_args["y_offset"] or 0
		
		
		
		if not obj_args["mouse_x"] or not obj_args["mouse_y"] or button.locked then return false end -- check that given action is mouse (and button is not locked)
		if button:check_hover(obj_args["mouse_x"], obj_args["mouse_y"], obj_args["y_offset"]) then	-- if the mouse is hovering the button
			if obj_args["event"] == "mouse_up" and button.showingHover then -- if the mouse is clicking the button	
				button.sprite:setImage(button.spriteFile)
				button.showingHover = false
				button:draw(obj_args["x_offset"], obj_args["y_offset"])
				return button:click() -- button has been clicked
			elseif not button.showingHover and obj_args["event"] == "mouse_click" then -- if the mouse is hovering the button
				button.sprite:setImage(button.hoverSpriteFile)
				button.showingHover = true
				button:draw(obj_args["x_offset"], obj_args["y_offset"])
				return false -- button is being hovered
			end
		elseif button.showingHover then
			button.sprite:setImage(button.spriteFile)
			button:draw(obj_args["x_offset"], obj_args["y_offset"])
			button.showingHover = false
		end
		return false -- not interacted with
	end
	
	
	
	-- checks if a set of coordinates overlaps the buttons sprite
	function button:check_hover(inX, inY, y_offset)
		if (button.y+button.sprite.height-y_offset) >= 0 and (button.y-y_offset) <= 19 then
			term.setCursorPos(0,0)
			
			--[[
			print("testing if:")
			term.clearLine()
			print("inX: " .. inX .. " > button.x: " .. button.x) 
			term.clearLine()
			print("inX: " .. inX .. " < button.sprite.width+button.x: " .. button.sprite.width+button.x-1)
			term.clearLine()
			print("inY: " .. inY .. " > button.y: " .. button.y-y_offset)
			term.clearLine()
			print("inY: " .. inY .. " > button.sprite.height+button.y-y_offset: " .. button.sprite.height+button.y-y_offset-1)
			
			term.clearLine()
			print("button at: X=", button.x, "-", (button.x+button.sprite.width))
			term.clearLine()
			print("\t\tY=", (button.y-y_offset), "-", (button.y-y_offset+button.sprite.height))
			]]--
			
			if button.sticky then y_offset = 0 end
			
			if 
			inX >= button.x and
			inX <= button.sprite.width+button.x-1 and
			inY >= button.y - y_offset and
			inY <= button.sprite.height+button.y-y_offset-1
			then
				return true
			else
				return false
			end
			
		end
	end
	
	
	-- applies the buttons function if not locked
	function button:click()
		if button.locked == false then 
			if button.singleClick then button.locked = true end
			if button.func ~= nil then button.func() end
			return true
		end
		return false
	end
	
	function button:corrections()
		if button.sticky == "true" or not type(button.sticky) == "boolean" then
			button.sticky = true
		else
			button.sticky = false
		end
	end
	
	--[[
	if sharedFunctions then
		sharedFunctions.corrections(button)
	end
	]]--
	return button
end