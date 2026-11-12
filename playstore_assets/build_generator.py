import base64
import os
import subprocess
import json

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
OUTPUT_DIR = os.path.join(BASE_DIR, 'output')
TEMPLATES_DIR = os.path.join(BASE_DIR, 'templates')
SOURCES_DIR = os.path.join(BASE_DIR, 'source_images')

os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(TEMPLATES_DIR, exist_ok=True)

# Helper to read base64
def get_b64(path):
    if not os.path.exists(path):
        return ""
    with open(path, 'rb') as f:
        return base64.b64encode(f.read()).decode('utf-8')

# Load Assets
logo_path = os.path.normpath(os.path.join(BASE_DIR, '..', 'mobile-client', 'assets', 'logo.png'))
logo_b64 = get_b64(logo_path)

tokyo_b64 = get_b64(os.path.join(SOURCES_DIR, 'tokyo_neon.jpg'))
nordic_b64 = get_b64(os.path.join(SOURCES_DIR, 'nordic_cozy.jpg'))
alpine_b64 = get_b64(os.path.join(SOURCES_DIR, 'alpine_dawn.jpg'))
seoul_b64 = get_b64(os.path.join(SOURCES_DIR, 'neo_seoul.jpg'))
sahara_b64 = get_b64(os.path.join(SOURCES_DIR, 'sahara_4k.jpg'))
ghibli_b64 = get_b64(os.path.join(SOURCES_DIR, 'ghibli_anime.jpg'))
cosmos_b64 = get_b64(os.path.join(SOURCES_DIR, 'cosmos_nebula.jpg'))
brutalist_b64 = get_b64(os.path.join(SOURCES_DIR, 'brutalist_arch.jpg'))

COMMON_HEAD = """
<meta charset="utf-8">
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    width: 1080px;
    height: 2400px;
    background: radial-gradient(circle at 50% 12%, #220910 0%, #111217 40%, #0a0b0e 100%);
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI Variable Display', 'Segoe UI', Roboto, sans-serif;
    color: #FFFFFF;
    position: relative;
    overflow: hidden;
  }
  .glow-top {
    position: absolute;
    width: 1000px;
    height: 1000px;
    top: -250px;
    left: 40px;
    background: radial-gradient(circle, rgba(230, 0, 35, 0.24) 0%, rgba(230, 0, 35, 0) 70%);
    pointer-events: none;
  }
  .header-container {
    position: absolute;
    top: 130px;
    left: 0;
    width: 100%;
    text-align: center;
    padding: 0 50px;
    z-index: 10;
  }
  .brand-badge {
    display: inline-flex;
    align-items: center;
    gap: 12px;
    padding: 10px 24px;
    background: rgba(255, 255, 255, 0.08);
    border: 1.5px solid rgba(255, 255, 255, 0.16);
    border-radius: 40px;
    font-size: 22px;
    font-weight: 700;
    letter-spacing: 2px;
    text-transform: uppercase;
    color: #FF5268;
    backdrop-filter: blur(10px);
  }
  .brand-badge img {
    width: 26px;
    height: 26px;
    border-radius: 6px;
  }
  h1 {
    font-size: 68px;
    font-weight: 800;
    line-height: 1.15;
    letter-spacing: -1.5px;
    margin: 28px auto 16px auto;
    max-width: 960px;
    text-shadow: 0 4px 24px rgba(0,0,0,0.6);
  }
  h1 span.highlight {
    background: linear-gradient(135deg, #FF455D 0%, #FF8A9A 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }
  h1 span.gold {
    background: linear-gradient(135deg, #FFD700 0%, #FFA500 100%);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }
  p.subtitle {
    font-size: 30px;
    font-weight: 500;
    line-height: 1.35;
    color: #A3A6B7;
    max-width: 880px;
    margin: 0 auto;
  }

  /* Standard Phone Frame */
  .phone-frame {
    position: absolute;
    bottom: -60px;
    left: 50%;
    transform: translateX(-50%);
    width: 780px;
    height: 1680px;
    background: #1C1E26;
    border-radius: 56px;
    padding: 12px;
    box-shadow: 0 40px 120px rgba(0, 0, 0, 0.85), 0 0 70px rgba(230, 0, 35, 0.16);
    border: 3px solid rgba(255, 255, 255, 0.16);
    z-index: 2;
  }
  .phone-screen {
    width: 100%;
    height: 100%;
    border-radius: 44px;
    position: relative;
    overflow: hidden;
  }
  .punch-hole {
    position: absolute;
    top: 18px;
    left: 50%;
    transform: translateX(-50%);
    width: 22px;
    height: 22px;
    background: #000000;
    border-radius: 50%;
    border: 1px solid rgba(255,255,255,0.15);
    z-index: 60;
  }
  .status-bar {
    position: absolute;
    top: 16px;
    left: 36px;
    right: 36px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 20px;
    font-weight: 600;
    color: #FFFFFF;
    z-index: 50;
  }
</style>
"""

