

function love.load()
	WIDTH = 1280
	HEIGHT = 720
	love.window.setMode(WIDTH, HEIGHT)
	love.window.setTitle("for egg in basket")

	BASE_FONTSIZE = 22
	BASE_FONT = love.graphics.newFont("fonts/VCR_OSD_MONO_1.001.ttf", BASE_FONTSIZE)
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
end

