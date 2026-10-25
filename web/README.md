# AmarPath — Authority Road Hazard & Pothole Management Portal

The companion web management dashboard for **AmarPath (Smart Road Damage Detection System)**.

## Architecture
- **Companion Mobile App (Flutter & YOLOv8):** Citizens and road surveyors detect road defects on-device and upload captures to Supabase.
- **Supabase Cloud Backend:** Centralized PostgreSQL database (`public.damage_reports`) and Storage bucket (`road-hazards`).
- **Authority Web Dashboard (PHP, Leaflet, Tailwind CSS):** Real-time monitoring, defect severity triage, bounding box inspection, and crew assignment workflow.

## Key Features
- **Real-Time WebSocket Sync:** Powered by `@supabase/supabase-js`, new captures uploaded on the street appear on the dashboard instantly without page reloads.
- **AI Detection Overlays:** Normalized YOLOv8 bounding boxes are dynamically rendered over mobile field inspection photos.
- **Live GIS Hazard Mapping:** Interactive map powered by OpenStreetMap (OSM) standard, humanitarian, and cycling layers with Nominatim street search.
- **Civic Light Design System:** Modern, high-contrast, accessible interface designed for municipal road maintenance authorities.
