# Structural Stability Assessment Tool (Flutter + Flask)

This project was developed as part of **Smart India Hackathon (SIH)** to assess the
structural stability of buildings damaged due to natural disasters such as earthquakes,
cyclones, and collapses. The system integrates a **Flutter-based mobile interface**
with a **Python Flask backend** to analyze images, sensor data, and structural indicators
to assist rescue and inspection teams.

---

## 🔍 Key Features

- **Flutter Mobile Application**
  - Image capture & upload (aerial and side views)
  - Offline-first design with local data persistence
  - Interactive map visualization using OpenStreetMap (`flutter_map`)
  - Multi-screen workflow for image upload, sensor input, and results

- **Backend Processing (Flask)**
  - Crack detection using patch-based image analysis
  - Heatmap visualization of crack severity using OpenCV
  - Beam and column localization with structural overlays
  - Sensor-based hazard detection (gas leak, temperature, voltage)
  - Final structural stability classification: *Safe / Caution / Weak / Critical*

- **Machine Learning**
  - TensorFlow Lite models for lightweight inference
  - Image-based damage scoring
  - Risk aggregation from visual + sensor data

---

## 🛠️ Tech Stack

**Frontend**
- Flutter (Dart)
- flutter_map (OpenStreetMap)
- Image Picker
- REST API integration

**Backend**
- Python
- Flask + Flask-CORS
- NumPy, OpenCV, Pandas
- TensorFlow Lite

---

## 🚀 How to Run (Prototype)

### Flutter App
```bash
flutter pub get
flutter run
