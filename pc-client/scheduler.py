"""
Windows Task Scheduler integration for WallpaperSync.
Registers a scheduled task that runs the .exe daily at login and at a set time.
"""

import logging
import os
import subprocess
import sys
import json

from config import TASK_NAME, TASK_TIME, SETTINGS_FILE

logger = logging.getLogger("WallpaperSync")


def get_sync_time() -> str:
    """Read the sync time from settings or return the default."""
    if os.path.exists(SETTINGS_FILE):
        try:
            with open(SETTINGS_FILE, "r") as f:
                data = json.load(f)
                return data.get("sync_time", TASK_TIME)
        except Exception:
            pass
    return TASK_TIME


def set_sync_time(time_str: str):
    """Save the sync time to settings."""
    data = {}
    if os.path.exists(SETTINGS_FILE):
        try:
            with open(SETTINGS_FILE, "r") as f:
                data = json.load(f)
        except Exception:
            pass
    data["sync_time"] = time_str
    try:
        with open(SETTINGS_FILE, "w") as f:
            json.dump(data, f)
    except Exception as e:
        logger.error(f"Failed to save settings: {e}")


def get_executable_path() -> tuple[str, str]:
    """Get the path to the current executable (or script in dev mode) and the arguments."""
    if getattr(sys, "frozen", False):
        # Running as a compiled .exe (PyInstaller)
        return sys.executable, ""
    else:
        # Check if compiled exe exists
        dist_exe = os.path.join(os.path.dirname(os.path.abspath(__file__)), "dist", "Canvas Link.exe")
        if os.path.exists(dist_exe):
            return dist_exe, ""
        # Running as a Python script (development)
        return sys.executable, f'"{os.path.abspath(sys.argv[0])}"'


def install_scheduled_task() -> bool:
    """
    Register a Windows Task Scheduler task that:
    1. Runs daily at the configured time
    2. Runs at user logon
    """
    exe_path, extra_args = get_executable_path()
    sync_time = get_sync_time()
    logger.info(f"Installing scheduled task: {TASK_NAME}")
    logger.info(f"Executable: {exe_path} {extra_args} at {sync_time}")

    try:
        # Delete existing task if present (ignore errors)
        subprocess.run(
            ["schtasks", "/Delete", "/TN", TASK_NAME, "/F"],
            capture_output=True,
            creationflags=subprocess.CREATE_NO_WINDOW,
        )

        # Create daily scheduled task
        task_cmd = f'"{exe_path}" {extra_args} --sync' if extra_args else f'"{exe_path}" --sync'
        
        result = subprocess.run(
            [
                "schtasks",
                "/Create",
                "/TN", TASK_NAME,
                "/TR", task_cmd,
                "/SC", "DAILY",
                "/ST", sync_time,
                "/F",
            ],
            capture_output=True,
            text=True,
            creationflags=subprocess.CREATE_NO_WINDOW,
        )

        if result.returncode == 0:
            # Enable "Run task as soon as possible after a scheduled start is missed"
            try:
                import tempfile
                query_res = subprocess.run(
                    ["schtasks", "/Query", "/TN", TASK_NAME, "/XML"],
                    capture_output=True,
                    text=True,
                    creationflags=subprocess.CREATE_NO_WINDOW,
                )
                xml = query_res.stdout
                
                # Ensure it runs on missed schedule
                if "<StartWhenAvailable>false</StartWhenAvailable>" in xml:
                    xml = xml.replace("<StartWhenAvailable>false</StartWhenAvailable>", "<StartWhenAvailable>true</StartWhenAvailable>")
                elif "<StartWhenAvailable>" not in xml:
                    xml = xml.replace("</Settings>", "  <StartWhenAvailable>true</StartWhenAvailable>\n  </Settings>")
                
                # Allow running on battery
                xml = xml.replace("<DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>", "<DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>")
                xml = xml.replace("<StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>", "<StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>")
                
                xml_path = os.path.join(tempfile.gettempdir(), f"{TASK_NAME}_temp.xml")
                with open(xml_path, "w", encoding="utf-16") as f:
                    f.write(xml)
                
                xml_result = subprocess.run(
                    ["schtasks", "/Create", "/TN", TASK_NAME, "/XML", xml_path, "/F"],
                    capture_output=True,
                    text=True,
                    creationflags=subprocess.CREATE_NO_WINDOW,
                )
                if os.path.exists(xml_path):
                    os.remove(xml_path)
                    
                if xml_result.returncode != 0:
                    logger.error(f"Failed to modify scheduled task XML: {xml_result.stderr}")
                    return False
            except Exception as e:
                logger.error(f"Failed to modify scheduled task XML to run on missed schedule: {e}")

            logger.info("Daily scheduled task created successfully.")
            return True
        else:
            logger.error(f"Failed to create scheduled task: {result.stderr}")
            return False

    except Exception as e:
        logger.error(f"Task scheduler error: {e}")
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
