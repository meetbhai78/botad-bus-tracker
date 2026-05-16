"""
Botad Bus Tracker — ETA prediction (FastAPI)
Rush hour traffic multiplier — prompt ke hisaab se
"""
from fastapi import FastAPI
from pydantic import BaseModel
import math

app = FastAPI(title="Botad ETA Service")


class ETARequest(BaseModel):
    bus_lat: float
    bus_lng: float
    stop_lat: float
    stop_lng: float
    current_speed: float
    hour_of_day: int
    day_of_week: int = 0


def calculate_distance_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6371
    d_lat = math.radians(lat2 - lat1)
    d_lng = math.radians(lng2 - lng1)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(d_lng / 2) ** 2
    )
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


@app.get("/health")
def health():
    return {"status": "ok", "service": "botad-eta"}


@app.post("/predict-eta")
def predict_eta(req: ETARequest):
    distance = calculate_distance_km(
        req.bus_lat, req.bus_lng, req.stop_lat, req.stop_lng
    )
    if req.hour_of_day in (8, 9, 17, 18):
        multiplier = 1.4
    elif req.hour_of_day < 6 or req.hour_of_day > 22:
        multiplier = 0.8
    else:
        multiplier = 1.0
    avg_speed = max(req.current_speed, 15)
    eta_minutes = (distance / avg_speed) * 60 * multiplier
    return {"eta_minutes": round(eta_minutes, 1), "distance_km": round(distance, 2)}

