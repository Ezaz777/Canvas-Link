import tkinter as tk
from tkinter import messagebox, ttk
import threading
import sys
import os

from auth import is_logged_in, login, clear_token, load_token
from wallpaper import sync_wallpaper, skip_wallpaper_api
from scheduler import install_scheduled_task, is_task_installed, uninstall_scheduled_task, get_sync_time, set_sync_time


class WallpaperSyncGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Canvas Link | Pinterest Wallpaper Sync")
        self.root.geometry("400x380")
        self.root.resizable(False, False)
        
        # Pinterest Design System Colors
        self.bg_color = "#FBFBF9"      # Warm cream
        self.card_color = "#FFFFFF"    # White canvas card
        self.ink_color = "#111111"     # High-contrast ink
        self.mute_color = "#767676"    # Muted label
        self.primary_color = "#E60023" # Pinterest Red
        self.secondary_color = "#E5E5E0" # Pill secondary
        self.hairline_color = "#E5E5E0"

        self.root.configure(bg=self.bg_color)

        # Center the window
        self.root.eval('tk::PlaceWindow . center')

        # Header Frame with Pinterest Red Logo
        header_frame = tk.Frame(root, bg=self.bg_color)
        header_frame.pack(fill=tk.X, padx=24, pady=(20, 10))

        # Brand Badge (P)
        badge = tk.Label(
            header_frame, text="P", bg=self.primary_color, fg="#FFFFFF",
            font=("Segoe UI", 16, "bold"), width=2, height=1
        )
        badge.pack(side=tk.LEFT, padx=(0, 10))

        title_col = tk.Frame(header_frame, bg=self.bg_color)
        title_col.pack(side=tk.LEFT)

        app_title = tk.Label(
            title_col, text="Canvas Link", bg=self.bg_color, fg=self.ink_color,
            font=("Segoe UI", 14, "bold")
        )
        app_title.pack(anchor="w")

        app_sub = tk.Label(
            title_col, text="Daily Pinterest Wallpapers", bg=self.bg_color, fg=self.mute_color,
            font=("Segoe UI", 9)
        )
        app_sub.pack(anchor="w")

        # Status Card (White canvas card)
        status_card = tk.Frame(root, bg=self.card_color, highlightbackground=self.hairline_color, highlightthickness=1)
        status_card.pack(fill=tk.X, padx=24, pady=12, ipady=8)

        self.status_var = tk.StringVar()
        self.status_label = tk.Label(
            status_card, textvariable=self.status_var, bg=self.card_color, fg=self.ink_color,
            font=("Segoe UI", 10, "bold")
        )
        self.status_label.pack(pady=4)

        # Button Frame
        btn_frame = tk.Frame(root, bg=self.bg_color)
        btn_frame.pack(fill=tk.X, padx=24, pady=6)

        # Sync Button (Pinterest Red Primary CTA)
        self.sync_btn = tk.Button(
            btn_frame, text="Sync Wallpaper Now", command=self.sync_now,
            bg=self.primary_color, fg="#FFFFFF", activebackground="#B6001A", activeforeground="#FFFFFF",
            font=("Segoe UI", 10, "bold"), relief=tk.FLAT, bd=0, cursor="hand2", pady=8
        )
        self.sync_btn.pack(fill=tk.X, pady=4)

        # Skip Button (Secondary Pill)
        self.skip_btn = tk.Button(
            btn_frame, text="Skip Wallpaper", command=self.skip_now,
            bg=self.secondary_color, fg=self.ink_color, activebackground="#DADAD4",
            font=("Segoe UI", 10, "bold"), relief=tk.FLAT, bd=0, cursor="hand2", pady=7
        )
        self.skip_btn.pack(fill=tk.X, pady=4)

        # Login/Logout Button
        self.auth_btn_text = tk.StringVar()
        self.auth_btn = tk.Button(
            btn_frame, textvariable=self.auth_btn_text, command=self.toggle_auth,
            bg=self.secondary_color, fg=self.ink_color, activebackground="#DADAD4",
            font=("Segoe UI", 9, "bold"), relief=tk.FLAT, bd=0, cursor="hand2", pady=6
        )
        self.auth_btn.pack(fill=tk.X, pady=4)

        # Background Task Frame
        self.task_frame = tk.Frame(root, bg=self.bg_color)
        self.task_frame.pack(pady=(12, 16))

        self.task_var = tk.BooleanVar()
        self.task_checkbox = tk.Checkbutton(
            self.task_frame, text="Daily Sync at",
            variable=self.task_var,
            command=self.toggle_task,
            bg=self.bg_color, fg=self.ink_color, activebackground=self.bg_color,
            font=("Segoe UI", 10), selectcolor=self.card_color
        )
        self.task_checkbox.pack(side=tk.LEFT)

        # Time Dropdown
        self.time_var = tk.StringVar(value=get_sync_time())
        times = [f"{str(h).zfill(2)}:00" for h in range(24)]
        if self.time_var.get() not in times:
            times.append(self.time_var.get())

        self.time_combo = ttk.Combobox(
            self.task_frame, textvariable=self.time_var, values=times, width=6, state="readonly"
        )
        self.time_combo.pack(side=tk.LEFT, padx=6)
        self.time_combo.bind("<<ComboboxSelected>>", self.on_time_change)

        self.update_ui_state()

    def update_ui_state(self):
        logged_in = is_logged_in()
        if logged_in:
            self.status_var.set("Status: ✅ Logged In")
            self.auth_btn_text.set("Log Out")
            self.sync_btn.config(state=tk.NORMAL)
            self.skip_btn.config(state=tk.NORMAL)
        else:
            self.status_var.set("Status: ❌ Not Logged In")
            self.auth_btn_text.set("Log In")
            self.sync_btn.config(state=tk.DISABLED)
            self.skip_btn.config(state=tk.DISABLED)

        self.task_var.set(is_task_installed())

    def toggle_auth(self):
        if is_logged_in():
            clear_token()
            messagebox.showinfo("Logged Out", "You have been successfully logged out.")
            self.update_ui_state()
        else:
            # Login blocks until browser auth completes
            self.auth_btn.config(state=tk.DISABLED)
            self.status_var.set("Status: ⏳ Waiting for browser...")
            self.root.update()
            
            token = login()
            if token:
                messagebox.showinfo("Logged In", "Successfully logged in!")
                if not is_task_installed():
                    install_scheduled_task()
            else:
                messagebox.showerror("Login Failed", "Login timed out or failed. Please try again.")
            
            self.auth_btn.config(state=tk.NORMAL)
            self.update_ui_state()

    def sync_now(self):
        token = load_token()
        if not token:
            return
            
        self.sync_btn.config(state=tk.DISABLED)
        self.status_var.set("Status: ⏳ Syncing...")
        self.root.update()

        success = sync_wallpaper(token)
        if success:
            messagebox.showinfo("Success", "Wallpaper updated successfully!")
        else:
            messagebox.showerror("Error", "Failed to update wallpaper. Check the logs.")

        self.sync_btn.config(state=tk.NORMAL)
        self.skip_btn.config(state=tk.NORMAL)
        self.update_ui_state()

    def skip_now(self):
        token = load_token()
        if not token:
            return
            
        self.sync_btn.config(state=tk.DISABLED)
        self.skip_btn.config(state=tk.DISABLED)
        self.status_var.set("Status: ⏳ Skipping...")
        self.root.update()

        success = skip_wallpaper_api(token)
        if success:
            self.status_var.set("Status: ⏳ Syncing new wallpaper...")
            self.root.update()
            sync_success = sync_wallpaper(token)
            if sync_success:
                messagebox.showinfo("Success", "Wallpaper skipped and updated successfully!")
            else:
                messagebox.showerror("Error", "Skip successful, but failed to download new wallpaper.")
        else:
            messagebox.showerror("Error", "Failed to skip wallpaper. Check connection.")

        self.sync_btn.config(state=tk.NORMAL)
        self.skip_btn.config(state=tk.NORMAL)
        self.update_ui_state()

    def toggle_task(self):
        if self.task_var.get():
            install_scheduled_task()
            messagebox.showinfo("Task Enabled", f"Wallpaper will now automatically update daily at {self.time_var.get()}.")
        else:
            uninstall_scheduled_task()
            messagebox.showinfo("Task Disabled", "Automatic daily updates have been disabled.")

    def on_time_change(self, event=None):
        new_time = self.time_var.get()
        set_sync_time(new_time)
        # If task is enabled, re-install it with the new time
        if self.task_var.get():
            install_scheduled_task()


def run_gui():
    root = tk.Tk()
    app = WallpaperSyncGUI(root)
    root.mainloop()
