# Bucket Rules

## Board

Bucket gameplay takes place in a two-part board shaped like a square bucket. The bottom is a square grid, and the wall is a long
grid connected to the four sides of the bottom. The wall has four sides, defined by which side of the
bottom.

This can be thought of two different ways. 

As two distinct areas:
```
Wall:
┌──────┬──────┬──────┬──────┐
│------│------│------│------│
│------│------│------│------│
│------│------│------│------│
│North-│-East-│South-│-West-│

Bottom:
┌──────┐
│------│
│------│
│------│
│------│
│------│
│------│
└──────┘
```

or as one combined grid:
```
Wall:
     ┌──────┐
     │------│
     │------│
     │------│
     │North-│
┌────┼──────┼────┐
│----│------│----│
│---t│------│E---│
│---s│Bottom│a---│
│---e│------│s---│
│---W│------│t---│
│----│------│----│
└────┼──────┼────┘
     │-South│
     │------│
     │------│
     │------│
     └──────┘
```

Note that this board has a width of 6 and a depth of 4: the bottom/sides are 6 tiles wide, and the
sides are 4 tiles tall. This is smaller than the default board in Bucket but easier to draw and
explain.

## Game loop

Gameplay in Bucket follows a simple loop:

1. Piece appears at the top of the wall.
2. Piece is dropped/shifted/rotated as it drops down the wall.
3. Piece falls into the bottom.
4. Piece hits the end of its path (or occupied grid squares).
5. If it's partially on a wall, that wall is blocked.
6. If it completes vertical or horizontal lines through the bottom, they're cleared.
7. If all four walls are blocked, the game is lost.

The rest of this section explains each of these in depth.

### Piece creation

Pieces are chosen from triominos, tetrominos, and pentominos. Each category is shuffled then picked
from in order, then reshuffled once every piece in that category is exhausted. This ensures that no
piece will be drawn more than twice in a row. The category to draw a piece from is chosen randomly with weights determined by the difficulty level.

The piece is then placed at the top of the wall at a random spot such that the piece is completely
on one side of the wall (not overlapping a corner). (Later: random rotation.)

### Piece movement

Pieces automatically drop from the top of the wall towards the bottom. Once they enter the bottom,
they fall towards the opposite side (pieces from the east fall towards the left, those from
the south fall towards the top, etc.). The piece drops on an interval (later: determined by
difficulty) which is reset every time the player drops the piece manually.

Along the way, the player can:
  * Drop the piece faster towards the bottom of its path,
  * shift it left and right along its path,
  * or rotate the piece left or right around its center.

If the piece is next to a corner of the wall and not partially in the bottom, then it can be shifted onto a neighboring wall. It moves completely onto that wall such that it does not overlap a corner.

> **Note**: A piece can be rotated such that it goes from being in the bottom to being purely on
> the wall, and can be shifted between walls at that point.

If the piece is dropped automatically or manually, and it hits the opposite side of the board or
occupied grid squares, then
it stops moving and locks into place on the grid.

#### Piece rotation

Pieces are rotated around the center of the square containing all of their possible states, as per the [Super Rotation
System](https://tetris.fandom.com/wiki/SRS).

If the piece would intersect a corner or occupied grid squares after rotation, it tries to
automatically shift left or right by up to half its width, rounded down (i.e., an I can shift up to
two squares left or right when rotated horizontally, a Z/S/T can shift up to one square, etc.).

### Line clearing

If the piece completes any lines through the bottom of the board, then they are
cleared and the other lines shifted towards the center of the board. For example, if an I piece stops like so (already filled squares marked with X's):

```
  123456
 ┌──────┐
1│-xx-x-│
2│xIIII-│
3│-xxxxx│
4│-xx-x-│
5│-xx-xx│
6│-xxxx-│
 └──────┘
```

then the vertical lines 2, 3 and 5 are complete and the board looks like this after clearing and
shifting:

```
  123456
 ┌──────┐
1│------│
2│--xx--│
3│---xx-│
4│------│
5│----x-│
6│---x--│
 └──────┘
```

This clearing extends onto the walls of the board. For example, if an I piece stops like so:

```
  123456
 ┌──────┬────┐
1│------│----│
2│------│----│
3│------│----│
4│------│----│
5│xxxxII│II--│
6│------│----│
 └──────┴────┘
```

then the board is completely empty after clearing.

Vertical and horizontal lines are checked at the same time, but horizontal lines are cleared and shifted
before vertical ones. For example, if a T piece stops like so:

```
  123456
 ┌──────┐
1│-x-T--│
2│xxxTTx│
3│x--T-x│
4│---x--│
5│---x--│
6│---x--│
 └──────┘
```

then the horizontal line 2 and vertical line 4 are filled and the board looks like this after
clearing and shifting:

```
  123456
 ┌──────┐
1│------│
2│-x----│
3│x---x-│
4│------│
5│------│
6│------│
 └──────┘
```

(Later: speed increase due to level increase due to cleared lines.)

### Wall blocking

If any grid squares are filled on a given wall after line clearing, then that wall is blocked.
New pieces do not start on blocked walls, and cannot be shifted into them (they shift through
the blocked wall to the opposite side). Blocked walls are unblocked when they are once again empty
due to cleared or shifted lines. 

If all four walls are blocked, then the player loses the game.
