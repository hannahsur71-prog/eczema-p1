#!/usr/bin/env python3
"""Converts the prototype's SVG illustrations into Swift path data (Alji/Onboarding/OnboardingArtData.swift).
Usage: python3 scripts/generate-onboarding-art.py <Main.dc.html> <hand.svgfrag>
Needs: pip install fonttools"""
import re, sys, math
import xml.etree.ElementTree as ET
from fontTools.svgLib.path import parse_path
from fontTools.pens.recordingPen import RecordingPen
from fontTools.pens.transformPen import TransformPen
from fontTools.misc.transform import Transform, Identity

K = 0.5522847498
def ellipse_d(cx, cy, rx, ry):
    return (f"M{cx-rx} {cy} C{cx-rx} {cy-K*ry} {cx-K*rx} {cy-ry} {cx} {cy-ry} C{cx+K*rx} {cy-ry} {cx+rx} {cy-K*ry} {cx+rx} {cy} "
            f"C{cx+rx} {cy+K*ry} {cx+K*rx} {cy+ry} {cx} {cy+ry} C{cx-K*rx} {cy+ry} {cx-rx} {cy+K*ry} {cx-rx} {cy} Z")
def rect_d(x, y, w, h, r):
    r = min(r, w/2, h/2)
    if r <= 0: return f"M{x} {y} L{x+w} {y} L{x+w} {y+h} L{x} {y+h} Z"
    k = K*r
    return (f"M{x+r} {y} L{x+w-r} {y} C{x+w-r+k} {y} {x+w} {y+r-k} {x+w} {y+r} L{x+w} {y+h-r} C{x+w} {y+h-r+k} {x+w-r+k} {y+h} {x+w-r} {y+h} "
            f"L{x+r} {y+h} C{x+r-k} {y+h} {x} {y+h-r+k} {x} {y+h-r} L{x} {y+r} C{x} {y+r-k} {x+r-k} {y} {x+r} {y} Z")
def parse_transform(s):
    t = Identity
    for name, args in re.findall(r'(\w+)\(([^)]*)\)', s or ''):
        a = [float(v) for v in re.split(r'[ ,]+', args.strip()) if v]
        if name == 'translate': t = t.translate(a[0], a[1] if len(a) > 1 else 0)
        elif name == 'scale': t = t.scale(a[0], a[1] if len(a) > 1 else a[0])
        elif name == 'rotate':
            if len(a) == 3: t = t.translate(a[1], a[2]).rotate(math.radians(a[0])).translate(-a[1], -a[2])
            else: t = t.rotate(math.radians(a[0]))
    return t
def paint(v):
    if v is None: return None
    v = v.strip()
    if v == 'none': return ('none',)
    if v.startswith('url('): return ('skin',)
    if v == 'BLOB': return ('blob',)
    m = re.match(r'rgba\((\d+), *(\d+), *(\d+), *([\d.]+)\)', v)
    if m: return ('color', (int(m[1]) << 16) | (int(m[2]) << 8) | int(m[3]), float(m[4]))
    if v.startswith('#') and len(v) == 7: return ('color', int(v[1:], 16), 1.0)
    return None
def fmt(n):
    s = f"{n:.1f}"; return s[:-2] if s.endswith('.0') else s
def walk(el, t, st, out):
    tag = el.tag.split('}')[-1]
    if tag in ('defs', 'text', 'animate', 'animateTransform', 'animateMotion', 'title'): return
    st = dict(st)
    for k in ('fill', 'stroke', 'stroke-width', 'opacity'):
        if el.get(k) is not None:
            st[k] = float(el.get(k)) * (st.get('opacity', 1) if k == 'opacity' else 1) if k in ('stroke-width', 'opacity') else el.get(k)
    t = t.transform(parse_transform(el.get('transform')))
    d = None
    g = lambda k, dflt=0: float(el.get(k, dflt))
    if tag == 'path': d = el.get('d')
    elif tag == 'circle': d = ellipse_d(g('cx'), g('cy'), g('r'), g('r'))
    elif tag == 'ellipse': d = ellipse_d(g('cx'), g('cy'), g('rx'), g('ry'))
    elif tag == 'rect': d = rect_d(g('x'), g('y'), g('width'), g('height'), g('rx'))
    if d:
        rec = RecordingPen(); parse_path(d, TransformPen(rec, t))
        parts = []
        for op, pts in rec.value:
            if op == 'moveTo': parts.append('M ' + ' '.join(fmt(c) for c in pts[0]))
            elif op == 'lineTo': parts.append('L ' + ' '.join(fmt(c) for c in pts[0]))
            elif op == 'curveTo': parts.append('C ' + ' '.join(fmt(c) for p in pts for c in p))
            elif op == 'qCurveTo': parts.append('Q ' + ' '.join(fmt(c) for p in pts for c in p))
            elif op in ('closePath',): parts.append('Z')
        fill = paint(st.get('fill')) or ('color', 0, 1.0)
        stroke = paint(st.get('stroke'))
        scale = math.sqrt(abs(t[0]*t[3] - t[1]*t[2]))
        out.append((' '.join(parts), fill, stroke, st.get('stroke-width', 1) * scale, st.get('opacity', 1)))
    for c in el: walk(c, t, st, out)
