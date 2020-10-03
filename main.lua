function love.load()
	WIDTH = 1280
	HEIGHT = 720
	love.window.setMode(WIDTH, HEIGHT)
	love.window.setTitle("for egg in basket")

	BASE_FONTSIZE = 22
	BASE_FONT = love.graphics.newFont("fonts/VCR_OSD_MONO_1.001.ttf", BASE_FONTSIZE)
	TITLE_FONT = love.graphics.newFont("fonts/VCR_OSD_MONO_1.001.ttf", BASE_FONTSIZE * 3)
	
	EGG_TYPES = {
		{col="blue", striped=false, sprite_name="egg_blue_dotty"},
		{col="green", striped=false, sprite_name="egg_green_dotty"},
		{col="red", striped=false, sprite_name="egg_red_dotty"},
		{col="blue", striped=true, sprite_name="egg_blue_striped"},
		{col="green", striped=true, sprite_name="egg_green_striped"},
		{col="red", striped=true, sprite_name="egg_red_striped"},
		{col="gold", striped=false, sprite_name="egg_golden"},
	}
	for i, eggtype in ipairs(EGG_TYPES) do
		eggtype["sprite"] = love.graphics.newImage(
			"graphics/" .. eggtype["sprite_name"] .. ".png"
		)
	end
	EGG_SPRITE_BOT = {x=62, y=110}
	
	EGG_HITBOX_IMGDATA = love.image.newImageData("graphics/egg_hitbox.png")
	EGG_HITBOX_WIDTH = EGG_HITBOX_IMGDATA:getWidth()
	EGG_HITBOX_HEIGHT = EGG_HITBOX_IMGDATA:getHeight()
	EGG_HITBOX = {}
	for y = 1, EGG_HITBOX_HEIGHT do
		EGG_HITBOX[y] = {}
		for x = 1, EGG_HITBOX_WIDTH do
			r, g, b, a = EGG_HITBOX_IMGDATA:getPixel(x - 1, y - 1)
			EGG_HITBOX[y][x] = a > 0
		end
	end
	
	TRASH_CAN = love.graphics.newImage("graphics/trash_can.png")
	TRASH_SPRITE_MID = {x=64, y=66}
	
	CURSOR = love.graphics.newImage("graphics/cursor.png")
	love.mouse.setVisible(false)
	
	TASK_TYPES = {
		click_egg={
			str="click the egg!",
		},
		click_next_egg={
			str="click the next egg after the current one!",
		},
		click_any_xcol={
			str="click any %s egg!",
			fmt_col=true,
		},
		click_n_eggs={
			str="click any %d different eggs!",
			fmt_n=true,
		},
	}
	STATUS = {not_done=0, current=1, done=2}
	TASK_STATUS_COLOURS = {
		[STATUS.not_done]={1, 1, 1},
		[STATUS.current]={0.5, 0.5, 1},
		[STATUS.done]={0.5, 1, 0.8},
	}
	
	NEXT_EGG_TIME = 1
	CONVEYOR_SPEED = 120
	GRAVITY = 30
	EGG_Y = 560
	EGG_MAXFALL = 100
	
	started = false
	
	-- for debug, skip splash screen:
	reset_game()
end

function reset_task_progress()
	for i, task in ipairs(tasks) do
		task.status = STATUS.not_done
		if not (task.progress == nil) then
			task.progress = 0
		end
	end
	tasks[1].status = STATUS.current
	current_task_idx = 1
	complete_current_task_if_free()
end

function reset_game()
	tasks = {
		--{tasktype=TASK_TYPES.click_any_xcol, col="green"},
		--{tasktype=TASK_TYPES.click_any_xcol, col="red"},
		{tasktype=TASK_TYPES.click_n_eggs, n=3},
		{tasktype=TASK_TYPES.click_egg},
		{tasktype=TASK_TYPES.click_next_egg},
		{tasktype=TASK_TYPES.click_any_xcol, col="blue"},
	}
	
	spawned_eggs = {}
	t = 0
	eggs_lost = 0
	next_egg_timer = NEXT_EGG_TIME
	
	basket_eggs = {}
	for i = 1, 5 do
		basket_eggs[#basket_eggs + 1] = EGG_TYPES[i]
	end
	
	reset_task_progress() -- must call after defining eggs :)
	started = true
