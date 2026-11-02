import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402

client = TestClient(app)

PNG = b"\x89PNG\r\n\x1a\n" + b"fake-image-bytes" * 10


def test_health():
    r = client.get("/health")
    assert r.status_code == 200 and r.json()["status"] == "ok"


def test_food_detect_stub_is_deterministic_and_has_nutrition():
    r1 = client.post("/food/detect", files={"image": ("a.png", PNG, "image/png")})
    r2 = client.post("/food/detect", files={"image": ("a.png", PNG, "image/png")})
    assert r1.status_code == 200
    body = r1.json()
    assert body == r2.json()
    assert body["is_stub"] is True
    assert body["nutrition"]["calories"] > 0
    assert len(body["alternatives"]) == 2
    assert 0 < body["top"]["confidence"] <= 1


def test_food_detect_rejects_bad_files():
    r = client.post("/food/detect", files={"image": ("a.txt", b"hello", "text/plain")})
    assert r.status_code == 415
    r = client.post("/food/detect", files={"image": ("a.png", b"", "image/png")})
    assert r.status_code == 400
    r = client.post("/food/detect")
    assert r.status_code == 422


def test_dictionary():
    r = client.get("/food/dictionary")
    assert r.status_code == 200 and "nasi_putih" in r.json()["foods"]


def test_grocery_meets_targets_with_enough_budget():
    r = client.post(
        "/grocery/recommendations",
        json={"budget_idr": 600000, "days": 7, "target_calories": 2500, "target_protein_g": 140},
    )
    assert r.status_code == 200
    b = r.json()
    assert b["within_budget"] is True
    assert b["total_cost_idr"] <= 600000
    assert b["meets_protein_target"] is True
    assert b["meets_calorie_target"] is True
    assert {i["category"] for i in b["items"]} >= {"protein", "karbo", "sayur", "buah"}


def test_grocery_small_budget_scales_down_and_warns():
    r = client.post(
        "/grocery/recommendations",
        json={"budget_idr": 50000, "days": 7, "target_calories": 2500, "target_protein_g": 140},
    )
    b = r.json()
    assert r.status_code == 200
    assert b["total_cost_idr"] <= 50000 * 1.02  # toleransi pembulatan
    assert b["meets_protein_target"] is False
    assert any("Anggaran" in n for n in b["notes"])


def test_grocery_exclude_and_validation():
    r = client.post(
        "/grocery/recommendations",
        json={"budget_idr": 600000, "days": 7, "target_calories": 2500,
              "target_protein_g": 140, "exclude": ["tempe", "tahu", "telur_ayam", "ikan_lele", "daging_sapi"]},
    )
    assert all(i["item_id"] != "tempe" for i in r.json()["items"])
    bad = client.post("/grocery/recommendations", json={"budget_idr": 5, "target_calories": 10, "target_protein_g": 1})
    assert bad.status_code == 422


def test_substitutions():
    r = client.post("/grocery/substitutions", json={"item_id": "daging_sapi"})
    assert r.status_code == 200
    subs = r.json()["substitutes"]
    assert subs and all(s["item_id"] != "daging_sapi" for s in subs)
    assert client.post("/grocery/substitutions", json={"item_id": "ngawur"}).status_code == 404


def test_meal_plan_close_to_targets():
    r = client.post("/meal-plans/generate", json={"target_calories": 2800, "target_protein_g": 180})
    assert r.status_code == 200
    b = r.json()
    assert [m["category"] for m in b["meals"]] == ["Sarapan", "Makan Siang", "Snack Sore", "Makan Malam"]
    assert abs(b["total_calories"] - 2800) / 2800 < 0.12
    assert abs(b["total_protein_g"] - 180) / 180 < 0.15


def test_chatbot_topics_and_fallback():
    r = client.post("/chatbot/message", json={"message": "Berapa protein yang saya butuhkan?"})
    assert r.json()["topic"] == "protein"
    r = client.post("/chatbot/message", json={"message": "mau cutting nih"})
    assert r.json()["topic"] == "cutting"
    r = client.post("/chatbot/message", json={"message": "halo", "goal": "bulking"})
    assert r.json()["topic"] == "umum" and "bulking" in r.json()["reply"]
    assert client.post("/chatbot/message", json={"message": ""}).status_code == 422
