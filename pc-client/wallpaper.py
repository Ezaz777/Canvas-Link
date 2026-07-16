"""
Wallpaper module for WallpaperSync PC client.
Handles fetching, center-cropping, and applying wallpapers on Windows.
"""

import ctypes
import logging
import os
import sys
from datetime import date
from io import BytesIO

import time
import requests
from PIL import Image
from screeninfo import get_monitors

from config import API_BASE_URL, WALLPAPER_DIR

logger = logging.getLogger("WallpaperSync")

# Windows API constants
SPI_SETDESKWALLPAPER = 0x0014
SPIF_UPDATEINIFILE = 0x0001
SPIF_SENDWININICHANGE = 0x0002


def fetch_wallpaper_url(token: str) -> dict | None:
    """
    Call the /api/get-wallpaper endpoint to get today's wallpaper URL.
    Returns the response JSON or None on failure. Retries on network errors.
    """
    max_retries = 5
    for attempt in range(max_retries):
        try:
            response = requests.get(
                f"{API_BASE_URL}/api/get-wallpaper?device_type=desktop",
                headers={"Authorization": f"Bearer {token}"},
                timeout=30,
            )

            if response.status_code == 402:
                logger.warning("Subscription not active. Payment required.")
                return None

            if response.status_code == 401:
                logger.warning("Authentication token expired or invalid.")
                return None

            response.raise_for_status()
            data = response.json()
            logger.info(f"Received wallpaper: pin={data.get('pin_id')}, date={data.get('date')}, total_pins={data.get('total_pins')}")
            return data

        except requests.RequestException as e:
            logger.warning(f"Failed to fetch wallpaper URL (attempt {attempt + 1}/{max_retries}): {e}")
            if attempt < max_retries - 1:
                time.sleep(10)
    
    logger.error("Max retries reached. Failed to fetch wallpaper URL.")
    return None


def download_image(url: str) -> Image.Image | None:
    """Download an image from URL and return as a PIL Image."""
    try:
        response = requests.get(url, timeout=60, stream=True)
        response.raise_for_status()
        image = Image.open(BytesIO(response.content))
        logger.info(f"Downloaded image: {image.size[0]}x{image.size[1]}")
        return image
    except Exception as e:
        logger.error(f"Failed to download image: {e}")
        return None


def get_primary_monitor_resolution() -> tuple[int, int]:
    """
    Detect the primary monitor's resolution using screeninfo.
    Returns (width, height).
    """
    try:
        monitors = get_monitors()
        # Find primary monitor (usually the first one, or the one at 0,0)
        primary = None
        for m in monitors:
            if hasattr(m, "is_primary") and m.is_primary:
                primary = m
                break
        if primary is None:
            primary = monitors[0]

        logger.info(f"Primary monitor: {primary.width}x{primary.height}")
        return (primary.width, primary.height)
    except Exception as e:
        logger.warning(f"Failed to detect monitor resolution: {e}. Defaulting to 1920x1080.")
        return (1920, 1080)


def center_crop(image: Image.Image, target_width: int, target_height: int) -> Image.Image:
    """
    Center-crop an image to exactly match the target aspect ratio,
    then resize to the target resolution.

    This prevents stretching or distortion — the image is always sharp
    and fills the screen perfectly.
    """
    img_width, img_height = image.size
    
    is_source_landscape = img_width > img_height
    is_target_landscape = target_width > target_height
    
    # Auto-rotate if orientations don't match (e.g. portrait image on landscape screen)
    if is_source_landscape != is_target_landscape:
        logger.info("Orientation mismatch: Rotating image 90 degrees to fit screen better.")
        image = image.rotate(90, expand=True)
        img_width, img_height = image.size

    target_ratio = target_width / target_height
    img_ratio = img_width / img_height

    if img_ratio > target_ratio:
        # Image is wider than target — crop horizontally
        new_width = int(img_height * target_ratio)
        left = (img_width - new_width) // 2
        crop_box = (left, 0, left + new_width, img_height)
    else:
        # Image is taller than target — crop vertically
        new_height = int(img_width / target_ratio)
        top = (img_height - new_height) // 2
        crop_box = (0, top, img_width, top + new_height)

    cropped = image.crop(crop_box)

    # Resize to exact target resolution using high-quality resampling
    resized = cropped.resize((target_width, target_height), Image.Resampling.LANCZOS)

    logger.info(
        f"Center-cropped: {img_width}x{img_height} -> "
        f"crop({crop_box}) -> {target_width}x{target_height}"
    )
    return resized


def save_as_jpg(image: Image.Image, filename: str = None) -> str:
    """
    Save the image as a JPG file in the wallpaper directory.
    Modern Windows handles JPGs perfectly and they take up much less space.
    """
    if filename is None:
        filename = f"wallpaper_{date.today().isoformat()}.jpg"

    filepath = os.path.join(WALLPAPER_DIR, filename)

    # Convert to RGB if necessary (e.g., RGBA PNGs)
    if image.mode != "RGB":
        image = image.convert("RGB")

    image.save(filepath, "JPEG", quality=95)
    logger.info(f"Saved wallpaper to: {filepath}")
    return filepath