# ==========================================
# SCREEN 1: HERO HOOK
# ==========================================
s1_html = f"""<!DOCTYPE html>
<html>
<head>
{COMMON_HEAD}
<style>
  .hero-screen {{
    background: url('data:image/jpeg;base64,{tokyo_b64}') center/cover no-repeat;
  }}
  .screen-overlay {{
    position: absolute;
    inset: 0;
    background: linear-gradient(180deg, rgba(0,0,0,0.45) 0%, rgba(0,0,0,0.1) 40%, rgba(0,0,0,0.7) 100%);
  }}
  .clock-widget {{
    position: absolute;
    top: 130px;
    left: 0;
    width: 100%;
    text-align: center;
    color: #FFFFFF;
  }}
  .clock-time {{ font-size: 102px; font-weight: 300; letter-spacing: -3px; }}
  .clock-date {{ font-size: 24px; font-weight: 500; opacity: 0.9; margin-top: 6px; }}

  .sync-card {{
    position: absolute;
    top: 520px;
    left: 34px;
    right: 34px;
    background: rgba(18, 20, 28, 0.84);
    border: 1.5px solid rgba(255, 255, 255, 0.2);
    backdrop-filter: blur(24px);
    border-radius: 28px;
    padding: 24px 28px;
    box-shadow: 0 20px 40px rgba(0,0,0,0.6);
    display: flex;
    align-items: center;
    gap: 20px;
  }}
  .sync-card img.logo {{
    width: 62px;
    height: 62px;
    border-radius: 16px;
    box-shadow: 0 4px 16px rgba(230, 0, 35, 0.4);
  }}
  .sync-info {{ flex: 1; }}
  .sync-title {{ font-size: 22px; font-weight: 700; color: #FFF; display: flex; align-items: center; gap: 10px; }}
  .sync-tag {{ background: #00E676; color: #000; font-size: 13px; font-weight: 800; padding: 3px 10px; border-radius: 8px; }}
  .sync-desc {{ font-size: 19px; color: #B4B7C5; margin-top: 6px; }}

  .app-dock {{
    position: absolute;
    bottom: 50px;
    left: 34px;
    right: 34px;
    height: 100px;
    background: rgba(255, 255, 255, 0.12);
    border: 1px solid rgba(255, 255, 255, 0.18);
    backdrop-filter: blur(20px);
    border-radius: 32px;
    display: flex;
    justify-content: space-around;
    align-items: center;
  }}
  .app-icon {{ width: 62px; height: 62px; border-radius: 18px; display: flex; align-items: center; justify-content: center; font-size: 28px; }}

  .floating-pill-left {{
    position: absolute;
    top: 660px;
    left: 36px;
    background: rgba(20, 22, 30, 0.92);
    border: 1.5px solid rgba(255, 255, 255, 0.22);
    border-radius: 40px;
    padding: 16px 28px;
    font-size: 23px;
    font-weight: 700;
    color: #FFF;
    box-shadow: 0 16px 36px rgba(0,0,0,0.7);
    z-index: 10;
  }}
  .floating-pill-right {{
    position: absolute;
    top: 980px;
    right: 36px;
    background: rgba(20, 22, 30, 0.92);
    border: 1.5px solid rgba(255, 255, 255, 0.22);
    border-radius: 40px;
    padding: 16px 28px;
    font-size: 23px;
    font-weight: 700;
    color: #FFF;
    box-shadow: 0 16px 36px rgba(0,0,0,0.7);
    z-index: 10;
  }}
</style>
</head>
<body>
  <div class="glow-top"></div>

  <div class="header-container">
    <div class="brand-badge">
      <img src="data:image/png;base64,{logo_b64}">
      <span>Pinterest Auto Wallpaper</span>
    </div>
    <h1>Turn Pinterest Boards<br>Into <span class="highlight">Daily Wallpapers</span></h1>
    <p class="subtitle">Auto-sync fresh high-definition pins directly to your screens</p>
  </div>

  <div class="floating-pill-left">
    <span>💎 Pure 4K CDN Quality</span>
  </div>

  <div class="floating-pill-right">
    <span>⚡ Zero Battery Drain</span>
  </div>

  <div class="phone-frame">
    <div class="phone-screen hero-screen">
      <div class="screen-overlay"></div>
      <div class="punch-hole"></div>
      <div class="status-bar">
        <span>09:41</span>
        <span>5G  ●  100%</span>
      </div>

      <div class="clock-widget">
        <div class="clock-time">09:41</div>
        <div class="clock-date">Sunday, November 7 • Tokyo</div>
      </div>

      <div class="sync-card">
        <img class="logo" src="data:image/png;base64,{logo_b64}">
        <div class="sync-info">
          <div class="sync-title">
            <span>Pinterest Auto Wallpaper Active</span>
            <span class="sync-tag">SYNCED</span>
          </div>
          <div class="sync-desc">Board: Tokyo Neon 4K • Direct Pin</div>
        </div>
      </div>

      <div class="app-dock">
        <div class="app-icon" style="background: #25D366;">📞</div>
        <div class="app-icon" style="background: #4285F4;">💬</div>
        <div class="app-icon" style="background: #E60023;">📌</div>
        <div class="app-icon" style="background: #34A853;">📷</div>
      </div>
    </div>
  </div>
</body>
</html>"""

