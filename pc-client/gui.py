import tkinter as tk
from tkinter import messagebox, ttk
import threading
import sys
import os

from auth import is_logged_in, login, clear_token, load_token
from wallpaper import sync_wallpaper
from scheduler import install_scheduled_task, is_task_installed, uninstall_scheduled_task, get_sync_time, set_sync_time


class WallpaperSyncGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("WallpaperSync Settings")
        self.root.geometry("380x250")
        self.root.resizable(False, False)
        
        # Center the window
        self.root.eval('tk::PlaceWindow . center')

        # Status Label
        self.status_var = tk.StringVar()
        self.status_label = tk.Label(root, textvariable=self.status_var, font=("Segoe UI", 12))
        self.status_label.pack(pady=20)

        # Login/Logout Button
        self.auth_btn_text = tk.StringVar()
        self.auth_btn = tk.Button(root, textvariable=self.auth_btn_text, command=self.toggle_auth, width=20, font=("Segoe UI", 10))
        self.auth_btn.pack(pady=5)

        # Sync Button
        self.sync_btn = tk.Button(root, text="Sync Wallpaper Now", command=self.sync_now, width=20, font=("Segoe UI", 10))
        self.sync_btn.pack(pady=5)

        # Background Task Frame
        self.task_frame = tk.Frame(root)
        self.task_frame.pack(pady=15)

        self.task_var = tk.BooleanVar()
        self.task_checkbox = tk.Checkbutton(
            self.task_frame, text="Enable Daily Sync at", 
            variable=self.task_var, 
            command=self.toggle_task,
            font=("Segoe UI", 10)
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
        self.time_combo.pack(side=tk.LEFT, padx=5)
        self.time_combo.bind("<<ComboboxSelected>>", self.on_time_change)

        self.update_ui_state()

    def update_ui_state(self):
        logged_in = is_logged_in()
        if logged_in:
            self.status_var.set("Status: ✅ Logged In")
            self.auth_btn_text.set("Log Out")
            self.sync_btn.config(state=tk.NORMAL)
        else:
            self.status_var.set("Status: ❌ Not Logged In")
            self.auth_btn_text.set("Log In")
            self.sync_btn.config(state=tk.DISABLED)

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