def convert(fragment, pre=Identity):
    fragment = re.sub(r'\{\{ sc\.blobColor \}\}', 'BLOB', fragment)
    fragment = re.sub(r'<(/?)sc-(if|for)[^>]*>', '', fragment)
    root = ET.fromstring('<root>' + fragment + '</root>')
    out = []; walk(root, pre, {}, out); return out
def swift(name, shapes):
    lines = [f"    static let {name}: [ArtShape] = ["]
    for d, fill, stroke, w, op in shapes:
        def p(x):
            if x is None or x[0] == 'none': return 'nil', 1.0, 0
            if x[0] == 'skin': return '0xF2B48A', 1.0, 1
            if x[0] == 'blob': return '0x000000', 1.0, 2
            return f"0x{x[1]:06X}", x[2], 0
        fc, fo, fs = p(fill); sc, so, _ = p(stroke)
        lines.append(f'        ArtShape("{d}", fill: {fc}, fillOpacity: {fmt(fo*op) if fo*op != 1 else "1"}, stroke: {sc}, strokeOpacity: {fmt(so*op) if so*op != 1 else "1"}, lineWidth: {fmt(w)}, special: {fs}),')
    lines.append("    ]"); return '\n'.join(lines)

main = open(sys.argv[1]).read(); hand = open(sys.argv[2]).read()
def between(a, b, start=0):
    i = main.index(a, start); j = main.index(b, i); return main[i:j + len(b)]
hero = between('<svg viewBox="0 0 230 210"', '</svg>')
screen_free = between('<svg viewBox="0 0 320 250"', '</svg>')
bi = main.index('<!-- before / after scenes -->')
before = between('<svg viewBox="0 0 120 84"', '</svg>', bi)
after = between('<svg viewBox="0 0 120 84"', '</svg>', main.index('</svg>', bi) + 6)
ti = main.index('{{ sc.isTaste }}')
body = '<ellipse cx="150" cy="330" rx="110" ry="10" fill="rgba(0,0,0,0.18)"></ellipse>' + between('<g stroke="#FFFFFF" stroke-width="3"', '</g>', ti)
strip = lambda s: re.sub(r'<svg[^>]*>|</svg>', '', re.sub(r'\saria-[a-z]+="[^"]*"|\srole="[^"]*"|\sstyle="[^"]*"', '', s))
out = ["// Generated by scripts/generate-onboarding-art.py from the approved prototype. Do not edit by hand.", "import Foundation", "",
       "/// Illustration path data, in each drawing's own coordinate space (see the `Size` constants).", "enum ArtData {",
       "    static let heroSize = CGSize(width: 230, height: 210)", "    static let screenFreeSize = CGSize(width: 320, height: 250)",
       "    static let sceneSize = CGSize(width: 120, height: 84)", "    static let bodySize = CGSize(width: 300, height: 340)",
       "    /// The hand is drawn fingers-up; its palm sits at `handAnchor`.", "    static let handSize = CGSize(width: 60, height: 64)", "    static let handAnchor = CGPoint(x: 30, y: 34)", ""]
out.append(swift('hero', convert(strip(hero)))); out.append(swift('screenFree', convert(strip(screen_free))))
out.append(swift('before', convert(strip(before)))); out.append(swift('after', convert(strip(after))))
out.append(swift('bodyBack', convert(body))); out.append(swift('hand', convert(hand, Identity.translate(30, 34))))
out.append("}"); print('\n'.join(out))
