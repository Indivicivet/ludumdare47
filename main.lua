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
	EGG_LIFE_CRACKED = love.graphics.newImage("graphics/egg_life_cracked.png")
	EGG_LIFE_INTACT = love.graphics.newImage("graphics/egg_life_intact.png")
	
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
	
	DEAD_EGG = love.audio.newSource("sound/dead_egg.wav", "static")
	FINISH_TASK = love.audio.newSource("sound/finish_task.wav", "static")
	FINISH_EGG = love.audio.newSource("sound/finish_egg.wav", "static")
	FINISH_BASKET = love.audio.newSource("sound/finish_basket.wav", "static")
	EGG_SPAWN = love.audio.newSource("sound/egg_spawn.wav", "static")
	
	CONVEYOR_BACKWARDS = love.audio.newSource("sound/conveyor_backwards.wav", "static")
	CONVEYOR_BACKWARDS_TIME = 0.35
	
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
		[STATUS.current]={0.6, 0.7, 1},
		[STATUS.done]={0.5, 1, 0.8},
	}
	
	NEXT_EGG_TIME = 1.5
	CONVEYOR_SPEED = 70
	CONVEYOR_BACKSPEED_RATIO = 0.4
	GRAVITY = 10
	EGG_Y = 560
	EGG_MAXFALL = 100
	MAX_LIVES = 3
	
	SCREEN = {splash=1, game=2, fadeout=3, scores=4}
	FADEOUT_TIME = 1.5
	SCORE_FADEIN_TIME = 0.5
	
	click_highlights = {}  -- applicable for splash draw_cursor()
	
	screen = SCREEN.splash
	fade_t = 0
	
	-- for debug, skip splash screen:
	--reset_game()
end

function reset_task_progress()
	for i, task in ipairs(tasks) do
		task.status = STATUS.not_done
		task.progress = nil
		--if not (task.progress == nil) then
		--	task.progress = 0
		--end
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
		{tasktype=TASK_TYPES.click_egg},
		{tasktype=TASK_TYPES.keyseq, seq={"left", "right"}},
		{tasktype=TASK_TYPES.click_n_eggs, n=2},
		{tasktype=TASK_TYPES.keyseq, seq={"up", "left", "down"}},
		{tasktype=TASK_TYPES.click_any_xcol, col="blue"},
		{tasktype=TASK_TYPES.mash_keys, n=5},
		{tasktype=TASK_TYPES.click_any_striped},
		{tasktype=TASK_TYPES.click_any_xcol, col="red"},
		{tasktype=TASK_TYPES.keyseq, seq={"up", "down", "up", "down", "left"}},
		{tasktype=TASK_TYPES.mash_keys, n=10},
		{tasktype=TASK_TYPES.click_next_egg},
		{tasktype=TASK_TYPES.click_n_eggs, n=3},
		{tasktype=TASK_TYPES.click_any_xcol, col="green"},
	}
	
	tasks = {task_queue[1]}
	
	spawned_eggs = {}
	fadeout_eggs = {}
	t = 0
	eggs_lost = 0
	eggs_cleared = 0
	baskets_cleared = 0
	lives = MAX_LIVES
	
	basket_eggs_set = {}
	for i = 1, 6 do
		-- todo: randomize or something
		basket_eggs_set[#basket_eggs_set + 1] = EGG_TYPES[i]
	end
	eggs_per_basket = 2
	basket_eggs = new_basket(eggs_per_basket)
	spawn_egg()  -- sets next_egg_timer
	
	event_msgs = {{str="begin"}}
	
	reset_task_progress() -- must call after defining eggs :)
	screen = SCREEN.game
	
	conveyor_moving = true
	conveyor_t = 0 -- for conveyor sprite
	conveyor_reset_timer = 0
	conveyor_back_sound_t = 0
end

function draw_tasks(offset_x, offset_y)
	-- used ingame and in scores screen
	love.graphics.setFont(BASE_FONT)
	love.graphics.setColor(1, 1, 1)
	text_d_x = 50 + (offset_x or 0)
	text_d_y = 40 + (offset_y or 0)
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
end

