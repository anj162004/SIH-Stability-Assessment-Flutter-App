import numpy as np
import cv2
import tensorflow as tf


def load_structure_model(model_path="mobilenetv2_building.tflite"):
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    print("✅ Structure model loaded:", model_path)
    return interpreter


def predict_structure(interpreter, image_bgr):
    """
    SAFE VERSION — will NEVER crash.
    Handles ANY shape of model output.
    Returns empty beams/columns if model is not a detection model.
    """

    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    H, W = image_bgr.shape[:2]
    inp_h, inp_w = input_details[0]["shape"][1], input_details[0]["shape"][2]

    # Preprocess
    img = cv2.resize(image_bgr, (inp_w, inp_h))
    img = img.astype(np.float32) / 255.0
    img = np.expand_dims(img, axis=0)

    interpreter.set_tensor(input_details[0]["index"], img)
    interpreter.invoke()

    # Raw predictions
    preds = interpreter.get_tensor(output_details[0]["index"])

    print("\n🔍 Structure model raw output:", preds)

    # ----------------------------------------------------------
    # CHECK 1 — if output is None or empty → skip
    # ----------------------------------------------------------
    if preds is None:
        print("⚠ Model returned None → No beam/column detected")
        return {"beams": [], "columns": []}

    if preds.size == 0:
        print("⚠ Empty output → No beam/column detected")
        return {"beams": [], "columns": []}

    # ----------------------------------------------------------
    # CHECK 2 — If model output is NOT Nx3 → NOT a detection model
    # ----------------------------------------------------------
    if preds.ndim != 3 or preds.shape[-1] != 3:
        print(f"⚠ Structure model output shape {preds.shape} is NOT coordinate format")
        print("   → Returning empty beams/columns safely.\n")
        return {"beams": [], "columns": []}

    # If valid shape -> extract
    preds = preds[0]  # shape: (N,3)

    beams = []
    columns = []

    for px, py, cls in preds:
        # Normalize
        x = int(px * W)
        y = int(py * H)

        if cls == 0:
            beams.append({"x": x, "y": y})
        elif cls == 1:
            columns.append({"x": x, "y": y})

    print("✅ Extracted Beams:", beams)
    print("✅ Extracted Columns:", columns)

    return {"beams": beams, "columns": columns}