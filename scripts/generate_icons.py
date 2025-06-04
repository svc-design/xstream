import os
from PIL import Image

sizes = [
    ("Icon-App-20x20@1x.png", 20),
    ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60),
    ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58),
    ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40),
    ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120),
    ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180),
    ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152),
    ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png", 1024)
]

base = Image.open('assets/logo.png')
base = base.convert('RGBA')

out_dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
os.makedirs(out_dir, exist_ok=True)

for filename, size in sizes:
    img = base.resize((size, size), Image.LANCZOS)
    img.save(os.path.join(out_dir, filename), format='PNG')

