"""
Applet: Perlin Noise
Summary: Perlin noise for your Tronbyt
Description: Set the vibe with beautiful, complex, colorful animated noise produced with math!
Author: rektdeckard
"""

load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")

SCALE = 40
SCALE_T = "40"
SPEED = 1 / 30
HUE = "#EB6E21"
FRAMES = 160
FRAMES_PER_VIEW = 1

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Color(
                id = "color",
                name = "Color",
                desc = "Hue of the noise.",
                icon = "brush",
                default = HUE,
            ),
            schema.Text(
                id = "scale",
                name = "Scale",
                desc = "Scale of the noise.",
                icon = "ruler",
                default = SCALE_T,
            ),
        ],
    )

PERMUTATION = [151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180]

GRAD_3 = [[1.0, 1.0, 0.0], [-1.0, 1.0, 0.0], [1.0, -1.0, 0.0], [-1.0, -1.0, 0.0], [1.0, 0.0, 1.0], [-1.0, 0.0, 1.0], [1.0, 0.0, -1.0], [-1.0, 0.0, -1.0], [0.0, 1.0, 1.0], [0.0, -1.0, 1.0], [0.0, 1.0, -1.0], [0.0, -1.0, -1.0]]

def grad_dot2(grad, a, b):
    return grad[0] * a + grad[1] * b

def grad_dot3(grad, a, b, c):
    return grad[0] * a + grad[1] * b + grad[2] * c

def lerp(mn, mx, v):
    return (mn + (mx - mn) * v)

perm = [0 for x in range(512)]
grads = [0 for x in range(512)]
F2 = 0.5 * (math.sqrt(3) - 1)
G2 = (3 - math.sqrt(3)) / 6
F3 = 1 / 3
G3 = 1 / 6

def reseed(seed):
    if seed > 0 and seed < 1:
        seed *= 655536
    se = math.floor(seed)
    if se < 256:
        se |= se << 8
    for i in range(256):
        v = 0
        if i & 1:
            v = PERMUTATION[i] ^ (se & 255)
        else:
            v = PERMUTATION[i] * ((se >> 8) & 255)
        perm[i + 256] = v
        perm[i] = v
        grads[i + 256] = GRAD_3[v % 12]
        grads[i] = grads[i + 256]

def simp(x, y, z):
    s = (x + y + z) * F3
    i = math.floor(x + s)
    j = math.floor(y + s)
    k = math.floor(z + s)
    t = (i + j + k) * G3
    x0 = x - i + t
    y0 = y - j + t
    z0 = z - k + t
    i1 = 0
    j1 = 0
    k1 = 0
    i2 = 0
    j2 = 0
    k2 = 0
    if x0 > y0:
        if y0 > z0:
            i1 = 1
            j1 = 0
            k1 = 0
            i2 = 1
            j2 = 1
            k2 = 0
        elif x0 > z0:
            i1 = 1
            j1 = 0
            k1 = 0
            i2 = 1
            j2 = 0
            k2 = 1
        else:
            i1 = 0
            j1 = 0
            k1 = 1
            i2 = 1
            j2 = 0
            k2 = 1
    elif y0 < z0:
        i1 = 0
        j1 = 0
        k1 = 1
        i2 = 0
        j2 = 1
        k2 = 1
    elif x0 < z0:
        i1 = 0
        j1 = 1
        k1 = 0
        i2 = 0
        j2 = 1
        k2 = 1
    else:
        i1 = 0
        j1 = 1
        k1 = 0
        i2 = 1
        j2 = 1
        k2 = 0
    x1 = x0 - i1 + G3
    y1 = y0 - j1 + G3
    z1 = z0 - k1 + G3
    x2 = x0 - i2 + 2 * G3
    y2 = y0 - j2 + 2 * G3
    z2 = z0 - k2 + 2 * G3
    x3 = x0 - 1 + 3 * G3
    y3 = y0 - 1 + 3 * G3
    z3 = z0 - 1 + 3 * G3
    ii = math.floor(i) & 255
    jj = math.floor(j) & 255
    kk = math.floor(k) & 255
    gi0 = grads[ii + perm[jj + perm[kk]]]
    gi1 = grads[ii + i1 + perm[jj + j1 + perm[kk + k1]]]
    gi2 = grads[ii + i2 + perm[jj + j2 + perm[kk + k2]]]
    gi3 = grads[ii + 1 + perm[jj + 1 + perm[kk + 1]]]
    t0 = 0.6 - x0 * x0 - y0 * y0 - z0 * z0
    if t0 < 0.0:
        n0 = 0.0
    else:
        t0 *= t0
        n0 = t0 * t0 * grad_dot3(gi0, x0, y0, z0)
    t1 = 0.6 - x1 * x1 - y1 * y1 - z1 * z1
    if t1 < 0.0:
        n1 = 0.0
    else:
        t1 *= t1
        n1 = t1 * t1 * grad_dot3(gi1, x1, y1, z1)
    t2 = 0.6 - x2 * x2 - y2 * y2 - z2 * z2
    if t2 < 0.0:
        n2 = 0.0
    else:
        t2 *= t2
        n2 = t2 * t2 * grad_dot3(gi2, x2, y2, z2)
    t3 = 0.6 - x3 * x3 - y3 * y3 - z3 * z3
    if t3 < 0.0:
        n3 = 0.0
    else:
        t3 *= t3
        n3 = t3 * t3 * grad_dot3(gi3, x3, y3, z3)
    return 32 * (n0 + n1 + n2 + n3)

reseed(0)

def flatten(iter):
    list = []
    if type(iter) != "list":
        list.append(iter)
    else:
        for it in iter:
            if type(it) != "list":
                list.append(it)
            else:
                list.extend(flatten(it))
    return list

def color_for_pixel(x, y, t, c, s):
    b = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"]
    val = simp(x / s, y / s, t * SPEED)
    val = math.floor((val + 1) * 128)
    h = (val & 0xF0) >> 4
    l = val & 0x0F

    # print([h, l])
    return c + b[h] + b[l]

def main(config):
    color = config.str("color")
    if not color:
        color = HUE
    scale = config.str("scale")
    if not scale:
        scale = SCALE
    scale = int(scale)

    return render.Root(
        child = render.Animation(
            children = flatten([[render.Column([
                render.Row([
                    render.Box(color = color_for_pixel(x, y, t, color, scale), width = 1, height = 1)
                    for x in range(64)
                ])
                for y in range(32)
            ])] * FRAMES_PER_VIEW for t in range(FRAMES)]),
        ),
    )
