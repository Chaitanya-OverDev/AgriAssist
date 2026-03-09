import os
import json
import asyncio
import aiohttp
import requests
import traceback
from datetime import datetime, timedelta

API_KEY = os.getenv("DATA_GOV_API_KEY")
RESOURCE_ID = "35985678-0d79-46b4-9ed6-6f13308a1d24"
BASE_URL = f"https://api.data.gov.in/resource/{RESOURCE_ID}"

# Global headers to mimic a real browser and avoid firewall blocks
HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Accept": "application/json"
}

# --- HELPER: GET RECENT BUSINESS DAYS ---
def get_recent_business_days(num_days=4):
    today = datetime.now()
    dates = []
    days_back = 0

    while len(dates) < num_days:
        check_date = today - timedelta(days=days_back)
        if check_date.weekday() < 5:
            dates.append(check_date.strftime("%d/%m/%Y"))
        days_back += 1
        if days_back > 15:
            break

    return dates

# --- FETCH MARKET DATA FOR FRONTEND (JSON RESPONSE) ---
async def get_market_data(state: str, district: str):
    target_district = district.title() if district and district.lower() != "all districts" else None
    dates_to_check = get_recent_business_days(4)
    results = []

    # 45 seconds to handle large payloads (500 records)
    custom_timeout = aiohttp.ClientTimeout(total=45)

    async with aiohttp.ClientSession(timeout=custom_timeout, headers=HEADERS) as session:
        for date_str in dates_to_check:
            params = {
                "api-key": API_KEY,
                "format": "json",
                "limit": 500, # Increased to 500 based on your successful test
                "offset": 0,
                "filters[State]": state.title(),
                "filters[Arrival_Date]": date_str
            }

            if target_district:
                params["filters[District]"] = target_district

            try:
                print(f"📡 Fetching state data for {date_str}...")
                async with session.get(BASE_URL, params=params) as response:
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
                            # Once we find the most recent business day with data, we stop
                            break

                    elif response.status == 429:
                        print(f"⚠️ [FRONTEND] Rate Limited (429) on {date_str}.")
                        await asyncio.sleep(2)

                    else:
                        error_text = await response.text()
                        print(f"⚠️ [FRONTEND] HTTP {response.status}: {error_text}")

            except asyncio.TimeoutError:
                print(f"⏳ [FRONTEND] Timeout on {date_str}. Server is slow, skipping...")
            except Exception as e:
                print(f"🚨 [FRONTEND] Error: {repr(e)}")

            await asyncio.sleep(1)

    return {"data": results}


# --- HELPER FOR GEMINI TOOL (LIVE ONLY) ---
def get_baazar_bhav_for_ai(state: str, district: str, commodity: str):
    """Synchronous tool for Gemini to fetch the latest price live."""
    if not API_KEY:
        return "Error: Government API key is missing."

    target_district = district.title() if district and district.lower() != "all districts" else None
    dates_to_check = get_recent_business_days(4)

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
            # Using browser headers in synchronous request too
            response = requests.get(BASE_URL, params=params, headers=HEADERS, timeout=30)

            if response.status_code == 200:
                records = response.json().get("records", [])

                if records:
                    record = records[0]
                    return format_ai_response(record, commodity)

            elif response.status_code == 429:
                print(f"⚠️ [AI TOOL] Rate Limit (429) for {commodity}")

            import time
            time.sleep(1)

        except requests.exceptions.Timeout:
            print(f"⏳ [AI TOOL] Timeout for {commodity} on {date_str}")
        except Exception as e:
            print(f"🚨 [AI TOOL] Error: {repr(e)}")

    return f"Politely inform the user that market data is not available for {commodity} in {district or state} right now."


def format_ai_response(record: dict, requested_commodity: str):
    """Helper formatting string for Gemini from a raw dictionary."""
    return f"""
Latest Baazar Bhav for {record.get('Commodity', requested_commodity)}:

- Mandi Market: {record.get('Market')} ({record.get('District')})
- Variety/Grade: {record.get('Variety')} / {record.get('Grade')}
- Arrival Date: {record.get('Arrival_Date')}
- Latest Price (Modal): **₹{record.get('Modal_Price')}/Quintal**
- Price Range: ₹{record.get('Min_Price')} to ₹{record.get('Max_Price')}

INSTRUCTIONS FOR AI:
1. Politely tell the farmer the Latest Price and the specific Mandi it is from.
2. Mention the date the price was recorded.
3. Use bold formatting (**) for key numbers so it looks good in the chat UI.
4. Keep the explanation concise.
"""