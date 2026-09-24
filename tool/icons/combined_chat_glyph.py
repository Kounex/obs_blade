"""Combined-chat glyph v2: one solid speech bubble with a knocked-out
"merge" mark inside - three input nodes on the left whose lines converge
into one output node on the right: several chats flowing into one.
Single color, so it tints per theme like every other glyph in the font."""
import sys
from pathops import Path, op, PathOp
from fontTools.ttLib import TTFont
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.recordingPen import RecordingPen

UPM = 1000
K = 0.5523

def circle(cx, cy, r):
    c = Path(); k = K * r
    c.moveTo(cx + r, cy)
    c.cubicTo(cx + r, cy + k, cx + k, cy + r, cx, cy + r)
    c.cubicTo(cx - k, cy + r, cx - r, cy + k, cx - r, cy)
    c.cubicTo(cx - r, cy - k, cx - k, cy - r, cx, cy - r)
    c.cubicTo(cx + k, cy - r, cx + r, cy - k, cx + r, cy)
    c.close(); return c

def bubble(x0, y0, x1, y1, r):
    """Rounded rect with a tail at the bottom-left (y-up)."""
    p = Path(); k = K * r
    p.moveTo(x0 + r + 190, y0)
    p.lineTo(x1 - r, y0)
    p.cubicTo(x1 - r + k, y0, x1, y0 + r - k, x1, y0 + r)
    p.lineTo(x1, y1 - r)
    p.cubicTo(x1, y1 - r + k, x1 - r + k, y1, x1 - r, y1)
    p.lineTo(x0 + r, y1)
    p.cubicTo(x0 + r - k, y1, x0, y1 - r + k, x0, y1 - r)
    p.lineTo(x0, y0 + r)
    p.cubicTo(x0, y0 + r - k, x0 + r - k, y0, x0 + r, y0)
    # classic tail: drops from the bottom edge near the left corner,
    # points down-left, soft inner curve
    p.lineTo(x0 + r + 10, y0)
    p.lineTo(x0 + 70, y0 - 150)
    p.quadTo(x0 + 250, y0 - 70, x0 + r + 190, y0)
    p.close()
    return p

def line(ax, ay, bx, by, w):
    """Stream from an input node into the output: leaves horizontally,
    bends in, arrives horizontally (an S-curve), round caps."""
    p = Path(); p.moveTo(ax, ay)
    mx = (ax + bx) / 2
    p.cubicTo(mx, ay, mx, by, bx, by)
    p.stroke(w, 1, 1, 4)
    p.convertConicsToQuads()
    return p

X0, Y0, X1, Y1, R = 60, 230, 940, 900, 210
body = bubble(X0, Y0, X1, Y1, R)

cy = (Y0 + Y1) / 2
ins = [(270, cy + 185), (270, cy), (270, cy - 185)]
out = (720, cy)
LW = 92
mark = Path()
for (x, y) in ins:
    mark = op(mark, line(x, y, out[0], out[1], LW), PathOp.UNION)
    mark = op(mark, circle(x, y, 70), PathOp.UNION)
mark = op(mark, circle(out[0], out[1], 112), PathOp.UNION)

glyph = op(body, mark, PathOp.DIFFERENCE)
glyph.simplify()

rec = RecordingPen(); glyph.draw(rec)
xs = [x for _, pts in rec.value for x, _ in pts]
ys = [y for _, pts in rec.value for _, y in pts]
minx, maxx, miny, maxy = min(xs), max(xs), min(ys), max(ys)
scale = min((UPM * 0.92) / (maxx - minx), (UPM * 0.92) / (maxy - miny))
ox = (UPM - (maxx - minx) * scale) / 2 - minx * scale
oy = (UPM - (maxy - miny) * scale) / 2 - miny * scale

src, dst, svg_out = sys.argv[1], sys.argv[2], sys.argv[3]
font = TTFont(src)
upm = font['head'].unitsPerEm
f = upm / UPM
pen = TTGlyphPen(None)
glyph.draw(Cu2QuPen(TransformPen(pen, (scale * f, 0, 0, scale * f, ox * f, (oy - UPM * 0.125) * f)), max_err=1.0, reverse_direction=True))
name = 'combined_chat'
order = font.getGlyphOrder()
if name not in order:
    font.setGlyphOrder(order + [name])
font['glyf'][name] = pen.glyph()
font['hmtx'][name] = (upm, 0)
for table in font['cmap'].tables:
    if table.isUnicode():
        table.cmap[0xE802] = name
font['maxp'].numGlyphs = len(font.getGlyphOrder())
font.save(dst)

sp = SVGPathPen(None)
glyph.draw(TransformPen(sp, (scale, 0, 0, -scale, ox, UPM - oy)))
open(svg_out, 'w').write(
    f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {UPM} {UPM}">'
    f'<path d="{sp.getCommands()}"/></svg>')
print('ok upm', upm)
