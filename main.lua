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
	
	eggs = {}
	for i = 1, 5 do
		eggs[#eggs + 1] = {
			spawned=false,
			eggtype=EGG_TYPES[i],
		}
	end
	next_egg_timer = 1
end

function love.draw()
	love.graphics.setFont(BASE_FONT)
	love.graphics.setColor(1, 1, 1)
	text_d_x = 40
	text_d_y = 10
	love.graphics.print("for egg in basket:", text_d_x, text_d_y)
	text_d_y = text_d_y + BASE_FONTSIZE * 1.2
	text_d_x = text_d_x + 50 -- tab in
	love.graphics.print("click the egg!", text_d_x, text_d_y)
	egg_d_y = 500
	egg_d_x = 50
	for i, egg in ipairs(eggs) do
		love.graphics.draw(egg.eggtype.sprite, egg_d_x, egg_d_y)
		egg_d_x = egg_d_x + 150
	end
end

function love.update(dt)
	
end

