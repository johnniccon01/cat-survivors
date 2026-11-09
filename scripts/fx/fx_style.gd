class_name FxStyle
## The look of the weapons' effects (swipes, rings, beams, bolts, waves,
## hits). With `soft` on they match the soft-edged icons: no white cores (a
## light shade of the effect's own colour instead), a fainter glow, and a
## darker shade of the colour along the edges instead of black.

static var soft := false


## The bright core of an effect: white, or a light shade of `tint`.
static func white(tint: Color, a: float) -> Color:
	return Color(tint.lightened(0.62), a) if soft else Color(1, 1, 1, a)


## How strong a wide glow is.
static func glow(a: float) -> float:
	return a * 0.55 if soft else a


## The edge of something coloured `fill`: black, or its own darker shade.
static func edge(fill: Color, a: float = 1.0) -> Color:
	return Color(fill.darkened(0.42), a) if soft else Color(Color("2b1d14"), a)
