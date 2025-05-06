#!/bin/bash

echo "Written for my autistic dispatcher with love by Colby & a LLM controlled by the CCP"



# ========== SYSTEM PREP ==========
echo "[*] Installing required system packages..."
sudo apt update
sudo apt install -y python3 python3-venv python3-tk

# ========== VENV SETUP ==========
echo "[*] Creating Python virtual environment..."
python3 -m venv farmingdale-env
source farmingdale-env/bin/activate

# ========== PYTHON DEPENDENCIES ==========
echo "[*] Installing Python dependencies..."
pip install --upgrade pip
pip install playwright

echo "[*] Installing Playwright browser..."
python3 -m playwright install chromium

# ========== WRITE PYTHON SCRIPT ==========
echo "[*] Writing Python GUI script..."
cat > farmingdale_live.py << 'EOF'
from playwright.sync_api import sync_playwright
import tkinter as tk

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
    print("\n=========== RAW SCRAPED TEXT ===========")
    for i, line in enumerate(lines):
        print(f"{i}: {line}")
    print("========================================\n")

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
    raw_text = fetch_train_info()
    arrival, destination, train_number = parse_train_data(raw_text)
    time_label.config(text=f"Arrival Time: {arrival}")
    destination_label.config(text=f"Destination: {destination}")
    train_number_label.config(text=f"Train Status: {train_number}")
    root.after(60000, update_display)

root = tk.Tk()
root.title("Next LIRR Train at Farmingdale")
root.geometry("800x300")

time_label = tk.Label(root, text="Arrival Time: ", font=("Helvetica", 32))
time_label.pack(pady=10)

destination_label = tk.Label(root, text="Destination:", font=("Helvetica", 32))
destination_label.pack(pady=10)

train_number_label = tk.Label(root, text="Train Status:", font=("Helvetica", 32))
train_number_label.pack(pady=10)

update_display()
root.mainloop()
EOF

chmod +x farmingdale_live.py

# ========== RUN APP ==========
echo "[*] Launching the Farmingdale Train Display..."
python3 farmingdale_live.py