function draw_stats(offset_x, offset_y)
	-- used ingame and on scores page
	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(BASE_FONT)
	text_d_x = 800 + (offset_x or 0)
	text_d_y = 200 + (offset_y or 0)
	love.graphics.print("eggs cleared: " .. eggs_cleared, text_d_x, text_d_y)
	text_d_y = text_d_y + BASE_FONTSIZE * 1.25
	love.graphics.print("eggs lost: " .. eggs_lost, text_d_x, text_d_y)
	text_d_y = text_d_y + BASE_FONTSIZE * 1.25
	love.graphics.print("baskets cleared: " .. baskets_cleared, text_d_x, text_d_y)
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
	
	if screen == SCREEN.splash then
		-- splash screen
		love.graphics.setColor(1, 1, 1)
		love.graphics.setFont(TITLE_FONT)
		love.graphics.printf("for egg in basket", 0, 200, WIDTH, "center")
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
			.. " free progress towards the task so it's possible.",
			"when you clear a basket, you get a life back."
		}
		draw_y = 600
		for i, line in ipairs(footnote_lines) do
			love.graphics.printf(line, 0, draw_y, WIDTH, "center")
			draw_y = draw_y + BASE_FONTSIZE * 1.2 * 0.7
		end
		draw_cursor()
		return
	end
	
	if screen == SCREEN.scores then
		love.graphics.setFont(BIG_FONT)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("final loop:", 100, 150)
		draw_tasks(50, 200)
		draw_stats(0, 0)
		if fade_t < SCORE_FADEIN_TIME then
			love.graphics.setColor(0, 0, 0, 1 - (fade_t / SCORE_FADEIN_TIME))
			love.graphics.rectangle("fill", 0, 0, WIDTH, HEIGHT)
		end
		draw_cursor()
		return
	end
	
	-- otherwise, we're ingame or fading out
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(BACKGROUND)
	
	-- tasks
	draw_tasks()
	
	-- print events
	love.graphics.setFont(HUGE_FONT)
	for i, event_msg in ipairs(event_msgs) do
		if i > 1 and (event_msg.d_y == nil) then
			event_msg.d_y = love.math.random(-50, 50)
		end
		cr, cg, cb = unpack(event_msg.col or {1, 1, 1})
		event_t = event_msg.t or 1
		event_d_y = event_msg.d_y or 0
		love.graphics.setColor(cr, cg, cb, 0.7 * (1 - event_t))
		love.graphics.printf(event_msg.str, 0, 270 + event_d_y + event_t * 10, 1280, "center")
	end
	
	-- eggs fading out
	for i, egg in ipairs(fadeout_eggs) do
		love.graphics.setColor(1, 1, 1, egg.alpha or 0.95)
		love.graphics.draw(
			egg.eggtype.sprite,
			egg.x - EGG_SPRITE_BOT.x,
			egg.y - EGG_SPRITE_BOT.y
		)
	end
	
	-- current egg highlighter
	love.graphics.setColor(1, 1, 1)
	if #spawned_eggs >= 1 then
		egg = spawned_eggs[1]
		love.graphics.setFont(BIG_FONT)
		love.graphics.printf("↓", egg.x - 30, egg.y - 150, 60, "center")
	end
	
	-- conveyor
	conv_frame_num = math.floor(conveyor_t * CONVEYOR_SPEED / 4) % #CONVEYOR_FRAMES
	love.graphics.draw(CONVEYOR_FRAMES[conv_frame_num], 210, EGG_Y - 5)
	love.graphics.setFont(BASE_FONT)
	
	-- eggs
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
	
	-- trash
	love.graphics.draw(
		TRASH_CAN,
		155 - TRASH_SPRITE_MID.x,
		EGG_Y + EGG_MAXFALL - TRASH_SPRITE_MID.y
	)
	
	-- basket
	basket_x = 1180
	basket_y = EGG_Y - 150
	love.graphics.draw(BASKET_BACK, basket_x - BASKET_TOP_MID.x, basket_y - BASKET_TOP_MID.y)
	love.graphics.setFont(HUGE_FONT)
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(#basket_eggs, basket_x - 50, basket_y - 45, 100, "center")
	love.graphics.draw(BASKET_FRONT, basket_x - BASKET_TOP_MID.x, basket_y - BASKET_TOP_MID.y)
	
	-- lives
	life_d_x = 780
	life_d_y = 100
	love.graphics.setFont(BASE_FONT)
	love.graphics.printf("lives:", life_d_x, life_d_y + 20, 100, "center")
	life_d_x = life_d_x + 100
	for i = 1, MAX_LIVES do
		if lives >= i then
			love.graphics.draw(EGG_LIFE_INTACT, life_d_x, life_d_y)
		else
			love.graphics.draw(EGG_LIFE_CRACKED, life_d_x, life_d_y)
		end
		life_d_x = life_d_x + 50
	end
	
	-- status gui
	draw_stats()
	
	-- screen fadeout
	if screen == SCREEN.fadeout then
		love.graphics.setColor(0, 0, 0, fade_t/FADEOUT_TIME)
		love.graphics.rectangle("fill", 0, 0, WIDTH, HEIGHT)
		love.graphics.setColor(1, 0.3, 0.3)
		love.graphics.setFont(HUGE_FONT)
		love.graphics.printf("game over...", 0, 300, WIDTH, "center")
	end
	
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
		EGG_SPAWN:play()
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
	if screen == SCREEN.splash then
		return
	end
	
	if screen == SCREEN.scores then
		fade_t = fade_t + dt
		return
	end
	
	if screen == SCREEN.fadeout then
		fade_t = fade_t + dt
		if fade_t >= FADEOUT_TIME then
			screen = SCREEN.scores
			fade_t = 0
		end
	end
	
	t = t + dt
	if conveyor_moving then
		conveyor_t = conveyor_t + dt
	else
		conveyor_t = conveyor_t - dt * CONVEYOR_BACKSPEED_RATIO
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
	
	for i, egg in ipairs(fadeout_eggs) do
		egg.alpha = (egg.alpha or 1) - 3 * dt
		if egg.alpha < 0 then
			table.remove(fadeout_eggs[i])
		end
	end
	
	-- move eggs; first we block on the conveyor being active
	if not conveyor_moving then
		-- sound stuff
		conveyor_back_sound_t = conveyor_back_sound_t + dt
		if conveyor_back_sound_t >= CONVEYOR_BACKWARDS_TIME then
			conveyor_back_sound_t = 0
			CONVEYOR_BACKWARDS:play()
		end
		
		-- gameplay stuff
		conveyor_reset_timer = conveyor_reset_timer - dt
		if conveyor_reset_timer <= 0 then
			conveyor_moving = true
		end
	end
	for i, egg in ipairs(spawned_eggs) do
		move_by = CONVEYOR_SPEED * dt - love.math.randomNormal(20, 0) * dt
		if not conveyor_moving then
			move_by = move_by * (- CONVEYOR_BACKSPEED_RATIO)
		end
		egg.x = egg.x - move_by
		if egg.x < 200 then
			egg.vdown = egg.vdown + GRAVITY * dt
			egg.y = egg.y + egg.vdown
			if egg.y > EGG_Y + EGG_MAXFALL then
				if screen ~= SCREEN.game then
					table.remove(spawned_eggs, 1)
					return
				end
				eggs_lost = eggs_lost + 1
				lives = lives - 1
				remove_first_egg()
				event_msgs[#event_msgs + 1] = {str="egg failed!", col={1, 0.3, 0.3}}
				DEAD_EGG:play()
				conveyor_moving = false
				conveyor_reset_timer = 1.5
				if lives > 0 then
					reset_task_progress()
				else
					--event_msgs[#event_msgs + 1] = {str="game over...", col={1, 0.5, 0.5}}
					--GAME_OVER:play()
					screen = SCREEN.fadeout
					fade_t = 0
				end
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
		baskets_cleared = baskets_cleared + 1
		if #tasks >= #task_queue then
			-- ideally shouldn't hit this
			screen = SCREEN.fadeout
			return
		end
		tasks[#tasks + 1] = task_queue[#tasks + 1]
		if eggs_per_basket < 8 then
			eggs_per_basket = eggs_per_basket + 1 -- was 2 but was 2hard.
		else
			eggs_per_basket = eggs_per_basket + 1
		end
		basket_eggs = new_basket(eggs_per_basket)
		event_msgs[#event_msgs + 1] = {str="basket cleared!", col={0.3, 1, 0.4}}
		if lives < MAX_LIVES then
			lives = lives + 1
		end
		FINISH_BASKET:play()
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
		FINISH_TASK:play()
		return
	end
	-- no tasks left: we finished an egg!
	event_msgs[#event_msgs + 1] = {str="egg cleared!", col={0.3, 1, 0.4}}
	eggs_cleared = eggs_cleared + 1
	FINISH_EGG:play()
	fadeout_eggs[#fadeout_eggs + 1] = spawned_eggs[1]
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
	if screen == SCREEN.splash or screen == SCREEN.scores then
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
	
	if screen ~= SCREEN.game then
		return
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
