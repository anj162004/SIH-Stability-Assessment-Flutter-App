# beam_visualizer.py — draws beam/column markers on image

import cv2
import os
import uuid

RESULT_FOLDER = "results"

def draw_structure_overlay(image_path, beams, columns):
    img = cv2.imread(image_path)

    if img is None:
        return None

    # Draw beams (blue)
    for b in beams:
        x, y = int(b["x"]), int(b["y"])
        cv2.circle(img, (x, y), 10, (255, 0, 0), 3)
        cv2.putText(img, "B", (x + 5, y - 5),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 0, 0), 2)

    # Draw columns (yellow)
    for c in columns:
        x, y = int(c["x"]), int(c["y"])
        cv2.circle(img, (x, y), 10, (0, 255, 255), 3)
        cv2.putText(img, "C", (x + 5, y - 5),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)

    # Save output
    filename = f"overlay_{uuid.uuid4().hex}.jpg"
    out_path = os.path.join(RESULT_FOLDER, filename)
    cv2.imwrite(out_path, img)

    return out_path