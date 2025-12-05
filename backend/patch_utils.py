import numpy as np

# =====================================================================
# Split image into non-overlapping patches (used for TFLite inference)
# =====================================================================
def split_into_patches(image, patch_size):
    """
    Returns:
        - patches: list of 2D numpy arrays
        - positions: list of (y, x) coordinates for stitching
    """
    H, W = image.shape
    patches = []
    positions = []

    for y in range(0, H, patch_size):
        for x in range(0, W, patch_size):
            patch = image[y:y+patch_size, x:x+patch_size]

            # pad border patches
            if patch.shape[0] != patch_size or patch.shape[1] != patch_size:
                padded = np.zeros((patch_size, patch_size), dtype=np.uint8)
                padded[:patch.shape[0], :patch.shape[1]] = patch
                patch = padded

            patches.append(patch)
            positions.append((y, x))

    return patches, positions


# =====================================================================
# Stitch 2D probability patches into final full probability map
# =====================================================================
def stitch_patches(probability_patches, positions, full_shape, patch_size):
    H, W = full_shape
    full_map = np.zeros((H, W), dtype=np.float32)
    weight_map = np.zeros((H, W), dtype=np.float32)

    # Gaussian kernel
    ax = np.linspace(-1, 1, patch_size)
    xx, yy = np.meshgrid(ax, ax)
    gaussian = np.exp(-(xx**2 + yy**2))

    for patch, (y, x) in zip(probability_patches, positions):
        h = min(patch_size, H - y)
        w = min(patch_size, W - x)

        # clip to real region
        p_clip = patch[:h, :w]
        g_clip = gaussian[:h, :w]

        full_map[y:y+h, x:x+w] += p_clip * g_clip
        weight_map[y:y+h, x:x+w] += g_clip

    weight_map[weight_map == 0] = 1e-6
    return full_map / weight_map