def apply_wallpaper(image_path: str) -> bool:
    """
    Apply an image as the Windows desktop wallpaper.
    Uses the modern IDesktopWallpaper COM interface (required for Windows 11),
    with a fallback to the legacy SystemParametersInfoW API.
    """
    if not os.path.exists(image_path):
        logger.error(f"Wallpaper file not found: {image_path}")
        return False

    abs_path = os.path.abspath(image_path)

    # Try the modern COM interface first (Windows 8+/11)
    try:
        import comtypes
        from comtypes import GUID, HRESULT, COMMETHOD
        from ctypes import wintypes

        CLSID_DesktopWallpaper = GUID('{C2CF3110-460E-4fc1-B9D0-8A1C0C9CC4BD}')
        IID_IDesktopWallpaper = GUID('{B92B56A9-8B55-4E14-9A89-0199BBB6F93B}')

        class IDesktopWallpaper(comtypes.IUnknown):
            _iid_ = IID_IDesktopWallpaper
            _methods_ = [
                COMMETHOD([], HRESULT, 'SetWallpaper',
                          (['in'], wintypes.LPCWSTR, 'monitorID'),
                          (['in'], wintypes.LPCWSTR, 'wallpaper')),
                COMMETHOD([], HRESULT, 'GetWallpaper',
                          (['in'], wintypes.LPCWSTR, 'monitorID'),
                          (['out'], ctypes.POINTER(wintypes.LPWSTR), 'wallpaper')),
            ]

        comtypes.CoInitialize()
        desktop_wallpaper = comtypes.CoCreateInstance(
            CLSID_DesktopWallpaper, interface=IDesktopWallpaper
        )
        desktop_wallpaper.SetWallpaper(None, abs_path)
        comtypes.CoUninitialize()

        logger.info(f"Wallpaper applied successfully (COM): {abs_path}")
        return True

    except Exception as e:
        logger.warning(f"COM wallpaper method failed: {e}. Trying legacy method...")

    # Fallback: legacy SystemParametersInfoW (older Windows)
    try:
        result = ctypes.windll.user32.SystemParametersInfoW(
            SPI_SETDESKWALLPAPER,
            0,
            abs_path,
            SPIF_UPDATEINIFILE | SPIF_SENDWININICHANGE,
        )

        if result:
            logger.info(f"Wallpaper applied successfully (legacy): {abs_path}")
            return True
        else:
            logger.error("SystemParametersInfoW returned False")
            return False
    except Exception as e:
        logger.error(f"Failed to apply wallpaper: {e}")
        return False


def cleanup_old_wallpapers(keep_days: int = 7):
    """Remove wallpaper files older than keep_days."""
    try:
        today = date.today()
        for filename in os.listdir(WALLPAPER_DIR):
            filepath = os.path.join(WALLPAPER_DIR, filename)
            if os.path.isfile(filepath):
                file_date_str = filename.replace("wallpaper_", "").replace(".jpg", "").replace(".bmp", "")
                try:
                    file_date = date.fromisoformat(file_date_str)
                    if (today - file_date).days > keep_days:
                        os.remove(filepath)
                        logger.info(f"Cleaned up old wallpaper: {filename}")
                except ValueError:
                    pass
    except Exception as e:
        logger.warning(f"Cleanup failed: {e}")


def sync_wallpaper(token: str) -> bool:
    """
    Full wallpaper sync pipeline:
    1. Fetch today's wallpaper URL from the API
    2. Download the image
    3. Detect monitor resolution
    4. Center-crop to match screen aspect ratio
    5. Save as BMP
    6. Apply as Windows desktop background
    7. Clean up old wallpapers
    """
    logger.info("Syncing wallpaper...")

    # 1. Fetch URL
    data = fetch_wallpaper_url(token)
    if not data:
        return False

    image_url = data.get("image_url")
    if not image_url:
        logger.error("No image_url in API response")
        return False

    # 2. Download
    image = download_image(image_url)
    if not image:
        return False

    # 3. Detect resolution
    screen_width, screen_height = get_primary_monitor_resolution()

    # 4. Center-crop
    cropped = center_crop(image, screen_width, screen_height)

    # 5. Save as JPG
    img_path = save_as_jpg(cropped)

    # 6. Apply
    success = apply_wallpaper(img_path)

    # 7. Cleanup
    cleanup_old_wallpapers()

    if success:
        logger.info(f"Wallpaper updated! (Pin: {data.get('pin_id', 'unknown')})")
    else:
        logger.error("Failed to apply wallpaper.")

    return success