# ==========================================
# SCREEN 2: CURATED AESTHETIC BOARDS
# ==========================================
s2_html = f"""<!DOCTYPE html>
<html>
<head>
{COMMON_HEAD}
<style>
  .dashboard-screen {{
    background: #121318;
    padding: 80px 24px 24px 24px;
    display: flex;
    flex-direction: column;
  }}
  .dash-header {{
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 24px;
  }}
  .dash-title {{ font-size: 32px; font-weight: 800; color: #FFF; }}
  .dash-sub {{ font-size: 18px; color: #8F92A2; margin-top: 4px; }}
  .search-bar {{
    background: rgba(255, 255, 255, 0.08);
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 18px;
    padding: 16px 20px;
    display: flex;
    align-items: center;
    gap: 12px;
    font-size: 19px;
    color: #8F92A2;
    margin-bottom: 26px;
  }}

  .boards-grid {{
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 18px;
  }}
  .board-card {{
    background: #1C1E26;
    border-radius: 24px;
    overflow: hidden;
    border: 2px solid rgba(255, 255, 255, 0.1);
    position: relative;
    box-shadow: 0 10px 24px rgba(0,0,0,0.4);
  }}
  .board-card.active {{
    border-color: #E60023;
  }}
  .board-thumb {{
    height: 340px;
    width: 100%;
    background-size: cover;
    background-position: center;
    position: relative;
  }}
  .board-thumb::after {{
    content: '';
    position: absolute;
    inset: 0;
    background: linear-gradient(180deg, rgba(0,0,0,0.1) 0%, rgba(0,0,0,0.85) 100%);
  }}
  .board-details {{
    position: absolute;
    bottom: 16px;
    left: 16px;
    right: 16px;
    z-index: 2;
  }}
  .board-name {{ font-size: 21px; font-weight: 800; color: #FFF; }}
  .board-meta {{ font-size: 16px; color: #DDD; margin-top: 4px; display: flex; justify-content: space-between; align-items: center; }}
  .board-badge {{ background: #E60023; color: #FFF; font-size: 12px; font-weight: 800; padding: 3px 8px; border-radius: 6px; }}

  /* Floating aesthetics tag pills */
  .tag-pill {{
    position: absolute;
    background: rgba(22, 24, 32, 0.94);
    border: 1.5px solid rgba(255, 255, 255, 0.2);
    border-radius: 36px;
    padding: 14px 26px;
    font-size: 22px;
    font-weight: 700;
    color: #FFF;
    box-shadow: 0 14px 32px rgba(0,0,0,0.7);
    z-index: 10;
  }}
</style>
</head>
<body>
  <div class="glow-top"></div>

  <div class="header-container">
    <div class="brand-badge">
      <img src="data:image/png;base64,{logo_b64}">
      <span>Curated Aesthetics</span>
    </div>
    <h1>Sync Any Aesthetic<br><span class="highlight">You Truly Love</span></h1>
    <p class="subtitle">Connect Anime, Cyberpunk, Cozy Minimalist & Nature boards</p>
  </div>

  <div class="tag-pill" style="top: 680px; left: 40px;">🌸 Studio Ghibli</div>
  <div class="tag-pill" style="top: 880px; right: 40px;">🏙️ Cyberpunk Neon</div>
  <div class="tag-pill" style="top: 1100px; left: 40px;">☕ Cozy Nordic</div>

  <div class="phone-frame">
    <div class="phone-screen dashboard-screen">
      <div class="punch-hole"></div>
      <div class="status-bar" style="top: 16px;">
        <span>09:41</span>
        <span>5G  ●  100%</span>
      </div>

      <div class="dash-header">
        <div>
          <div class="dash-title">Your Pinterest Boards</div>
          <div class="dash-sub">Select boards to auto-sync</div>
        </div>
        <div style="background: rgba(230,0,35,0.2); color: #FF5A6E; padding: 8px 16px; border-radius: 12px; font-size: 15px; font-weight: 700;">8 BOARDS</div>
      </div>

      <div class="search-bar">
        <span>🔍</span>
        <span>Search boards or aesthetics...</span>
      </div>

      <div class="boards-grid">
        <div class="board-card active">
          <div class="board-thumb" style="background-image: url('data:image/jpeg;base64,{ghibli_b64}');">
            <div class="board-details">
              <div class="board-name">Studio Ghibli 4K</div>
              <div class="board-meta">
                <span>148 pins</span>
                <span class="board-badge">SYNCING</span>
              </div>
            </div>
          </div>
        </div>

        <div class="board-card active">
          <div class="board-thumb" style="background-image: url('data:image/jpeg;base64,{seoul_b64}');">
            <div class="board-details">
              <div class="board-name">Tokyo Cyberpunk</div>
              <div class="board-meta">
                <span>320 pins</span>
                <span class="board-badge">SYNCING</span>
              </div>
            </div>
          </div>
        </div>

        <div class="board-card">
          <div class="board-thumb" style="background-image: url('data:image/jpeg;base64,{nordic_b64}');">
            <div class="board-details">
              <div class="board-name">Nordic Minimalist</div>
              <div class="board-meta">
                <span>94 pins</span>
                <span style="font-size: 13px; color: #AAA;">Tap to sync</span>
              </div>
            </div>
          </div>
        </div>

        <div class="board-card">
          <div class="board-thumb" style="background-image: url('data:image/jpeg;base64,{alpine_b64}');">
            <div class="board-details">
              <div class="board-name">Alpine Mountains</div>
              <div class="board-meta">
                <span>210 pins</span>
                <span style="font-size: 13px; color: #AAA;">Tap to sync</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</body>
</html>"""

