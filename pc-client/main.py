"""
WallpaperSync PC Client — Main Entry Point

A background Windows app that syncs a daily Pinterest wallpaper
from your subscribed board to your desktop.

Usage:
  python main.py             Interactive mode (first-time setup + sync)
  python main.py --sync      Silent sync mode (for scheduled task)
  python main.py --login     Force re-login
  python main.py --install   Install scheduled task
  python main.py --uninstall Remove scheduled task
  python main.py --logout    Clear stored credentials
"""

import argparse
import logging
import os
import sys

from config import LOG_FILE, APP_DATA_DIR
from auth import login, load_token, clear_token, is_logged_in
from wallpaper import sync_wallpaper
from scheduler import install_scheduled_task, uninstall_scheduled_task, is_task_installed


def setup_logging():
    """Configure logging to file and console."""
    os.makedirs(APP_DATA_DIR, exist_ok=True)

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
        handlers=[
            logging.FileHandler(LOG_FILE, encoding="utf-8"),
            logging.StreamHandler(sys.stdout),
        ],
    )


def main():
    setup_logging()
    logger = logging.getLogger("WallpaperSync")

    parser = argparse.ArgumentParser(
        description="WallpaperSync — Daily Pinterest wallpaper sync for Windows"
    )
    parser.add_argument("--sync", action="store_true", help="Run a silent wallpaper sync")
    parser.add_argument("--login", action="store_true", help="Force re-login")
    parser.add_argument("--logout", action="store_true", help="Clear stored credentials")
    parser.add_argument("--install", action="store_true", help="Install daily scheduled task")
    parser.add_argument("--uninstall", action="store_true", help="Remove scheduled task")
    args = parser.parse_args()

    # Handle logout
    if args.logout:
        clear_token()
        print("✅ Logged out. Credentials cleared.")
        return

    # Handle uninstall
    if args.uninstall:
        uninstall_scheduled_task()
        return

    # Handle install
    if args.install:
        install_scheduled_task()
        return

    # Handle silent sync mode (used by scheduled task)
    if args.sync:
        token = load_token()
        if not token:
            logger.error("No token found. Please run the app interactively first to log in.")
            return
        sync_wallpaper(token)
        return

    # =========================================================================
    # INTERACTIVE MODE (first-time setup)
    # =========================================================================
    print()
    print("╔══════════════════════════════════════════╗")
    print("║       🖼️  WallpaperSync for Windows       ║")
    print("║     Daily Pinterest Wallpaper Magic      ║")
    print("╚══════════════════════════════════════════╝")
    print()

    # Step 1: Authentication
    if args.login or not is_logged_in():
        print("📋 Step 1: Log in with your Pinterest account\n")
        token = login()
        if not token:
            print("\n❌ Login failed. Please try again.")
            sys.exit(1)
    else:
        token = load_token()
        print("✅ Already logged in.\n")

    # Step 2: Sync wallpaper now
    print("📋 Step 2: Syncing today's wallpaper...\n")
    sync_wallpaper(token)

    # Step 3: Install scheduled task
    if not is_task_installed():
        print("\n📋 Step 3: Setting up daily automatic sync...\n")
        install_scheduled_task()
    else:
        print("\n✅ Daily sync is already configured.\n")

    print("\n🎉 Setup complete! Your wallpaper will update automatically every day.")
    print(f"   Wallpapers saved to: {os.path.abspath(APP_DATA_DIR)}")
    print(f"   Logs: {LOG_FILE}")
    print()


if __name__ == "__main__":
    main()
