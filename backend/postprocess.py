# postprocess.py

import os
import cv2
import numpy as np

RESULT_FOLDER = "results"
os.makedirs(RESULT_FOLDER, exist_ok=True)


def build_probability_map(scores, positions, img_shape, patch_size=256):
    """
    scores:     list of floats in [0, 1], one per patch
    positions:  list of (y, x) for each patch
    img_shape:  (H, W)
    Returns:
        prob_map: (H, W) float32, values in [0, 1]
    """
    H, W = img_shape

    max_y = max([p[0] for p in positions])
    max_x = max([p[1] for p in positions])

    rows = (max_y // patch_size) + 1
    cols = (max_x // patch_size) + 1

    grid = np.zeros((rows, cols), dtype=np.float32)

    for score, (y, x) in zip(scores, positions):
        r = y // patch_size
        c = x // patch_size
        grid[r, c] = float(score)

    # Upsample grid to full resolution
    prob_map = cv2.resize(grid, (W, H), interpolation=cv2.INTER_CUBIC)

    # Smooth to get more pixel-like transitions
    prob_map = cv2.GaussianBlur(prob_map, (25, 25), 0)

    prob_map = np.clip(prob_map, 0.0, 1.0)

    return prob_map


def compute_damage_score(prob_map):
    """
    Aggregated damage score from pixel-wise probabilities.
    Output in [0, 1].
    """
    return float(np.mean(prob_map))


def generate_segmentation_mask(prob_map, img_id, threshold=0.5):
    """
    Binary crack mask: prob >= threshold => 255, else 0.
    Saves mask and returns filename & path.
    """
    seg = (prob_map >= threshold).astype(np.uint8) * 255

    mask_filename = f"mask_{img_id}.png"
    mask_path = os.path.join(RESULT_FOLDER, mask_filename)
    cv2.imwrite(mask_path, seg)

    return mask_filename, mask_path


def generate_heatmap(prob_map, original_bgr, img_id,
                     low_thr=0.3, high_thr=0.7):
    """
    Color heatmap over original image:
        < low_thr      -> green
        low_thr..high  -> yellow
        >= high_thr    -> red
    """
    H, W = prob_map.shape
    heatmap = np.zeros((H, W, 3), dtype=np.uint8)

    high = prob_map >= high_thr
    mid = (prob_map >= low_thr) & (prob_map < high_thr)
    low = prob_map < low_thr

    # BGR colors
    heatmap[low] = (0, 255, 0)       # green
    heatmap[mid] = (0, 255, 255)     # yellow
    heatmap[high] = (0, 0, 255)      # red

    # Blend with original image
    overlay = cv2.addWeighted(original_bgr, 0.6, heatmap, 0.4, 0)

    heatmap_filename = f"heatmap_{img_id}.png"
    heatmap_path = os.path.join(RESULT_FOLDER, heatmap_filename)
    cv2.imwrite(heatmap_path, overlay)

    return overlay, heatmap_path


def find_weak_point(prob_map):
    """
    Returns the pixel with maximum probability as 'weak point'.
    """
    idx = np.unravel_index(np.argmax(prob_map), prob_map.shape)
    y, x = int(idx[0]), int(idx[1])
    score = float(prob_map[y, x])
    return {"x": x, "y": y, "score": score}
