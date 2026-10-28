# gen_icon.py —— 把显示器 SVG 图标还原为多尺寸 icon.ico
# 原 SVG (viewBox 0 0 1024 1024, fill #707070) 的几何结构：
#   1) 显示器外框: 圆角矩形环 外沿(154.45,187.73)-(927.40,708.27) r=102.4, 线宽 68.27
#   2) 底座横线:   圆头胶囊 (323.42,750.93)-(758.61,819.20) r=34.13
from PIL import Image, ImageDraw

COLOR = (112, 112, 112, 255)  # #707070

SS = 4  # 4x 超采样抗锯齿
size = 1024 * SS
img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

s = SS  # scale
# 显示器外框（outline 从 bbox 外沿向内画，内半径自动 = 102.4-68.27 = 34.13，与原 SVG 一致）
d.rounded_rectangle([154.45*s, 187.73*s, 927.40*s, 708.27*s],
                    radius=102.4*s, outline=COLOR, width=round(68.27*s))
# 底座
d.rounded_rectangle([323.42*s, 750.93*s, 758.61*s, 819.20*s],
                    radius=34.13*s, fill=COLOR)

img = img.resize((1024, 1024), Image.LANCZOS)

img.save("icon.ico",
         sizes=[(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (24, 24), (16, 16)])
img.resize((128, 128), Image.LANCZOS).save("icon_preview.png")
print("icon.ico generated")
