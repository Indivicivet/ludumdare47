function love.load()
	WIDTH = 1280
	HEIGHT = 720
	love.window.setMode(WIDTH, HEIGHT)
	love.window.setTitle("for egg in basket")

	BASE_FONTSIZE = 22
	BASE_FONT = love.graphics.newFont("fonts/VCR_OSD_MONO_1.001.ttf", BASE_FONTSIZE)
	
	EGG_TYPES = {
		{
			col="blue",
			striped=false,
			sprite_name="egg_blue_dotty",
		},
		{
			col="green",
			striped=false,
			sprite_name="egg_green_dotty",
		},
		{
			col="red",
			striped=false,
			sprite_name="egg_red_dotty",
		},
		{
			col="blue",
			striped=true,
			sprite_name="egg_blue_striped",
		},
		{
			col="green",
			striped=true,
			sprite_name="egg_green_striped",
		},
		{
			col="red",
			striped=true,
			sprite_name="egg_red_striped",
		},
		{
			col="gold",
			striped=false,
			sprite_name="egg_golden",
		},
	}
	for i, eggtype_info in ipairs(EGG_TYPES) do
		eggtype_info["sprite"] = love.graphics.newImage(
			"graphics/" .. eggtype_info["sprite_name"] .. ".png"
		)
	end
	
	basket_eggs = {}
	for i = 1, 5 do
		basket_eggs[#basket_eggs + 1] = EGG_TYPES[i]
	end
	
	TASK_TYPES = {
		click_egg={
			str="click the egg!",
		},
	}
	
	tasks = {TASK_TYPES.click_egg, TASK_TYPES.click_egg}
	
	spawned_eggs = {}
	NEXT_EGG_TIME = 1
	CONVEYOR_SPEED = 80
	next_egg_timer = NEXT_EGG_TIME
end

function love.draw()
	love.graphics.setFont(BASE_FONT)
	love.graphics.setColor(1, 1, 1)
	text_d_x = 40
	text_d_y = 10
	love.graphics.print("for egg in basket:", text_d_x, text_d_y)
	text_d_x = text_d_x + 50 -- tab in
	for i, task in ipairs(tasks) do
		text_d_y = text_d_y + BASE_FONTSIZE * 1.2
		love.graphics.print(task.str, text_d_x, text_d_y)
	end
	for i, egg in ipairs(spawned_eggs) do
		love.graphics.draw(egg.eggtype.sprite, egg.x, egg.y)
	end
	love.graphics.print("eggs left in basket: " .. #basket_eggs, 800, 10)
end

function love.update(dt)
	next_egg_timer = next_egg_timer - dt
	if next_egg_timer < 0 then
		if #basket_eggs > 0 then
			spawned_eggs[#spawned_eggs + 1] = {
				eggtype=basket_eggs[1],
				x=1000,
				y=500,
			}
			table.remove(basket_eggs, 1)
			next_egg_timer = NEXT_EGG_TIME
		end
	end
	for i, egg in ipairs(spawned_eggs) do
		egg.x = egg.x - CONVEYOR_SPEED * dt
	end
end

