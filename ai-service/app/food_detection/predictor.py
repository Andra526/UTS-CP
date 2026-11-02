from typing import List, Tuple

from app.food_detection.model_loader import get_model, load_labels


def predict_top_k(data: bytes, k: int = 3) -> Tuple[List[Tuple[str, float]], bool]:
    model = get_model()
    labels = load_labels()
    scores = model.predict(data)
    ranked = sorted(zip(labels, scores), key=lambda x: x[1], reverse=True)[:k]
    return ranked, bool(getattr(model, "is_stub", False))