# ==========================================
# SCREEN 3: SMART AUTO-CHANGER & ROTATION
# ==========================================
s3_html = f"""<!DOCTYPE html>
<html>
<head>
{COMMON_HEAD}
<style>
  .settings-screen {{
    background: #111218;
    padding: 80px 28px 28px 28px;
    display: flex;
    flex-direction: column;
  }}
  .panel-title {{ font-size: 30px; font-weight: 800; color: #FFF; }}
  .panel-sub {{ font-size: 18px; color: #8C8FA1; margin-top: 4px; margin-bottom: 28px; }}

  .freq-card {{
    background: #1A1C25;
    border: 2px solid rgba(255, 255, 255, 0.1);
    border-radius: 22px;
    padding: 22px 24px;
    margin-bottom: 18px;
    display: flex;
    align-items: center;
    justify-content: space-between;
  }}
  .freq-card.active {{
    background: rgba(230, 0, 35, 0.08);
    border-color: #E60023;
    box-shadow: 0 0 30px rgba(230, 0, 35, 0.25);
  }}
  .freq-left {{ display: flex; align-items: center; gap: 16px; }}
  .freq-icon {{
    width: 52px;
    height: 52px;
    background: rgba(255,255,255,0.08);
    border-radius: 14px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 26px;
  }}
  .freq-card.active .freq-icon {{
    background: #E60023;
  }}
  .freq-name {{ font-size: 22px; font-weight: 700; color: #FFF; }}
  .freq-desc {{ font-size: 16px; color: #8F92A2; margin-top: 4px; }}
  .pro-pill {{
    background: linear-gradient(135deg, #FFD700 0%, #FFA500 100%);
    color: #000;
    font-size: 13px;
    font-weight: 800;
    padding: 4px 10px;
    border-radius: 8px;
  }}

  /* Mini visual sequence showing cycle */
  .timeline-box {{
    background: rgba(255, 255, 255, 0.04);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 24px;
    padding: 24px;
    margin-top: 14px;
  }}
  .timeline-title {{ font-size: 19px; font-weight: 700; color: #FFF; margin-bottom: 18px; }}
  .timeline-row {{
    display: flex;
    justify-content: space-between;
    align-items: center;
  }}
  .timeline-item {{
    text-align: center;
    flex: 1;
  }}
  .timeline-thumb {{
    width: 140px;
    height: 240px;
    border-radius: 16px;
    margin: 0 auto 10px auto;
    background-size: cover;
    background-position: center;
    border: 2px solid rgba(255,255,255,0.15);
    box-shadow: 0 8px 20px rgba(0,0,0,0.5);
  }}
  .timeline-time {{ font-size: 16px; font-weight: 700; color: #FF5A6E; }}

  /* Floating battery badge */
  .battery-pill {{
    position: absolute;
    top: 660px;
    right: 40px;
    background: rgba(20, 22, 30, 0.94);
    border: 1.5px solid rgba(0, 230, 118, 0.5);
    border-radius: 36px;
    padding: 16px 28px;
    font-size: 22px;
    font-weight: 700;
    color: #00E676;
    box-shadow: 0 16px 36px rgba(0,0,0,0.7);
    z-index: 10;
  }}
</style>
</head>
<body>
  <div class="glow-top"></div>

  <div class="header-container">
    <div class="brand-badge">
      <img src="data:image/png;base64,{logo_b64}">
      <span>Smart Auto-Changer</span>
    </div>
    <h1>Fresh Screens All Day<br><span class="highlight">Automatically</span></h1>
    <p class="subtitle">Auto-cycle wallpapers every 1 hour, 6 hours, or daily</p>
  </div>

  <div class="battery-pill">
    <span>🔋 0% Battery Drain • WorkManager</span>
  </div>

  <div class="phone-frame">
    <div class="phone-screen settings-screen">
      <div class="punch-hole"></div>
      <div class="status-bar" style="top: 16px;">
        <span>09:41</span>
        <span>5G  ●  100%</span>
      </div>

      <div class="panel-title">Wallpaper Frequency</div>
      <div class="panel-sub">Choose how often your phone updates</div>

      <div class="freq-card active">
        <div class="freq-left">
          <div class="freq-icon">⏱️</div>
          <div>
            <div class="freq-name">Every 1 Hour</div>
            <div class="freq-desc">Rapid fresh rotation throughout the day</div>
          </div>
        </div>
        <div class="pro-pill">ACTIVE</div>
      </div>

      <div class="freq-card">
        <div class="freq-left">
          <div class="freq-icon">🔄</div>
          <div>
            <div class="freq-name">Every 6 Hours</div>
            <div class="freq-desc">Morning, Afternoon, Evening vibes</div>
          </div>
        </div>
        <div class="pro-pill" style="background: rgba(255,255,255,0.1); color: #AAA;">SELECT</div>
      </div>

      <div class="freq-card">
        <div class="freq-left">
          <div class="freq-icon">☀️</div>
          <div>
            <div class="freq-name">Daily (24 Hours)</div>
            <div class="freq-desc">Sync new pin every morning at 08:00 AM</div>
          </div>
        </div>
        <span style="color: #666; font-size: 24px;">›</span>
      </div>

      <div class="timeline-box">
        <div class="timeline-title">Upcoming Wallpaper Rotation</div>
        <div class="timeline-row">
          <div class="timeline-item">
            <div class="timeline-thumb" style="background-image: url('data:image/jpeg;base64,{tokyo_b64}');"></div>
            <div class="timeline-time">09:00 AM</div>
          </div>
          <div style="font-size: 26px; color: #666;">➔</div>
          <div class="timeline-item">
            <div class="timeline-thumb" style="background-image: url('data:image/jpeg;base64,{seoul_b64}');"></div>
            <div class="timeline-time">10:00 AM</div>
          </div>
          <div style="font-size: 26px; color: #666;">➔</div>
          <div class="timeline-item">
            <div class="timeline-thumb" style="background-image: url('data:image/jpeg;base64,{ghibli_b64}');"></div>
            <div class="timeline-time">11:00 AM</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</body>
</html>"""

