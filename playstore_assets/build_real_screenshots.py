import os
import base64
import subprocess
import glob

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(BASE_DIR, 'output')
TEMPLATES_DIR = os.path.join(BASE_DIR, 'templates')

os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(TEMPLATES_DIR, exist_ok=True)

# Helper to read base64
def get_b64(path):
    if not os.path.exists(path):
        return ""
    with open(path, 'rb') as f:
        return base64.b64encode(f.read()).decode('utf-8')

# Real screenshots from user's Pictures folder
pic_login_path = r'C:\Users\USER\Pictures\Screenshot_20261031-162508 (1).png'
pic_active_path = r'C:\Users\USER\Pictures\Screenshot_20261031-162357 (1).png'
pic_browser_path = r'C:\Users\USER\Pictures\Screenshot_20261031-162416 (1).png'
pic_boards_path = r'C:\Users\USER\Pictures\Screenshot_20261031-162425 (1).png'
pic_gallery_path = r'C:\Users\USER\Pictures\Screenshot_20261031-162432 (1).png'
pic_schedule_path = r'C:\Users\USER\Pictures\Screenshot_20261031-162448 (1).png'

logo_path = os.path.normpath(os.path.join(BASE_DIR, '..', 'mobile-client', 'assets', 'logo.png'))

logo_b64 = get_b64(logo_path)
b64_login = get_b64(pic_login_path)
b64_active = get_b64(pic_active_path)
b64_browser = get_b64(pic_browser_path)
b64_boards = get_b64(pic_boards_path)
b64_gallery = get_b64(pic_gallery_path)
b64_schedule = get_b64(pic_schedule_path)

