import os
import json
import asyncio
import aiohttp
import requests
from datetime import datetime, timedelta

API_KEY = os.getenv("DATA_GOV_API_KEY")
RESOURCE_ID = "35985678-0d79-46b4-9ed6-6f13308a1d24"
BASE_URL = f"https://api.data.gov.in/resource/{RESOURCE_ID}"


# --- FETCH MARKET DATA FOR FRONTEND (JSON RESPONSE) ---
async def get_market_data(state: str, district: str):
    """Fetch market data and return JSON instead of streaming."""

    target_district = district.title() if district and district.lower() != "all districts" else None

    today = datetime.now()
    dates_to_check = [(today - timedelta(days=i)).strftime("%d/%m/%Y") for i in range(5)]

    results = []

    async with aiohttp.ClientSession() as session:
        for date_str in dates_to_check:
            params = {
                "api-key": API_KEY,
                "format": "json",
                "limit": 100,
                "offset": 0,
                "filters[State]": state.title(),
                "filters[Arrival_Date]": date_str
            }

            if target_district:
                params["filters[District]"] = target_district

            try:
                async with session.get(BASE_URL, params=params, timeout=15) as response:

                    if response.status == 200:
                        data = await response.json()
                        records = data.get("records", [])

                        if records:
                            for r in records:
                                results.append({
                                    "commodity": r.get("Commodity"),
                                    "district": r.get("District"),
                                    "market": r.get("Market"),
                                    "price_latest": str(r.get("Modal_Price", "N/A")),
                                    "msp": str(r.get("Min_Price", "N/A")),
                                    "date": r.get("Arrival_Date"),
                                    "source": "live"
                                })

                            # stop once we find latest data
                            break

                    elif response.status == 429:
                        await asyncio.sleep(2)

            except Exception as e:
                print(f"API Error on {date_str}: {e}")

            await asyncio.sleep(1)

    return {"data": results}


# --- HELPER FOR GEMINI TOOL (LIVE ONLY) ---
def get_baazar_bhav_for_ai(state: str, district: str, commodity: str):
    """Synchronous tool for Gemini to fetch the latest price live."""

    if not API_KEY:
        return "Error: Government API key is missing."

    target_district = district.title() if district and district.lower() != "all districts" else None

    today = datetime.now()
    dates_to_check = [(today - timedelta(days=i)).strftime("%d/%m/%Y") for i in range(5)]

    for date_str in dates_to_check:
        params = {
            "api-key": API_KEY,
            "format": "json",
            "limit": 5,
            "filters[State]": state.title(),
            "filters[Commodity]": commodity.title(),
            "filters[Arrival_Date]": date_str
        }

        if target_district:
            params["filters[District]"] = target_district

        try:
            response = requests.get(BASE_URL, params=params, timeout=10)

            if response.status_code == 200:
                records = response.json().get("records", [])

                if records:
                    record = records[0]
                    return format_ai_response(record, commodity)

            import time
            time.sleep(1)

        except Exception:
            pass

    return f"Politely inform the user that market data is not available for {commodity} in {district or state} right now."


def format_ai_response(record: dict, requested_commodity: str):
    """Helper formatting string for Gemini from a raw dictionary."""

    return f"""
Latest Baazar Bhav for {record.get('Commodity', requested_commodity)}:

- Mandi Market: {record.get('Market')} ({record.get('District')})
- Variety/Grade: {record.get('Variety')} / {record.get('Grade')}
- Arrival Date: {record.get('Arrival_Date')}
- Latest Price (Modal): ₹{record.get('Modal_Price')}/Quintal
- Price Range: ₹{record.get('Min_Price')} to ₹{record.get('Max_Price')}

INSTRUCTIONS FOR AI:
1. Politely tell the farmer the Latest Price and the specific Mandi it is from.
2. Mention the date the price was recorded.
3. Use bold formatting (**) for key numbers so it looks good in the chat UI.
4. Keep the explanation concise.
"""