# ==========================================
# SCREEN 4: DUAL SCREEN FREEDOM
# ==========================================
s4_html = f"""<!DOCTYPE html>
<html>
<head>
{COMMON_HEAD}
<style>
  .dual-container {{
    position: absolute;
    bottom: -80px;
    left: 50%;
    transform: translateX(-50%);
    width: 980px;
    height: 1650px;
    display: flex;
    justify-content: center;
    gap: 30px;
  }}
  .mini-phone {{
    width: 460px;
    height: 1580px;
    background: #1C1E26;
    border-radius: 48px;
    padding: 10px;
    box-shadow: 0 35px 90px rgba(0, 0, 0, 0.85);
    border: 2.5px solid rgba(255, 255, 255, 0.16);
    position: relative;
  }}
  .mini-phone-screen {{
    width: 100%;
    height: 100%;
    border-radius: 38px;
    position: relative;
    overflow: hidden;
  }}
  .phone-label-badge {{
    position: absolute;
    top: 70px;
    left: 50%;
    transform: translateX(-50%);
    background: rgba(18, 20, 28, 0.88);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 20px;
    padding: 8px 20px;
    font-size: 18px;
    font-weight: 800;
    letter-spacing: 1.5px;
    text-transform: uppercase;
    color: #FFF;
    z-index: 10;
    backdrop-filter: blur(12px);
  }}

  /* Floating Dual Badge */
  .dual-toggle-badge {{
    position: absolute;
    top: 660px;
    left: 50%;
    transform: translateX(-50%);
    background: rgba(22, 24, 34, 0.94);
    border: 2px solid #E60023;
    border-radius: 40px;
    padding: 18px 36px;
    display: flex;
    align-items: center;
    gap: 16px;
    font-size: 24px;
    font-weight: 800;
    color: #FFF;
    box-shadow: 0 16px 40px rgba(230, 0, 35, 0.35);
    z-index: 20;
    white-space: nowrap;
  }}
</style>
</head>
<body>
  <div class="glow-top"></div>

  <div class="header-container">
    <div class="brand-badge">
      <img src="data:image/png;base64,{logo_b64}">
      <span>Dual Screen Independence</span>
    </div>
    <h1>Different Vibes For<br><span class="highlight">Home & Lock Screens</span></h1>
    <p class="subtitle">Set independent wallpapers or sync both simultaneously</p>
  </div>

  <div class="dual-toggle-badge">
    <span>🔒 Independent Targets: Active</span>
  </div>

  <div class="dual-container">
    <!-- Left Phone: Lock Screen -->
    <div class="mini-phone">
      <div class="phone-label-badge">LOCK SCREEN</div>
      <div class="mini-phone-screen" style="background: url('data:image/jpeg;base64,{cosmos_b64}') center/cover no-repeat;">
        <div class="punch-hole"></div>
        <div class="status-bar" style="top: 16px; left: 24px; right: 24px; font-size: 17px;">
          <span>09:41</span>
          <span>100%</span>
        </div>
        <div style="position: absolute; top: 160px; width: 100%; text-align: center;">
          <div style="font-size: 76px; font-weight: 300;">09:41</div>
          <div style="font-size: 20px; opacity: 0.8; margin-top: 6px;">Sunday, Nov 7</div>
        </div>
        <div style="position: absolute; bottom: 120px; left: 24px; right: 24px; background: rgba(0,0,0,0.6); padding: 16px; border-radius: 20px; border: 1px solid rgba(255,255,255,0.15); text-align: center;">
          <div style="font-size: 16px; color: #AAA;">BOARD</div>
          <div style="font-size: 18px; font-weight: 700;">Deep Cosmos Nebula</div>
        </div>
      </div>
    </div>

    <!-- Right Phone: Home Screen -->
    <div class="mini-phone">
      <div class="phone-label-badge">HOME SCREEN</div>
      <div class="mini-phone-screen" style="background: url('data:image/jpeg;base64,{brutalist_b64}') center/cover no-repeat;">
        <div class="punch-hole"></div>
        <div class="status-bar" style="top: 16px; left: 24px; right: 24px; font-size: 17px;">
          <span>09:41</span>
          <span>5G</span>
        </div>
        <div style="position: absolute; top: 180px; left: 24px; right: 24px; background: rgba(255,255,255,0.15); padding: 14px 20px; border-radius: 24px; backdrop-filter: blur(10px); display: flex; align-items: center; gap: 10px;">
          <span>🔍</span>
          <span style="font-size: 17px; color: #DDD;">Search apps...</span>
        </div>
        <div style="position: absolute; bottom: 120px; left: 24px; right: 24px; background: rgba(0,0,0,0.6); padding: 16px; border-radius: 20px; border: 1px solid rgba(255,255,255,0.15); text-align: center;">
          <div style="font-size: 16px; color: #AAA;">BOARD</div>
          <div style="font-size: 18px; font-weight: 700;">Brutalist Architecture</div>
        </div>
      </div>
    </div>
  </div>
</body>
</html>"""

