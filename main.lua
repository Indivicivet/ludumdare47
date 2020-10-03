function love.load()
	WIDTH = 1280
	HEIGHT = 720
	love.window.setMode(WIDTH, HEIGHT)
	love.window.setTitle("for egg in basket")

	BASE_FONTSIZE = 22
	BASE_FONT = love.graphics.newFont("fonts/VCR_OSD_MONO_1.001.ttf", BASE_FONTSIZE)
	
	EGG_TYPES = {
		{col="blue", striped=false, sprite_name="egg_blue_dotty"},
		{col="green", striped=false, sprite_name="egg_green_dotty"},
		{col="red", striped=false, sprite_name="egg_red_dotty"},
		{col="blue", striped=true, sprite_name="egg_blue_striped"},
		{col="green", striped=true, sprite_name="egg_green_striped"},
		{col="red", striped=true, sprite_name="egg_red_striped"},
		{col="gold", striped=false, sprite_name="egg_golden"},
	}
	for i, eggtype_info in ipairs(EGG_TYPES) do
		eggtype_info["sprite"] = love.graphics.newImage(
			"graphics/" .. eggtype_info["sprite_name"] .. ".png"
		)
	end
	EGG_SPRITE_BOT = {x=62, y=110}
	
	TRASH_CAN = love.graphics.newImage("graphics/trash_can.png")
	TRASH_SPRITE_MID = {x=64, y=66}
	
	CURSOR = love.graphics.newImage("graphics/cursor.png")
	love.mouse.setVisible(false)
	
	TASK_TYPES = {
		click_egg={
			str="click the egg!",
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

function reset_game()
	tasks = {{tasktype=TASK_TYPES.click_egg}, {tasktype=TASK_TYPES.click_egg}}
	for i, task in ipairs(tasks) do
		task.status = STATUS.not_done
	end
	tasks[1].status = STATUS.current
	
	spawned_eggs = {}
	t = 0
	eggs_lost = 0
	next_egg_timer = NEXT_EGG_TIME
	
	basket_eggs = {}
	for i = 1, 5 do
		basket_eggs[#basket_eggs + 1] = EGG_TYPES[i]
	end
	
	started = true
end

function love.draw()
	if not started then
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
		love.graphics.print(task.tasktype.str, text_d_x, text_d_y)
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
	mouse_x, mouse_y = love.mouse.getPosition()
	love.graphics.draw(CURSOR, mouse_x, mouse_y)
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


function love.keypressed(key, scancode, isrepeat)
	-- esc keys isn't going through, maybe being passed to something else
	-- on my PC at the moment?
	if key == "escape" then
		love.event.quit()
	end
end
