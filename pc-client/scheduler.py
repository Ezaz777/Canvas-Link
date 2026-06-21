"""
Windows Task Scheduler integration for WallpaperSync.
Registers a scheduled task that runs the .exe daily at login and at a set time.
"""

import logging
import os
import subprocess
import sys

from config import TASK_NAME, TASK_TIME

logger = logging.getLogger("WallpaperSync")


def get_executable_path() -> str:
    """Get the path to the current executable (or script in dev mode)."""
    if getattr(sys, "frozen", False):
        # Running as a compiled .exe (PyInstaller)
        return sys.executable
    else:
        # Running as a Python script (development)
        return os.path.abspath(sys.argv[0])


def install_scheduled_task() -> bool:
    """
    Register a Windows Task Scheduler task that:
    1. Runs daily at the configured time
    2. Runs at user logon
    """
    exe_path = get_executable_path()
    logger.info(f"Installing scheduled task: {TASK_NAME}")
    logger.info(f"Executable: {exe_path}")

    try:
        # Delete existing task if present (ignore errors)
        subprocess.run(
            ["schtasks", "/Delete", "/TN", TASK_NAME, "/F"],
            capture_output=True,
            creationflags=subprocess.CREATE_NO_WINDOW,
        )

        # Create daily scheduled task
        result = subprocess.run(
            [
                "schtasks",
                "/Create",
                "/TN", TASK_NAME,
                "/TR", f'"{exe_path}" --sync',
                "/SC", "DAILY",
                "/ST", TASK_TIME,
                "/RL", "HIGHEST",
                "/F",
            ],
            capture_output=True,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW,
        )

        if result.returncode == 0:
            logger.info("Daily scheduled task created successfully.")
            print(f"✅ Scheduled task installed: runs daily at {TASK_TIME}")
            return True
        else:
            logger.error(f"Failed to create scheduled task: {result.stderr}")
            print(f"❌ Failed to install scheduled task: {result.stderr.strip()}")
            return False

    except Exception as e:
        logger.error(f"Task scheduler error: {e}")
        print(f"❌ Error installing scheduled task: {e}")
        return False


def uninstall_scheduled_task() -> bool:
    """Remove the scheduled task from Windows Task Scheduler."""
    try:
        result = subprocess.run(
            ["schtasks", "/Delete", "/TN", TASK_NAME, "/F"],
            capture_output=True,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW,
        )
        if result.returncode == 0:
            logger.info("Scheduled task removed successfully.")
            print("✅ Scheduled task removed.")
            return True
        else:
            logger.error(f"Failed to remove scheduled task: {result.stderr}")
            return False
    except Exception as e:
        logger.error(f"Task scheduler removal error: {e}")
        return False


def is_task_installed() -> bool:
    """Check if the scheduled task is currently registered."""
    try:
        result = subprocess.run(
            ["schtasks", "/Query", "/TN", TASK_NAME],
            capture_output=True,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW,
        )
        return result.returncode == 0
    except Exception:
        return False