# ==========================================
# SCREEN 5: TRUE 4K MASTER ORIGINAL QUALITY
# ==========================================
s5_html = f"""<!DOCTYPE html>
<html>
<head>
{COMMON_HEAD}
<style>
  .zoom-lens {{
    position: absolute;
    top: 480px;
    right: 60px;
    width: 360px;
    height: 360px;
    border-radius: 50%;
    border: 4px solid #FFD700;
    box-shadow: 0 0 60px rgba(255, 215, 0, 0.45), 0 20px 50px rgba(0,0,0,0.8);
    background: url('data:image/jpeg;base64,{sahara_b64}') 55% 45%/260% no-repeat;
    z-index: 30;
  }}
  .zoom-lens::after {{
    content: '';
    position: absolute;
    inset: 0;
    border-radius: 50%;
    box-shadow: inset 0 0 40px rgba(0,0,0,0.6);
  }}
  .zoom-crosshair {{
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    width: 40px;
    height: 40px;
    border: 2px dashed rgba(255, 215, 0, 0.8);
    border-radius: 50%;
  }}
  .zoom-badge {{
    position: absolute;
    bottom: -20px;
    left: 50%;
    transform: translateX(-50%);
    background: #000;
    border: 1.5px solid #FFD700;
    border-radius: 20px;
    padding: 6px 18px;
    font-size: 17px;
    font-weight: 800;
    color: #FFD700;
    white-space: nowrap;
  }}
  .floating-4k-card {{
    position: absolute;
    top: 680px;
    left: 40px;
    background: rgba(18, 20, 28, 0.92);
    border: 2px solid rgba(255, 215, 0, 0.4);
    border-radius: 32px;
    padding: 22px 30px;
    box-shadow: 0 16px 40px rgba(0,0,0,0.7);
    z-index: 20;
  }}
  .floating-4k-card .title {{ font-size: 26px; font-weight: 800; color: #FFF; }}
  .floating-4k-card .sub {{ font-size: 18px; color: #A5A8B8; margin-top: 6px; }}
</style>
</head>
<body>
  <div class="glow-top" style="background: radial-gradient(circle, rgba(255, 215, 0, 0.2) 0%, rgba(255, 215, 0, 0) 70%);"></div>

  <div class="header-container">
    <div class="brand-badge" style="color: #FFD700; border-color: rgba(255, 215, 0, 0.3);">
      <img src="data:image/png;base64,{logo_b64}">
      <span>Ultra High Definition</span>
    </div>
    <h1>Pure 4K Master<br><span class="gold">Original Resolution</span></h1>
    <p class="subtitle">Direct uncompressed pin quality straight from Pinterest CDN</p>
  </div>

  <div class="floating-4k-card">
    <div class="title">⚡ 3840 × 2160 UHD</div>
    <div class="sub">Direct CDN Source • Lossless</div>
  </div>

  <div class="phone-frame">
    <div class="phone-screen" style="background: url('data:image/jpeg;base64,{sahara_b64}') center/cover no-repeat;">
      <div class="punch-hole"></div>
      <div class="status-bar">
        <span>09:41</span>
        <span>5G  ●  100%</span>
      </div>

      <!-- Zoom Loupe Callout -->
      <div class="zoom-lens">
        <div class="zoom-crosshair"></div>
        <div class="zoom-badge">400% MACRO DETAIL</div>
      </div>
    </div>
  </div>
</body>
</html>"""

# ==========================================
# SCREEN 6: MULTI-DEVICE ECOSYSTEM (PC + PHONE)
# ==========================================
s6_html = f"""<!DOCTYPE html>
<html>
<head>
{COMMON_HEAD}
<style>
  .multi-device-wrap {{
    position: absolute;
    bottom: -60px;
    left: 50%;
    transform: translateX(-50%);
    width: 1040px;
    height: 1650px;
  }}
  .laptop-mockup {{
    position: absolute;
    top: 140px;
    left: 40px;
    width: 820px;
    height: 520px;
    background: #1A1C24;
    border-radius: 24px;
    padding: 14px;
    border: 3px solid rgba(255,255,255,0.18);
    box-shadow: 0 30px 80px rgba(0,0,0,0.85);
    z-index: 2;
  }}
  .laptop-screen {{
    width: 100%;
    height: 100%;
    border-radius: 14px;
    background: url('data:image/jpeg;base64,{tokyo_b64}') center/cover no-repeat;
    position: relative;
    overflow: hidden;
  }}
  .taskbar {{
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    height: 38px;
    background: rgba(18, 20, 26, 0.88);
    backdrop-filter: blur(12px);
    display: flex;
    justify-content: center;
    align-items: center;
    gap: 16px;
  }}
  .task-icon {{ width: 22px; height: 22px; border-radius: 6px; background: rgba(255,255,255,0.2); }}

  .phone-overlay {{
    position: absolute;
    bottom: 20px;
    right: 30px;
    width: 480px;
    height: 1050px;
    background: #1C1E26;
    border-radius: 46px;
    padding: 10px;
    box-shadow: 0 40px 100px rgba(0, 0, 0, 0.9), 0 0 60px rgba(230,0,35,0.25);
    border: 3px solid rgba(255, 255, 255, 0.22);
    z-index: 10;
  }}
  .phone-overlay-screen {{
    width: 100%;
    height: 100%;
    border-radius: 36px;
    background: url('data:image/jpeg;base64,{tokyo_b64}') center/cover no-repeat;
    position: relative;
    overflow: hidden;
  }}

  .sync-pulse-badge {{
    position: absolute;
    top: 680px;
    left: 40px;
    background: rgba(20, 22, 32, 0.94);
    border: 2px solid #E60023;
    border-radius: 36px;
    padding: 18px 30px;
    font-size: 23px;
    font-weight: 800;
    color: #FFF;
    box-shadow: 0 16px 40px rgba(230, 0, 35, 0.35);
    z-index: 20;
    display: flex;
    align-items: center;
    gap: 12px;
  }}
</style>
</head>
<body>
  <div class="glow-top"></div>

  <div class="header-container">
    <div class="brand-badge">
      <img src="data:image/png;base64,{logo_b64}">
      <span>Cross-Device Ecosystem</span>
    </div>
    <h1>Seamless Phone &<br><span class="highlight">Windows PC Sync</span></h1>
    <p class="subtitle">Auto-update your phone & desktop wallpapers in harmony</p>
  </div>

  <div class="sync-pulse-badge">
    <span>🔄 Real-time Windows + Android Sync</span>
  </div>

  <div class="multi-device-wrap">
    <!-- Windows Laptop -->
    <div class="laptop-mockup">
      <div class="laptop-screen">
        <div style="position: absolute; top: 16px; left: 16px; background: rgba(0,0,0,0.7); padding: 6px 14px; border-radius: 8px; font-size: 14px; font-weight: 700;">💻 Windows 11 Desktop Client</div>
        <div class="taskbar">
          <div class="task-icon" style="background: #0078D4;"></div>
          <div class="task-icon" style="background: #E60023;"></div>
          <div class="task-icon" style="background: #25D366;"></div>
          <div class="task-icon" style="background: #FFB900;"></div>
        </div>
      </div>
    </div>

    <!-- Phone Overlay -->
    <div class="phone-overlay">
      <div class="phone-overlay-screen">
        <div class="punch-hole"></div>
        <div class="status-bar" style="top: 14px; left: 24px; right: 24px; font-size: 16px;">
          <span>09:41</span>
          <span>5G</span>
        </div>
        <div style="position: absolute; bottom: 80px; left: 20px; right: 20px; background: rgba(0,0,0,0.65); border: 1px solid rgba(255,255,255,0.2); padding: 18px; border-radius: 20px; text-align: center;">
          <div style="font-size: 15px; color: #AAA;">SYNCHRONIZED</div>
          <div style="font-size: 19px; font-weight: 800; margin-top: 4px;">Tokyo Neon 4K</div>
        </div>
      </div>
    </div>
  </div>
</body>
</html>"""

