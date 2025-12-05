# ============================
#   app.py — SIH FINAL BACKEND
# ============================

from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import cv2
import numpy as np
import uuid
import os

from crack_detector import load_crack_model, predict_crack
from patch_utils import split_into_patches, stitch_patches
from postprocess import compute_damage_score, find_weak_point

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)

UPLOAD_FOLDER = "uploads/"
RESULT_FOLDER = "results/"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(RESULT_FOLDER, exist_ok=True)

# Load model once
model_data = load_crack_model("crack_detector.tflite")


# =================================================
@app.route("/results/<path:filename>")
def serve_results(filename):
    return send_from_directory(RESULT_FOLDER, filename)
# =================================================


@app.route("/predict", methods=["POST"])
def predict():

    # 1️⃣ RECEIVE IMAGE
    image_file = request.files["image"]
    img_id = str(uuid.uuid4())

    img_path = os.path.join(UPLOAD_FOLDER, f"{img_id}.jpg")
    image_file.save(img_path)

    original = cv2.imread(img_path)
    H, W = original.shape[:2]

    # 2️⃣ PREPROCESS
    gray = cv2.cvtColor(original, cv2.COLOR_BGR2GRAY)
    clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray)

    # 3️⃣ SPLIT INTO PATCHES
    patch_size = 64
    patches, positions = split_into_patches(enhanced, patch_size)

    # 4️⃣ MODEL + PIXEL MASK
    mask_patches = []

    for patch in patches:
        pnorm = np.expand_dims(patch / 255.0, axis=(0, -1)).astype(np.float32)
        pred = predict_crack(model_data, pnorm)
        score = float(np.squeeze(pred))

        edges = cv2.Canny(patch, 40, 120) / 255.0
        edges = cv2.dilate(edges, np.ones((5, 5)), iterations=1)

        pixel_mask = edges * score

        noise = np.random.normal(0, 0.04, (patch_size, patch_size))
        pixel_mask = np.clip(pixel_mask + noise, 0, 1)

        pixel_mask = cv2.GaussianBlur(pixel_mask.astype(np.float32), (7, 7), 1.5)

        mask_patches.append(pixel_mask)

    # 5️⃣ STITCH FULL MASK
    full_mask = stitch_patches(mask_patches, positions, (H, W), patch_size)
    full_mask = np.clip(full_mask, 0, 1)

    # Save segmentation mask
    seg_mask = (full_mask >= 0.7).astype(np.uint8)
    seg_file = f"mask_{img_id}.png"
    cv2.imwrite(os.path.join(RESULT_FOLDER, seg_file), seg_mask * 255)

    # 6️⃣ DAMAGE SCORE
    damage_score = compute_damage_score(full_mask)


    # ============================================================
    # 7️⃣ IMPROVED TRI-COLOR HEATMAP (VERY CLEAR GREEN & YELLOW)
    # ============================================================
    heatmap = np.zeros((H, W, 3), dtype=np.uint8)

    for y in range(H):
        for x in range(W):
            p = full_mask[y, x]

            if p >= 0.75:
                heatmap[y, x] = (0, 0, 255)               # RED (high)

            elif p >= 0.45:
                heatmap[y, x] = (0, 255, 255)             # BRIGHT YELLOW

            elif p >= 0.20:
                heatmap[y, x] = (0, 255, 0)               # BRIGHT GREEN

            else:
                heatmap[y, x] = (0, 0, 0)


    # ============================================================
    # 8️⃣ OVERLAY (balanced alpha — no more full red dominance)
    # ============================================================
    overlay = original.astype(np.float32)

    alpha_red = 0.55
    alpha_yellow = 0.45
    alpha_green = 0.40

    red_mask = (heatmap[:, :, 2] == 255)
    yellow_mask = (heatmap[:, :, 1] == 255) & (heatmap[:, :, 2] == 255)
    green_mask = (heatmap[:, :, 1] == 255) & (heatmap[:, :, 2] == 0)

    overlay[red_mask] = (
        alpha_red * np.array([0, 0, 255]) + (1 - alpha_red) * overlay[red_mask]
    )

    overlay[yellow_mask] = (
        alpha_yellow * np.array([0, 255, 255]) + (1 - alpha_yellow) * overlay[yellow_mask]
    )

    overlay[green_mask] = (
        alpha_green * np.array([0, 255, 0]) + (1 - alpha_green) * overlay[green_mask]
    )

    overlay = np.clip(overlay, 0, 255).astype(np.uint8)

    heatmap_file = f"heatmap_{img_id}.jpg"
    cv2.imwrite(os.path.join(RESULT_FOLDER, heatmap_file), overlay)


    # ============================================================
    # 9️⃣ WEAK POINT — HIGH VISIBILITY LABEL (WHITE+BLACK OUTLINE)
    # ============================================================
    weak_point = find_weak_point(full_mask)
    wx, wy = int(weak_point["x"]), int(weak_point["y"])

    marked = overlay.copy()

    # Red ring + black center
    cv2.circle(marked, (wx, wy), 22, (0, 0, 255), 4)
    cv2.circle(marked, (wx, wy), 7, (0, 0, 0), -1)

    # White text with black border (high visibility)
    cv2.putText(marked, "WEAK POINT", (wx + 20, wy - 20),
                cv2.FONT_HERSHEY_SIMPLEX, 1.0, (255, 255, 255), 3)  # White outline
    cv2.putText(marked, "WEAK POINT", (wx + 20, wy - 20),
                cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 0, 0), 1)        # Black border inside

    weak_overlay_file = f"weak_overlay_{img_id}.jpg"
    cv2.imwrite(os.path.join(RESULT_FOLDER, weak_overlay_file), marked)


    # ------- Zoom crop -------
    crop_radius = 130
    x1 = max(wx - crop_radius, 0)
    y1 = max(wy - crop_radius, 0)
    x2 = min(wx + crop_radius, W)
    y2 = min(wy + crop_radius, H)
    zoom_crop = original[y1:y2, x1:x2]

    weak_crop_file = f"weak_crop_{img_id}.jpg"
    cv2.imwrite(os.path.join(RESULT_FOLDER, weak_crop_file), zoom_crop)


    # ============================================================
    # 🔟 USER INPUT SCORING (same logic)
    # ============================================================
    age = float(request.form["age"])
    floors = float(request.form["floors"])
    height = float(request.form["height"])
    base = float(request.form["base"])
    material = request.form["material"]
    reinforcement = request.form["reinforcement"]

    gas = float(request.form["gas"])
    water = float(request.form["water"])
    electric = float(request.form["electric"])
    vibration = float(request.form["vibration"])

    A = 1.0 if age < 10 else 0.8 if age < 30 else 0.6
    material_scores = {"Steel": 1.0, "Reinforced Concrete": 0.9, "Brick": 0.6, "Wood": 0.4}
    M = material_scores.get(material, 0.7)
    L = 1.0 if floors <= 2 else 0.8 if floors <= 5 else 0.6
    G = 1 - ((height / base) / 10)
    R = {"Good": 1.0, "Average": 0.8, "Poor": 0.6}.get(reinforcement, 0.8)

    issues = sum([gas > 0.5, water > 0.5, electric < 0.5, vibration > 0.5])
    E = 1 - (issues * 0.1)

    baseScore = (
        0.2*M + 0.15*A + 0.15*G + 0.15*L +
        0.2*damage_score + 0.1*R + 0.05*E
    )

    correction = 1 - ((height / base) / 10)
    stability_score = max(0, min(baseScore * correction * 100, 100))

    return jsonify({
        "stability_score": stability_score,
        "damage_score": damage_score,
        "weak_point": weak_point,
        "mask_url": f"/results/{seg_file}",
        "heatmap_url": f"/results/{heatmap_file}",
        "weak_overlay_url": f"/results/{weak_overlay_file}",
        "weak_crop_url": f"/results/{weak_crop_file}",
        "suggestion": (
            "High risk. Immediate reinforcement needed."
            if stability_score < 50 else
            "Moderate risk. Monitor structure."
            if stability_score < 75 else
            "Structure stable."
        )
    })


# =================================================
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
