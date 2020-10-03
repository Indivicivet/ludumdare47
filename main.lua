function love.load()
	WIDTH = 1280
	HEIGHT = 720
	love.window.setMode(WIDTH, HEIGHT)
	love.window.setTitle("for egg in basket")

	BASE_FONTSIZE = 24
	BASE_FONT = love.graphics.newFont("fonts/VCR_OSD_MONO_1.001.ttf", BASE_FONTSIZE)
	BIG_FONT = love.graphics.newFont("fonts/VCR_OSD_MONO_1.001.ttf", BASE_FONTSIZE * 2)
	TITLE_FONT = love.graphics.newFont("fonts/VCR_OSD_MONO_1.001.ttf", BASE_FONTSIZE * 3)
	HUGE_FONT = love.graphics.newFont("fonts/VCR_OSD_MONO_1.001.ttf", BASE_FONTSIZE * 4)
	SMALL_FONT = love.graphics.newFont("fonts/VCR_OSD_MONO_1.001.ttf", BASE_FONTSIZE * 0.7)
	
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
	
	BACKGROUND = love.graphics.newImage("graphics/background.png")
	
	-- probs not using tick_behind
	EGG_TICK_BEHIND = love.graphics.newImage("graphics/egg_tick_behind.png")
	EGG_GREY_CENTER = love.graphics.newImage("graphics/egg_grey_center.png")
	
	TRASH_CAN = love.graphics.newImage("graphics/trash_can.png")
	TRASH_SPRITE_MID = {x=64, y=66}

	BASKET_FRONT = love.graphics.newImage("graphics/basket_front.png")
	BASKET_BACK = love.graphics.newImage("graphics/basket_back.png")
	BASKET_TOP_MID = {x=63, y=40}
	
	CONVEYOR_FRAMES = {}
	for i = 0, 9 do
		CONVEYOR_FRAMES[i] = love.graphics.newImage("graphics/conveyor" .. i .. ".png")
	end
	
	CURSOR = love.graphics.newImage("graphics/cursor.png")
	love.mouse.setVisible(false)
	
	ARROW_CHARS = {right="→", up="↑", down="↓", left="←"}
	WASD = {right="d", up="w", down="s", left="a"}
	
	TASK_TYPES = {
		click_egg={str="click the egg!"},
		click_next_egg={str="click the next egg after the current one!"},
		click_any_xcol={
			str="click any %s egg!",
			fmt_col=true,
		},
		click_any_striped={str="click any striped egg!"},
		click_n_eggs={
			str="click any %d eggs!",
			fmt_n=true,
		},
		keyseq={
			str="press the key sequence! %s",
			fmt_arrowseq=true,
		},
		mash_keys={
			str="mash any keys!",
			-- could fmt_n = true if desired
		},
	}
	STATUS = {not_done=0, current=1, done=2}
	TASK_STATUS_COLOURS = {
		[STATUS.not_done]={1, 1, 1},
		[STATUS.current]={0.5, 0.5, 1},
		[STATUS.done]={0.5, 1, 0.8},
	}
	
	NEXT_EGG_TIME = 1.3
	CONVEYOR_SPEED = 75
	GRAVITY = 10
	EGG_Y = 560
	EGG_MAXFALL = 100
	
	click_highlights = {}  -- applicable for splash draw_cursor()
	
	started = false
	
	-- for debug, skip splash screen:
	--reset_game()
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
	current_task = tasks[current_task_idx]
	setup_current_task()
end

