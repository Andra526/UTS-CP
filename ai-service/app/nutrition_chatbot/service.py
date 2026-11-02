"""Chatbot nutrisi berbasis aturan (kata kunci).

Titik pemasangan LLM: ganti `answer()` agar memanggil API LLM memakai
app.config.LLM_API_KEY, dengan prompt sistem tentang nutrisi olahraga.
"""
from app.nutrition_chatbot.schemas import ChatRequest, ChatResponse

DISCLAIMER = (
    "Informasi umum, bukan pengganti saran dokter atau ahli gizi."
)

RULES = [
    (("protein",), "protein",
     "Untuk yang rutin latihan beban, target umum sekitar 1,6-2,2 g protein per kg berat badan per hari, "
     "dibagi ke 3-5 kali makan. Sumber: dada ayam, telur, ikan, tempe, tahu, yogurt."),
    (("bulking", "naik berat", "massa otot", "nambah otot"), "bulking",
     "Untuk bulking, makan sedikit di atas kebutuhan kalori harian (surplus sekitar 250-500 kkal), "
     "cukupi protein, dan latihan beban progresif. Naikkan berat badan pelan-pelan (sekitar 0,25-0,5 kg per minggu)."),
    (("cutting", "turun berat", "diet", "kurus", "lemak"), "cutting",
     "Untuk menurunkan lemak, buat defisit sedang (sekitar 300-500 kkal di bawah kebutuhan), pertahankan protein tinggi "
     "dan tetap latihan beban agar otot terjaga. Hindari defisit ekstrem."),
    (("kalori", "kkal"), "kalori",
     "Kebutuhan kalori bergantung pada berat badan, tinggi, usia, dan aktivitas. Perkiraan kasar untuk menjaga berat badan "
     "adalah 30-35 kkal per kg berat badan untuk orang yang aktif. PT Anda dapat menetapkan target yang lebih tepat."),
    (("air", "minum", "hidrasi"), "hidrasi",
     "Minum air secara teratur sepanjang hari; sekitar 2-3 liter per hari untuk orang aktif, lebih banyak saat berkeringat banyak."),
    (("sebelum latihan", "pre workout", "sebelum olahraga"), "pre-workout",
     "Makan karbohidrat + sedikit protein 1-3 jam sebelum latihan, mis. nasi/oat dengan telur atau pisang dengan yogurt."),
    (("setelah latihan", "post workout", "sesudah latihan"), "post-workout",
     "Setelah latihan, utamakan protein (20-40 g) dan karbohidrat untuk pemulihan, mis. dada ayam dengan nasi, atau yogurt dengan pisang."),
    (("tidur", "istirahat", "recovery", "pemulihan"), "pemulihan",
     "Tidur 7-9 jam penting untuk pemulihan otot dan hormon. Beri jeda istirahat antar sesi latihan untuk kelompok otot yang sama."),
]


def answer(req: ChatRequest) -> ChatResponse:
    text = req.message.lower()
    for keywords, topic, reply in RULES:
        if any(k in text for k in keywords):
            return ChatResponse(
                reply=reply, topic=topic, is_stub=True, disclaimer=DISCLAIMER
            )

    goal_hint = f" Tujuan Anda: {req.goal}." if req.goal else ""
    return ChatResponse(
        reply="Saya bisa membantu seputar protein, kalori, bulking, cutting, hidrasi, "
        "makan sebelum/sesudah latihan, dan pemulihan. Coba tanyakan salah satunya." + goal_hint,
        topic="umum",
        is_stub=True,
        disclaimer=DISCLAIMER,
    )
