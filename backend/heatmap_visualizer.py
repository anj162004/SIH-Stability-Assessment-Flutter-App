# =========================================
#   heatmap_visualizer.py
#   Combine crack mask + weak/safe points
# =========================================

import cv2
import numpy as np
import uuid
import os

RESULT_FOLDER = "results"
os.makedirs(RESULT_FOLDER, exist_ok=True)

def generate_heatmap(original, mask, weak_points, safe_points):
    """
    Creates a colored heatmap overlay + marks weak/safe locations
    """

    H, W = mask.shape
    heatmap = np.zeros((H, W, 3), dtype=np.uint8)

    # Heatmap color coding
    heatmap[mask >= 0.75] = (0, 0, 255)
    heatmap[(mask >= 0.45) & (mask < 0.75)] = (0, 255, 255)
    heatmap[(mask >= 0.20) & (mask < 0.45)] = (0, 255, 0)

    overlay = cv2.addWeighted(original, 0.6, heatmap, 0.4, 0)

    # Draw weak points
    for i, wp in enumerate(weak_points, start=1):
        cv2.circle(overlay, (wp["x"], wp["y"]), 12, (0, 0, 255), 3)
        cv2.putText(overlay, f"W{i}", (wp["x"] + 8, wp["y"] - 8),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)

    # Draw safe points
    for i, sp in enumerate(safe_points, start=1):
        cv2.circle(overlay, (sp["x"], sp["y"]), 12, (0, 255, 0), 3)
        cv2.putText(overlay, f"S{i}", (sp["x"] + 8, sp["y"] - 8),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)

    # Save file
    file_id = uuid.uuid4().hex
    file_name = f"final_heatmap_{file_id}.png"
    full_path = os.path.join(RESULT_FOLDER, file_name)
    cv2.imwrite(full_path, overlay)

    return full_path