function new_basket(n)
	bask = {}
	for i = 1, n do
		bask[i] = basket_eggs_set[((i - 1) % #basket_eggs_set) + 1]
	end
	return bask
end

function reset_game()
	task_queue = {
		--{tasktype=TASK_TYPES.click_any_xcol, col="green"},
		--{tasktype=TASK_TYPES.click_any_xcol, col="red"},
		--{tasktype=TASK_TYPES.keyseq, seq={"up", "left", "up", "down"}},
		{tasktype=TASK_TYPES.click_egg},
		{tasktype=TASK_TYPES.click_n_eggs, n=3},
		{tasktype=TASK_TYPES.click_any_striped},
		{tasktype=TASK_TYPES.mash_keys, n=10},
		{tasktype=TASK_TYPES.click_next_egg},
		{tasktype=TASK_TYPES.click_any_xcol, col="blue"},
	}
	
	tasks = {task_queue[1]}
	
	spawned_eggs = {}
	t = 0
	eggs_lost = 0
	eggs_cleared = 0
	loops_cleared = 0
	
	basket_eggs_set = {}
	for i = 1, 5 do
		-- todo: randomize or something
		basket_eggs_set[#basket_eggs_set + 1] = EGG_TYPES[i]
	end
	eggs_per_basket = 2
	basket_eggs = new_basket(eggs_per_basket)
	spawn_egg()  -- sets next_egg_timer
	
	event_msgs = {{str="begin"}}
	
	reset_task_progress() -- must call after defining eggs :)
	started = true
	
	conveyor_moving = true
	conveyor_t = 0
	conveyor_reset_timer = 0
end

function draw_cursor()
	-- used in both splash screen and ingame
	love.graphics.setColor(1, 1, 1, 0.5)
	for i, hl in ipairs(click_highlights) do
		love.graphics.circle("line", hl.x, hl.y, (hl.t or 0) * 60)
	end
	mouse_x, mouse_y = love.mouse.getPosition()
	if love.mouse.isDown(1) then
		mouse_x = mouse_x + 1
		mouse_y = mouse_y + 4
	end
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(CURSOR, mouse_x, mouse_y)
end

function love.draw()
	love.graphics.setBackgroundColor(0.25, 0.25, 0.3)
	
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
		love.graphics.setFont(SMALL_FONT)
		footnote_lines = {
			"you can use WASD for tasks requiring arrow usage.",
			"if not enough eggs are left to complete a task, you will get"
			.. " free progress towards the task so it's possible."
		}
		draw_y = 600
		for i, line in ipairs(footnote_lines) do
			love.graphics.printf(line, 0, draw_y, WIDTH, "center")
			draw_y = draw_y + BASE_FONTSIZE * 1.2 * 0.7
		end
		draw_cursor()
		return
	end
	
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(BACKGROUND)
	
	-- tasks
	love.graphics.setFont(BASE_FONT)
	love.graphics.setColor(1, 1, 1)
	text_d_x = 50
	text_d_y = 40
	love.graphics.print("for egg in basket:", text_d_x, text_d_y)
	text_d_x = text_d_x + 50 -- tab in
	for i, task in ipairs(tasks) do
		love.graphics.setColor(TASK_STATUS_COLOURS[task.status] or {1, 1, 1})
		text_d_y = text_d_y + BASE_FONTSIZE * 1.25
		task_str = task.tasktype.str
		if not (task.tasktype.fmt_col == nil) then
			task_str = task_str:format(task.col)
		end
		if not (task.tasktype.fmt_n == nil) then
			task_str = task_str:format(task.n)
		end
		if not (task.tasktype.fmt_arrowseq == nil) then
			arr_str = ""
			for j, dir in ipairs(task.seq) do
				arr_str = arr_str .. ARROW_CHARS[dir]
			end
			task_str = task_str:format(arr_str)
		end
		if not (task.progress == nil) then
			task_str = task_str .. " (" .. task.progress .. "/" .. task.n .. ")"
		end
		love.graphics.print(task_str, text_d_x, text_d_y)
		if task.status == STATUS.current and math.floor(t * 2) % 2 == 0 then
			love.graphics.print(">", text_d_x - 25, text_d_y)
		end
	end
	
	-- print events
	love.graphics.setFont(HUGE_FONT)
	for i, event_msg in ipairs(event_msgs) do
		if i > 1 and (event_msg.d_y == nil) then
			event_msg.d_y = love.math.random(-30, 30)
		end
		cr, cg, cb = unpack(event_msg.col or {1, 1, 1})
		event_t = event_msg.t or 1
		event_d_y = event_msg.d_y or 0
		love.graphics.setColor(cr, cg, cb, 0.7 * (1 - event_t))
		love.graphics.printf(event_msg.str, 0, 270 + event_d_y + event_t * 10, 1280, "center")
	end
	
	-- sprites
	love.graphics.setColor(1, 1, 1)
	if #spawned_eggs >= 1 then
		egg = spawned_eggs[1]
		love.graphics.setFont(BIG_FONT)
		love.graphics.printf("↓", egg.x - 30, egg.y - 150, 60, "center")
	end
	conv_frame_num = math.floor(conveyor_t * CONVEYOR_SPEED / 4) % #CONVEYOR_FRAMES
	love.graphics.draw(CONVEYOR_FRAMES[conv_frame_num], 200, EGG_Y)
	love.graphics.setFont(BASE_FONT)
	for i, egg in ipairs(spawned_eggs) do
		love.graphics.draw(
			egg.eggtype.sprite,
			egg.x - EGG_SPRITE_BOT.x,
			egg.y - EGG_SPRITE_BOT.y
		)
		if current_task.hit_idxs and current_task.hit_idxs[i] then
			love.graphics.setColor(1, 1, 1, 0.6)
			love.graphics.draw(
				EGG_GREY_CENTER,
				egg.x - EGG_SPRITE_BOT.x,
				egg.y - EGG_SPRITE_BOT.y
			)
			love.graphics.setColor(1, 1, 1, 1)
		end
	end
	love.graphics.draw(
		TRASH_CAN,
		155 - TRASH_SPRITE_MID.x,
		EGG_Y + EGG_MAXFALL - TRASH_SPRITE_MID.y
	)
	basket_x = 1180
	basket_y = EGG_Y - 150
	love.graphics.draw(BASKET_BACK, basket_x - BASKET_TOP_MID.x, basket_y - BASKET_TOP_MID.y)
	love.graphics.setFont(HUGE_FONT)
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(#basket_eggs, basket_x - 50, basket_y - 45, 100, "center")
	love.graphics.draw(BASKET_FRONT, basket_x - BASKET_TOP_MID.x, basket_y - BASKET_TOP_MID.y)
	
	-- status gui
	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(BASE_FONT)
	text_d_y = 150
	love.graphics.print("eggs lost: " .. eggs_lost, 900, text_d_y)
	text_d_y = text_d_y + BASE_FONTSIZE * 1.25
	love.graphics.print("eggs cleared: " .. eggs_cleared, 900, text_d_y)
	text_d_y = text_d_y + BASE_FONTSIZE * 1.25
	love.graphics.print("loops cleared: " .. loops_cleared, 900, text_d_y)
	
	-- mouse
	draw_cursor()
end

function spawn_egg()
	-- used if egg timer runs out or if clear all eggs
	next_egg_timer = NEXT_EGG_TIME * (1 + love.math.randomNormal(0.1, 0))
	if not conveyor_moving then
		return
	end
	if #basket_eggs > 0 then
		spawned_eggs[#spawned_eggs + 1] = {
			eggtype=basket_eggs[1],
			x=1000,
			y=EGG_Y,
			vdown=0,
		}
		table.remove(basket_eggs, 1)
	end
end

function love.update(dt)
	if not started then
		return
	end
	
	t = t + dt
	if conveyor_moving then
		conveyor_t = conveyor_t + dt
	end
	
	next_egg_timer = next_egg_timer - dt
	if next_egg_timer < 0 then
		spawn_egg()
	end
	
	for i, event_msg in ipairs(event_msgs) do
		if event_msg.t == nil then
			event_msg.t = 0
		end
		event_msg.t = event_msg.t + dt
		if event_msg.t > 1 then
			table.remove(event_msgs, i)
		end
	end
	
	for i, click in ipairs(click_highlights) do
		click.t = click.t + dt
		if click.t > 0.3 then
			table.remove(click_highlights, i)
		end
	end
	
	-- move eggs; first we block on the conveyor being active
	if not conveyor_moving then
		conveyor_reset_timer = conveyor_reset_timer - dt
		if conveyor_reset_timer > 0 then
			return
		end
		conveyor_moving = true
	end
	for i, egg in ipairs(spawned_eggs) do
		egg.x = egg.x - CONVEYOR_SPEED * dt - love.math.randomNormal(20, 0) * dt
		if egg.x < 200 then
			egg.vdown = egg.vdown + GRAVITY * dt
			egg.y = egg.y + egg.vdown
			if egg.y > EGG_Y + EGG_MAXFALL then
				eggs_lost = eggs_lost + 1
				remove_first_egg()
				event_msgs[#event_msgs + 1] = {str="egg failed!", col={1, 0.3, 0.3}}
				conveyor_moving = false
				conveyor_reset_timer = 1.5
				reset_task_progress()
			end
		end
	end
end

function setup_current_task()
	-- call this when we reset tasks or complete_task()s
	-- some tasks we want to complete for free:
	if current_task.tasktype == TASK_TYPES.click_egg then
		-- probably only relevant if don't respawn eggs properly...
		if #spawned_eggs + #basket_eggs < 1 then
			complete_task()
		end
	elseif current_task.tasktype == TASK_TYPES.click_next_egg then
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
	elseif current_task.tasktype == TASK_TYPES.click_any_striped then
		-- todo: currently breaks if only tasks are ones that
		-- don't have any eggs, because we get into a loop. should
		-- probably figure that out...
		exists = false
		for i, egg in ipairs(spawned_eggs) do
			if egg.eggtype.striped then
				exists = true
			end
		end
		if not exists then
			complete_task()
		end
	elseif current_task.tasktype == TASK_TYPES.click_n_eggs then
		-- here we include basket eggs because you could wait for them.
		current_task.excess = 0
		current_task.hit_idxs = {}
		total_eggs = #spawned_eggs + #basket_eggs
		if total_eggs < current_task.n then
			current_task.excess = current_task.n - total_eggs
			current_task.progress = current_task.excess
			if current_task.excess == current_task.n then
				complete_task()
			end
		end
	end
end


function remove_first_egg()
	table.remove(spawned_eggs, 1)
	if #spawned_eggs == 0 and #basket_eggs == 0 then
		loops_cleared = loops_cleared + 1
		if #tasks >= #task_queue then
			-- ideally shouldn't hit this
			started = false
			return
		end
		tasks[#tasks + 1] = task_queue[#tasks + 1]
		if eggs_per_basket < 8 then
			eggs_per_basket = eggs_per_basket + 2
		else
			eggs_per_basket = eggs_per_basket + 1
		end
		basket_eggs = new_basket(eggs_per_basket)
	elseif #spawned_eggs == 0 then
		spawn_egg()
	end
end


function complete_task()
	current_task.status = STATUS.done
	current_task_idx = current_task_idx + 1
	-- still tasks to go
	if current_task_idx <= #tasks then
		current_task = tasks[current_task_idx]
		current_task.status = STATUS.current
		setup_current_task()
		event_msgs[#event_msgs + 1] = {str="task completed!"}
		return
	end
	-- no tasks left: we finished an egg!
	event_msgs[#event_msgs + 1] = {str="egg cleared!", col={0.3, 1, 0.4}}
	eggs_cleared = eggs_cleared + 1
	remove_first_egg()
	reset_task_progress()
end


function is_in_egg(egg, x, y)
	rel = {x=x - (egg.x - EGG_SPRITE_BOT.x), y=y - (egg.y - EGG_SPRITE_BOT.y)}
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
	
	click_highlights[#click_highlights + 1] = {x=x, y=y, t=0}
	
	-- inactive
	if #spawned_eggs == 0 then
		return
	end
	
	-- see if we had a "clicking on egg" task!
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
	elseif current_task.tasktype == TASK_TYPES.click_any_striped then
		for i, egg in ipairs(spawned_eggs) do
			if egg.eggtype.striped and is_in_egg(egg, x, y) then
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
		current_task.progress = #current_task.hit_idxs + (current_task.excess or 0)
		if current_task.progress >= current_task.n then
			complete_task()
		end
	end
end


function love.keypressed(key, scancode, isrepeat)
	if key == "escape" then
		love.event.quit()
	end
	
	if current_task.tasktype == TASK_TYPES.keyseq then
		if current_task.progress == nil then
			current_task.progress = 0
			current_task.n = #current_task.seq
		end
		target_key = current_task.seq[current_task.progress + 1]
		target_wasd_key = WASD[target_key]
		if key == target_key or key == target_wasd_key then
			current_task.progress = current_task.progress + 1
		end
		if current_task.progress == current_task.n then
			complete_task()
		end
	elseif current_task.tasktype == TASK_TYPES.mash_keys then
		current_task.progress = (current_task.progress or 0) + 1
		if current_task.progress >= current_task.n then
			complete_task()
		end
	end
end