end

function draw_cursor()
	mouse_x, mouse_y = love.mouse.getPosition()
	love.graphics.draw(CURSOR, mouse_x, mouse_y)
end

function love.draw()
	if not started then
		-- splash screen
		love.graphics.setColor(1, 1, 1)
		love.graphics.setFont(TITLE_FONT)
		love.graphics.printf("for egg in basket", 0, 240, WIDTH, "center")
		love.graphics.setFont(BASE_FONT)
		splash_lines = {
			"you are tasked with quality assurance for",
			"an premium egg manufacturer. for each egg, please",
			"carefully carry out all of the required assessments.",
			"if an egg's tasks are not completed, unfortunately",
			"that egg must be disposed of. click to start.",
			"good luck!",
		}
		draw_y = 320
		for i, line in ipairs(splash_lines) do
			love.graphics.printf(line, 0, draw_y, WIDTH, "center")
			draw_y = draw_y + BASE_FONTSIZE * 1.2
		end
		draw_cursor()
		return
	end
	
	love.graphics.setBackgroundColor(0.25, 0.25, 0.3)

	love.graphics.setFont(BASE_FONT)
	-- tasks
	love.graphics.setColor(1, 1, 1)
	text_d_x = 40
	text_d_y = 10
	love.graphics.print("for egg in basket:", text_d_x, text_d_y)
	text_d_x = text_d_x + 50 -- tab in
	for i, task in ipairs(tasks) do
		love.graphics.setColor(TASK_STATUS_COLOURS[task.status])
		text_d_y = text_d_y + BASE_FONTSIZE * 1.2
		task_str = task.tasktype.str
		if not (task.tasktype.fmt_col == nil) then
			task_str = task_str:format(task.col)
		end
		if not (task.tasktype.fmt_n == nil) then
			task_str = task_str:format(task.n)
			if not (task.progress == nil) then
				task_str = task_str .. " (" .. task.progress .. "/" .. task.n .. ")"
			end
		end
		love.graphics.print(task_str, text_d_x, text_d_y)
		if task.status == STATUS.current and math.floor(t * 2) % 2 == 0 then
			love.graphics.print(">", text_d_x - 25, text_d_y)
		end
	end
	
	-- placeholder conveyor:
	love.graphics.setColor(0.5, 0.5, 0.5)
	love.graphics.rectangle("fill", 200, EGG_Y, 900, 30, 15, 15)
	-- sprites
	love.graphics.setColor(1, 1, 1)
	for i, egg in ipairs(spawned_eggs) do
		love.graphics.draw(
			egg.eggtype.sprite,
			egg.x - EGG_SPRITE_BOT.x,
			egg.y - EGG_SPRITE_BOT.y
		)
	end
	love.graphics.draw(
		TRASH_CAN,
		140 - TRASH_SPRITE_MID.x,
		EGG_Y + EGG_MAXFALL - TRASH_SPRITE_MID.y
	)
	
	-- status gui
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("eggs left in basket: " .. #basket_eggs, 800, 10)
	love.graphics.print("eggs lost: " .. eggs_lost, 800, 10 + BASE_FONTSIZE*1.2)
	
	-- mouse
	draw_cursor()
end

function love.update(dt)
	if not started then
		return
	end
	
	t = t + dt
	next_egg_timer = next_egg_timer - dt
	if next_egg_timer < 0 then
		if #basket_eggs > 0 then
			spawned_eggs[#spawned_eggs + 1] = {
				eggtype=basket_eggs[1],
				x=1000,
				y=EGG_Y,
				vdown=0,
			}
			table.remove(basket_eggs, 1)
			next_egg_timer = NEXT_EGG_TIME
		end
	end
	for i, egg in ipairs(spawned_eggs) do
		egg.x = egg.x - CONVEYOR_SPEED * dt
		if egg.x < 200 then
			egg.vdown = egg.vdown + GRAVITY * dt
			egg.y = egg.y + egg.vdown
			if egg.y > EGG_Y + EGG_MAXFALL then
				eggs_lost = eggs_lost + 1
				table.remove(spawned_eggs, i)
			end
		end
	end
end

function complete_current_task_if_free()
	-- call this when we reset tasks or complete_task()s
	-- some tasks we want to complete for free:
	current_task = tasks[current_task_idx]
	if current_task.tasktype == TASK_TYPES.click_next_egg then
		if #spawned_eggs + #basket_eggs < 2 then
			complete_task()
		end
	elseif current_task.tasktype == TASK_TYPES.click_any_xcol then
		exists = false
		for i, egg in ipairs(spawned_eggs) do
			if egg.eggtype.col == current_task.col then
				exists = true
			end
		end
		if not exists then
			complete_task()
		end
	elseif current_task.tasktype == TASK_TYPES.click_n_eggs then
		total_eggs = #spawned_eggs + #basket_eggs
		if total_eggs < current_task.n then
			current_task.progress = current_task.n - total_eggs
		end
	end
end

function complete_task()
	tasks[current_task_idx].status = STATUS.done
	current_task_idx = current_task_idx + 1
	if current_task_idx <= #tasks then
		tasks[current_task_idx].status = STATUS.current
		complete_current_task_if_free()
		return
	end
	-- we finished an egg!
	table.remove(spawned_eggs, 1)
	reset_task_progress()
	if #spawned_eggs == 0 and #basket_eggs == 0 then
		started = false -- temp while we don't have more tasks etc!
	end
end


function is_in_egg(egg, x, y)
	rel = {x=x - (egg.x - EGG_SPRITE_BOT.x), y=y- (egg.y - EGG_SPRITE_BOT.y)}
	if (
		rel.x < 0 or rel.x > EGG_HITBOX_WIDTH
		or rel.y < 0 or rel.y > EGG_HITBOX_HEIGHT
	) then
		return false
	end
	return EGG_HITBOX[math.floor(rel.y)][math.floor(rel.x)]
end


function love.mousepressed(x, y, button, istouch, presses)
	if not started then
		reset_game()
	end
	-- inactive
	if #spawned_eggs == 0 then
		return
	end
	
	-- see if we had a "clicking on egg" task!
	current_task = tasks[current_task_idx]
	if current_task.tasktype == TASK_TYPES.click_egg then
		if is_in_egg(spawned_eggs[1], x, y) then
			complete_task()
		end
	elseif current_task.tasktype == TASK_TYPES.click_next_egg then
		if #spawned_eggs < 2 then
			return
		end
		if is_in_egg(spawned_eggs[2], x, y)	then
			complete_task()
		end
	elseif current_task.tasktype == TASK_TYPES.click_any_xcol then
		for i, egg in ipairs(spawned_eggs) do
			if egg.eggtype.col == current_task.col and is_in_egg(egg, x, y) then
				complete_task()
			end
		end
	elseif current_task.tasktype == TASK_TYPES.click_n_eggs then
		if current_task.hit_idxs == nil then
			current_task.hit_idxs = {}
		end
		for i, egg in ipairs(spawned_eggs) do
			if is_in_egg(egg, x, y) then
				current_task.hit_idxs[i] = true
			end
		end
		current_task.progress = #current_task.hit_idxs
		if current_task.progress >= current_task.n then
			complete_task()
		end
	end
end


function love.keypressed(key, scancode, isrepeat)
	-- esc keys isn't going through, maybe being passed to something else
	-- on my PC at the moment?
	if key == "escape" then
		love.event.quit()
	end
end
