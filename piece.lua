piece = {}

PIECES = {
	{
		{1,0},
		{1,1},
		{0,1}
	},
	{
		{0,1},
		{1,1},
		{1,0}
	}
}

function piece.random()
	piece_yx = PIECES[love.math.random(1, #PIECES)]

	piece_xy = {}

	for x = 1,#piece_yx[1] do
		piece_xy[x] = {}

		for y = 1,#piece_yx do
			piece_xy[x][y] = (piece_yx[y][x] == 1)
		end
	end

	return piece_xy
end

module("piece")