# ==========================================
# SCREEN 7: INTERACTIVE GALLERY & 1-TAP APPLY
# ==========================================
s7_html = f"""<!DOCTYPE html>
<html>
<head>
{COMMON_HEAD}
<style>
  .apply-sheet {{
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    background: rgba(18, 20, 26, 0.92);
    border-top: 2px solid rgba(255, 255, 255, 0.18);
    backdrop-filter: blur(30px);
    border-radius: 40px 40px 0 0;
    padding: 36px 32px 60px 32px;
  }}
  .apply-title {{ font-size: 28px; font-weight: 800; color: #FFF; }}
  .apply-author {{ font-size: 18px; color: #8F92A2; margin-top: 4px; }}
  .chips-row {{
    display: flex;
    gap: 12px;
    margin: 24px 0;
  }}
  .chip {{
    flex: 1;
    background: rgba(255, 255, 255, 0.08);
    border: 1.5px solid rgba(255, 255, 255, 0.15);
    border-radius: 18px;
    padding: 14px;
    text-align: center;
    font-size: 18px;
    font-weight: 700;
    color: #FFF;
  }}
  .chip.active {{
    background: rgba(230, 0, 35, 0.2);
    border-color: #E60023;
    color: #FF5A6E;
  }}
  .apply-btn {{
    width: 100%;
    background: #E60023;
    color: #FFF;
    border: none;
    border-radius: 22px;
    padding: 22px;
    font-size: 24px;
    font-weight: 800;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 12px;
    box-shadow: 0 10px 30px rgba(230, 0, 35, 0.5);
  }}

  .swipe-pill {{
    position: absolute;
    top: 660px;
    left: 40px;
    background: rgba(22, 24, 34, 0.94);
    border: 1.5px solid rgba(255, 255, 255, 0.22);
    border-radius: 36px;
    padding: 16px 28px;
    font-size: 22px;
    font-weight: 700;
    color: #FFF;
    box-shadow: 0 16px 36px rgba(0,0,0,0.7);
    z-index: 10;
  }}
</style>
</head>
<body>
  <div class="glow-top"></div>

  <div class="header-container">
    <div class="brand-badge">
      <img src="data:image/png;base64,{logo_b64}">
      <span>Effortless Control</span>
    </div>
    <h1>Browse, Swipe & Apply<br><span class="highlight">In Just One Tap</span></h1>
    <p class="subtitle">Interactive full-screen preview with zero compression</p>
  </div>

  <div class="swipe-pill">
    <span>👈 Swipe to Shuffle Pins 👉</span>
  </div>

  <div class="phone-frame">
    <div class="phone-screen" style="background: url('data:image/jpeg;base64,{seoul_b64}') center/cover no-repeat;">
      <div class="punch-hole"></div>
      <div class="status-bar">
        <span>09:41</span>
        <span>5G  ●  100%</span>
      </div>

      <div class="apply-sheet">
        <div style="width: 44px; height: 5px; background: rgba(255,255,255,0.25); border-radius: 10px; margin: 0 auto 20px auto;"></div>
        <div class="apply-title">Neo-Seoul Cyberpunk Passage</div>
        <div class="apply-author">By Min-Jun Kim • 4K Original</div>

        <div class="chips-row">
          <div class="chip">Lock Screen</div>
          <div class="chip">Home Screen</div>
          <div class="chip active">Both Screens</div>
        </div>

        <div class="apply-btn">
          <span>⚡ Apply Wallpaper Now</span>
        </div>
      </div>
    </div>
  </div>
</body>
</html>"""

