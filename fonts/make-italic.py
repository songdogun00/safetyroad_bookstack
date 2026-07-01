import fontforge

jobs = [
    ("NanumGothic.ttf",      "NanumGothic-Italic.ttf",     "NanumGothic Italic"),
    ("NanumGothic-Bold.ttf", "NanumGothic-BoldItalic.ttf", "NanumGothic Bold Italic"),
    ("NanumGothic-ExtraBold.ttf", "NanumGothic-ExtraBoldItalic.ttf", "NanumGothic ExtraBold Italic"),
    ("NanumGothic-Light.ttf", "NanumGothic-LightItalic.ttf", "NanumGothic Light Italic"),
]

for src, out, name in jobs:
    f = fontforge.open(src)
    f.selection.all()
    f.transform((1, 0, 0.25, 1, 0, 0))   # 약 14도 기울임
    f.italicangle = -14
    f.familyname = "Nanum Gothic"
    f.fullname = name
    f.fontname = name.replace(" ", "")
    f.generate(out)
    print("generated", out)
