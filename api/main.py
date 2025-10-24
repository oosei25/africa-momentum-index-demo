
# FastAPI app scaffold (optional for now)
from fastapi import FastAPI

app = FastAPI(title="Africa Momentum Index API (MVP scaffold)")

@app.get("/health")
def health():
    return {"status": "ok"}
