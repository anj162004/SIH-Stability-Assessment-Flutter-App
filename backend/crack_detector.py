# ============================================================
# crack_detector.py — Load TFLite Crack Detection Model & Predict
# ============================================================

import numpy as np
import tensorflow as tf
import cv2

# ------------------------------------------------------------
# 1️⃣ LOAD TFLITE MODEL
# ------------------------------------------------------------
def load_crack_model(model_path="crack_detector.tflite"):
    """
    Loads the TFLite crack detection model for inference.
    """

    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()

    print(f"🔥 TFLite crack detector loaded successfully: {model_path}")

    # Read input/output details once (for faster repeated inference)
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    return {
        "interpreter": interpreter,
        "input_details": input_details,
        "output_details": output_details
    }


# ------------------------------------------------------------
# 2️⃣ RUN INFERENCE ON A SINGLE PATCH (ANY INPUT SIZE → RESIZED)
# ------------------------------------------------------------
def predict_crack(model_data, patch):
    """
    Runs TFLite inference on a patch.
    Automatically resizes and fixes channels.
    """

    interpreter = model_data["interpreter"]
    input_details = model_data["input_details"]
    output_details = model_data["output_details"]

    # Expected input shape (1, H, W, C)
    _, H, W, C = input_details[0]["shape"]

    # Remove extra dims & resize
    patch_img = patch.squeeze()

    # Ensure image is 2D (if 3D, convert to grayscale)
    if patch_img.ndim == 3:
        patch_img = cv2.cvtColor(patch_img, cv2.COLOR_BGR2GRAY)

    patch_resized = cv2.resize(patch_img, (W, H))
    patch_resized = patch_resized.astype(np.float32) / 255.0

    # Expand to (H, W, 1)
    patch_resized = np.expand_dims(patch_resized, axis=-1)

    # If model expects 3 channels → stack grayscale → RGB
    if C == 3:
        patch_resized = np.repeat(patch_resized, 3, axis=-1)

    # Final shape → (1, H, W, C)
    patch_resized = np.expand_dims(patch_resized, axis=0)

    # Send to model
    interpreter.set_tensor(input_details[0]["index"], patch_resized)
    interpreter.invoke()

    # Output
    output = interpreter.get_tensor(output_details[0]["index"])
    mask = (output[0] > 0.5).astype(np.uint8)

    return mask.squeeze()
