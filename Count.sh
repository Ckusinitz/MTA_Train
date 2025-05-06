#!/bin/bash

echo "[*] Launching Farmingdale Train Display"
echo "[*] Setting up Python virtual environment..."

# Set up venv
python3 -m venv farmingdale-env
source farmingdale-env/bin/activate

echo "[*] Installing required Python packages..."
pip install --upgrade pip
pip install playwright
python3 -m playwright install chromium

echo "[*] Writing Python script..."
cat > farmingdale_live.py << 'EOF'
from playwright.sync_api import sync_playwright
import tkinter as tk

UPDATE_INTERVAL_MS = 60000
UPDATE_INTERVAL_SEC = UPDATE_INTERVAL_MS // 1000

def fetch_train_info():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto("https://traintime.mta.info/sign?code=FMD", timeout=60000)
        page.wait_for_timeout(5000)
        text = page.inner_text("body")
        browser.close()
        return text

def parse_train_data(raw_text):
    lines = [line.strip() for line in raw_text.splitlines() if line.strip()]
    try:
        time_index = lines.index("PLAT") + 1
        arrival_time = lines[time_index]
        destination = lines[time_index + 1]
        train_number = lines[time_index + 2]
        return arrival_time, destination, train_number
    except Exception as e:
        print(f"Parser error: {e}")
        return "N/A", "N/A", "N/A"

def update_display():
    global seconds_until_update
    raw_text = fetch_train_info()
    arrival, destination, train_number = parse_train_data(raw_text)
    time_label.config(text=f"Arrival Time: {arrival}")
    destination_label.config(text=f"Destination: {destination}")
    train_number_label.config(text=f"Train Status: {train_number}")
    seconds_until_update = UPDATE_INTERVAL_SEC
    root.after(UPDATE_INTERVAL_MS, update_display)

def countdown_timer():
    global seconds_until_update
    countdown_label.config(text=f"Next update in: {seconds_until_update}s")
    if seconds_until_update > 0:
        seconds_until_update -= 1
    root.after(1000, countdown_timer)

# GUI Setup
root = tk.Tk()
root.title("Next LIRR Train at Farmingdale")
root.geometry("800x300")
root.configure(bg="#f0f0f0")

# Main Labels
time_label = tk.Label(root, text="Arrival Time: ", font=("Helvetica", 32), bg="#f0f0f0")
time_label.pack(pady=10)

destination_label = tk.Label(root, text="Destination:", font=("Helvetica", 32), bg="#f0f0f0")
destination_label.pack(pady=10)

train_number_label = tk.Label(root, text="Train Status:", font=("Helvetica", 32), bg="#f0f0f0")
train_number_label.pack(pady=10)

# Countdown bottom-left
countdown_label = tk.Label(root, text="", font=("Helvetica", 12), bg="#f0f0f0", fg="#b0b0b0", anchor="w", justify="left")
countdown_label.pack(side="left", padx=15, pady=5)

# Credit bottom-right
credit_label = tk.Label(root, text="Made by Colby K", font=("Helvetica", 12), bg="#f0f0f0", fg="#a0a0a0", anchor="e", justify="right")
credit_label.pack(side="right", padx=15, pady=5)

# Start
seconds_until_update = UPDATE_INTERVAL_SEC
update_display()
countdown_timer()
root.mainloop()
EOF

echo "[*] Starting GUI..."
python3 farmingdale_live.py
