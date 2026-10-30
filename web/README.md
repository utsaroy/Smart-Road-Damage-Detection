# 🛣️ Road Hazard & Pothole DSS - Authority Web Portal

A PHP web application for Road and Highway Authorities to monitor, inspect, and manage road hazards and pothole detections transmitted automatically from the YOLOv8 Android mobile scanner app.

---

## 🌟 Key Features

1. **Authority Management Dashboard (`index.php`)**:
   - **Real-Time KPI Cards**: Total detected hazards, High/Critical count, Pending inspection, In-progress repairs, and Resolved cases.
   - **Live GIS Map (Leaflet)**: Real-time map pins colored by severity (Red for High/Critical with pulsing radar ring, Orange for Medium, Yellow for Low, Green for Resolved).
   - **Pothole Database Table**: Real-time search by Report ID, Road, or District, filter by Severity and Status, and export to CSV.
   - **Detailed Hazard Inspection Modal**: Matches the Android app UI screen:
     - Captured camera image with detected defect labels
     - AI Detection Metrics (Confidence %, Severity, Total Defects, Inference time)
     - Hazards breakdown list (Surface coverage %, Confidence % for each hazard)
     - GPS coordinates with direct "Open in Google Maps" link
     - Authority Action Panel: Change status (`Pending` &rarr; `Verified` &rarr; `Assigned` &rarr; `Under Repair` &rarr; `Resolved`), assign maintenance crew, schedule repair date, and log notes.

2. **Automated Android Ingestion API (`POST /api/report_hazard.php`)**:
   - Stores live detection reports and camera photos transmitted from the Android phone automatically into the database.

---

## 🚀 Running the Authority Dashboard

Run in PowerShell or Command Prompt:
```bash
php -S 0.0.0.0:8000 -t "c:\Users\munem\Desktop\Path Hole Detection\php_portal"
```
Then open:
👉 **[http://localhost:8000](http://localhost:8000)**

*(Or via your phone on the same Wi-Fi: `http://192.168.0.107:8000`)*
