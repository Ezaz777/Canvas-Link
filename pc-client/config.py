"""
Configuration constants for the WallpaperSync PC client.
"""

import os

# =============================================================================
# API CONFIGURATION
# =============================================================================
# Replace this with your deployed Cloudflare Worker URL
API_BASE_URL = "https://wallpaper-sync-api.canvaslink.workers.dev"

# =============================================================================
# LOCAL PATHS
# =============================================================================
APP_DATA_DIR = os.path.join(os.getenv("APPDATA", ""), "Canvas Link")
TOKEN_FILE = os.path.join(APP_DATA_DIR, "token.json")
SETTINGS_FILE = os.path.join(APP_DATA_DIR, "settings.json")
WALLPAPER_DIR = os.path.join(APP_DATA_DIR, "wallpapers")
LOG_FILE = os.path.join(APP_DATA_DIR, "canvas_link.log")

# =============================================================================
# AUTH
# =============================================================================
LOCAL_AUTH_PORT = 9437
LOCAL_AUTH_HOST = "127.0.0.1"

# =============================================================================
# TASK SCHEDULER
# =============================================================================
TASK_NAME = "CanvasLink_DailyUpdate"
TASK_TIME = "09:00"  # Daily execution time (24h format)

# Ensure directories exist
os.makedirs(APP_DATA_DIR, exist_ok=True)
os.makedirs(WALLPAPER_DIR, exist_ok=True)