# 1080 x 1920 (Standard Play Store 9:16 FHD - eliminates the "too long" look)
def generate_html(pill_tag, title_line1, title_highlight, subtitle, b64_img, is_gold=False):
    glow_color = "rgba(255, 215, 0, 0.22)" if is_gold else "rgba(230, 0, 35, 0.28)"
    pill_border = "rgba(255, 215, 0, 0.35)" if is_gold else "rgba(230, 0, 35, 0.35)"
    pill_text = "#FFD700" if is_gold else "#FF5268"
    highlight_gradient = "linear-gradient(135deg, #FFD700 0%, #FFA500 100%)" if is_gold else "linear-gradient(135deg, #FF455D 0%, #FF8A9A 100%)"

    return f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  body {{
    width: 1080px;
    height: 1920px;
    background: radial-gradient(circle at 50% 12%, #1a080d 0%, #0d0e13 42%, #08080a 100%);
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI Variable Display', 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
    color: #FFFFFF;
    position: relative;
    overflow: hidden;
  }}
  .glow {{
    position: absolute;
    width: 900px;
    height: 900px;
    top: -240px;
    left: 90px;
    background: radial-gradient(circle, {glow_color} 0%, rgba(0,0,0,0) 70%);
    pointer-events: none;
  }}
  .header {{
    position: absolute;
    top: 70px;
    left: 0;
    width: 100%;
    text-align: center;
    padding: 0 45px;
    z-index: 10;
  }}
  .brand-pill {{
    display: inline-flex;
    align-items: center;
    gap: 10px;
    padding: 8px 22px;
    background: rgba(255, 255, 255, 0.08);
    border: 1.5px solid {pill_border};
    border-radius: 30px;
    font-size: 19px;
    font-weight: 700;
    letter-spacing: 1.5px;
    text-transform: uppercase;
    color: {pill_text};
    backdrop-filter: blur(10px);
  }}
  .brand-pill img {{
    width: 24px;
    height: 24px;
    border-radius: 6px;
  }}
  h1 {{
    font-size: 58px;
    font-weight: 800;
    line-height: 1.15;
    letter-spacing: -1.2px;
    margin: 20px auto 12px auto;
    max-width: 960px;
    text-shadow: 0 4px 20px rgba(0,0,0,0.65);
  }}
  h1 span.highlight {{
    background: {highlight_gradient};
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }}
  p.sub {{
    font-size: 26px;
    font-weight: 500;
    line-height: 1.35;
    color: #A1A4B5;
    max-width: 860px;
    margin: 0 auto;
  }}

  /* Phone Mockup (FHD 9:16 balanced proportion) */
  .phone-wrap {{
    position: absolute;
    bottom: -60px;
    left: 50%;
    transform: translateX(-50%);
    width: 660px;
    height: 1360px;
    background: #171821;
    border-radius: 52px;
    padding: 10px;
    box-shadow: 0 35px 90px rgba(0, 0, 0, 0.9), 0 0 50px rgba(230, 0, 35, 0.18);
    border: 2.5px solid rgba(255, 255, 255, 0.18);
  }}
  .phone-inner {{
    width: 100%;
    height: 100%;
    border-radius: 42px;
    overflow: hidden;
    position: relative;
    background: #000;
  }}
  .app-screenshot {{
    width: 100%;
    height: 100%;
    object-fit: cover;
    object-position: top center;
    display: block;
  }}
</style>
</head>
<body>
  <div class="glow"></div>

  <div class="header">
    <div class="brand-pill">
      <img src="data:image/png;base64,{logo_b64}">
      <span>{pill_tag}</span>
    </div>
    <h1>{title_line1}<br><span class="highlight">{title_highlight}</span></h1>
    <p class="sub">{subtitle}</p>
  </div>

  <div class="phone-wrap">
    <div class="phone-inner">
      <img class="app-screenshot" src="data:image/png;base64,{b64_img}">
    </div>
  </div>
</body>
</html>"""

slides = [
    (
        "01_connect_pinterest",
        "Official Pinterest Integration",
        "Connect Pinterest Boards",
        "Into Daily Wallpapers",
        "Official OAuth 2.0 • Zero idle background battery drain",
        b64_login,
        False
    ),
    (
        "02_active_wallpaper",
        "Automatic Daily Sync",
        "Fresh Curated Pins",
        "Applied to Your Screen",
        "Auto-applies high-resolution Pinterest pins every morning",
        b64_active,
        False
    ),
    (
        "03_interactive_browser",
        "Instant Full-Screen Preview",
        "Swipe, Preview & Apply",
        "Directly in One Tap",
        "Seamlessly cycle through saved board pins and set targets",
        b64_browser,
        False
    ),
    (
        "04_board_management",
        "Multi-Device Ecosystem",
        "Assign Separate Boards",
        "For Phone & Windows PC",
        "Sync mobile and desktop independently from your Pinterest",
        b64_boards,
        False
    ),
    (
        "05_board_gallery",
        "Aesthetic Feed & History",
        "Visual Board Gallery",
        "With New & Seen Badges",
        "Browse all saved wallpapers in a rich masonry aesthetic grid",
        b64_gallery,
        False
    ),
    (
        "06_rotation_schedule",
        "Custom Rotation Engine",
        "Choose Your Schedule",
        "From 1 Hour to Daily",
        "Set custom change frequencies and exact daily sync times",
        b64_schedule,
        False
    ),
]

chrome_path = r'C:\Program Files\Google\Chrome\Application\chrome.exe'

print("Generating 1080x1920 Google Play Store screenshots from real app...")

for name, pill, line1, highlight, sub, b64_img, is_gold in slides:
    html_content = generate_html(pill, line1, highlight, sub, b64_img, is_gold)
    html_file = os.path.join(TEMPLATES_DIR, f"{name}.html")
    png_file = os.path.join(OUTPUT_DIR, f"{name}.png")
    
    with open(html_file, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    print(f"Rendering {name}.png...")
    cmd = [
        chrome_path,
        '--headless',
        '--no-sandbox',
        '--disable-gpu',
        '--window-size=1080,1920',
        f'--screenshot={png_file}',
        html_file
    ]
    subprocess.run(cmd, check=True)
    if os.path.exists(png_file):
        print(f"✓ Generated {name}.png ({os.path.getsize(png_file):,} bytes)")

print("\nAll real screenshots generated successfully at 1080x1920!")