# ==========================================
# SCREEN 8: PINTEREST AUTO WALLPAPER PRO (LIFETIME UNLOCK)
# ==========================================
s8_html = f"""<!DOCTYPE html>
<html>
<head>
{COMMON_HEAD}
<style>
  .pro-screen {{
    background: #121319;
    padding: 70px 28px 28px 28px;
    display: flex;
    flex-direction: column;
  }}
  .pro-badge-header {{
    align-self: center;
    background: linear-gradient(135deg, #FFD700 0%, #FFA500 100%);
    color: #000;
    font-size: 15px;
    font-weight: 800;
    letter-spacing: 1.5px;
    padding: 8px 20px;
    border-radius: 20px;
    display: flex;
    align-items: center;
    gap: 8px;
    box-shadow: 0 4px 20px rgba(255, 165, 0, 0.4);
    margin-bottom: 16px;
  }}
  .pro-h1 {{ font-size: 32px; font-weight: 800; text-align: center; color: #FFF; }}
  .pro-sub {{ font-size: 18px; color: #8F92A2; text-align: center; margin-top: 6px; margin-bottom: 30px; }}

  .feat-list {{ display: flex; flex-direction: column; gap: 16px; }}
  .feat-item {{
    background: rgba(255, 255, 255, 0.04);
    border: 1px solid rgba(255, 255, 255, 0.09);
    border-radius: 18px;
    padding: 16px 20px;
    display: flex;
    align-items: center;
    gap: 16px;
  }}
  .feat-icon {{
    width: 46px;
    height: 46px;
    background: rgba(255, 215, 0, 0.15);
    color: #FFD700;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 22px;
  }}
  .feat-text-title {{ font-size: 20px; font-weight: 700; color: #FFF; }}
  .feat-text-desc {{ font-size: 15px; color: #8F92A2; margin-top: 3px; }}

  .pro-btn {{
    margin-top: 30px;
    background: #E60023;
    color: #FFF;
    border-radius: 20px;
    padding: 22px;
    text-align: center;
    font-size: 23px;
    font-weight: 800;
    box-shadow: 0 10px 30px rgba(230, 0, 35, 0.5);
  }}

  .lifetime-pill {{
    position: absolute;
    top: 660px;
    right: 40px;
    background: rgba(22, 24, 34, 0.94);
    border: 2px solid #FFD700;
    border-radius: 36px;
    padding: 16px 28px;
    font-size: 22px;
    font-weight: 800;
    color: #FFD700;
    box-shadow: 0 16px 36px rgba(255, 215, 0, 0.3);
    z-index: 10;
  }}
</style>
</head>
<body>
  <div class="glow-top" style="background: radial-gradient(circle, rgba(255, 215, 0, 0.22) 0%, rgba(255, 215, 0, 0) 70%);"></div>

  <div class="header-container">
    <div class="brand-badge" style="color: #FFD700; border-color: rgba(255, 215, 0, 0.3);">
      <img src="data:image/png;base64,{logo_b64}">
      <span>Lifetime Value</span>
    </div>
    <h1>Unlock The Ultimate<br><span class="gold">Pinterest Auto Wallpaper Pro</span></h1>
    <p class="subtitle">One-time lifetime unlock • Rapid cycles • PC sync • No subscriptions</p>
  </div>

  <div class="lifetime-pill">
    <span>👑 Pay Once • Lifetime Updates</span>
  </div>

  <div class="phone-frame">
    <div class="phone-screen pro-screen">
      <div class="punch-hole"></div>
      <div class="status-bar" style="top: 16px;">
        <span>09:41</span>
        <span>5G  ●  100%</span>
      </div>

      <div class="pro-badge-header">
        <span>👑 PINTEREST AUTO WALLPAPER PRO</span>
      </div>
      <div class="pro-h1">Unlock Ultimate 4K</div>
      <div class="pro-sub">One-time payment. Zero recurring subscriptions.</div>

      <div class="feat-list">
        <div class="feat-item">
          <div class="feat-icon">⏱️</div>
          <div>
            <div class="feat-text-title">1-Hour & 6-Hour Rotations</div>
            <div class="feat-text-desc">Keep screens fresh all day automatically</div>
          </div>
        </div>

        <div class="feat-item">
          <div class="feat-icon">🔒</div>
          <div>
            <div class="feat-text-title">Lock Screen & Dual Sync</div>
            <div class="feat-text-desc">Set custom wallpapers on Home, Lock, or both</div>
          </div>
        </div>

        <div class="feat-item">
          <div class="feat-icon">💻</div>
          <div>
            <div class="feat-text-title">Windows PC Desktop Sync</div>
            <div class="feat-text-desc">Auto-sync Pinterest boards to your computer</div>
          </div>
        </div>

        <div class="feat-item">
          <div class="feat-icon">💎</div>
          <div>
            <div class="feat-text-title">Pure 4K Master Quality</div>
            <div class="feat-text-desc">Direct uncompressed pin resolution from CDN</div>
          </div>
        </div>
      </div>

      <div class="pro-btn">
        Unlock Pro for ₹199 (Lifetime)
      </div>
    </div>
  </div>
</body>
</html>"""

screens = [
    ('01_hero_hook', s1_html),
    ('02_curated_boards', s2_html),
    ('03_auto_changer', s3_html),
    ('04_dual_screen', s4_html),
    ('05_4k_ultra_hd', s5_html),
    ('06_phone_pc_sync', s6_html),
    ('07_instant_apply', s7_html),
    ('08_pinterest_auto_wallpaper_pro', s8_html),
]

chrome_path = r'C:\Program Files\Google\Chrome\Application\chrome.exe'

for name, html in screens:
    html_path = os.path.join(TEMPLATES_DIR, f"{name}.html")
    output_png = os.path.join(OUTPUT_DIR, f"{name}.png")
    
    with open(html_path, 'w', encoding='utf-8') as f:
        f.write(html)
    
    print(f"Rendering {name}.png...")
    cmd = [
        chrome_path,
        '--headless',
        '--no-sandbox',
        '--disable-gpu',
        '--window-size=1080,2400',
        f'--screenshot={output_png}',
        html_path
    ]
    subprocess.run(cmd, check=True)
    if os.path.exists(output_png):
        print(f"✓ Generated {name}.png ({os.path.getsize(output_png):,} bytes)")

print("\nAll 8 Play Store screenshot graphics successfully generated!")

