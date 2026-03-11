import requests
import time
import os
import traceback
import logging
from datetime import datetime
from dotenv import load_dotenv
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BASE_DIR))

from db.database import SessionLocal
from db.models import RawScheme, CleanedScheme

# --- Set up Logging ---
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("sync_log.txt"), # Logs to this text file
        logging.StreamHandler()              # Also prints to the terminal
    ]
)

load_dotenv()

API_URL = "https://api.myscheme.gov.in/search/v6/schemes"
API_KEY = os.getenv("MYSCHEME_API_KEY")

def is_active_and_relevant(fields):
    # 1. Check if the scheme is already closed
    close_date_str = str(fields.get("schemeCloseDate", "None"))
    if close_date_str != "None":
        try:
            close_date = datetime.strptime(close_date_str, "%Y-%m-%d").date()
            today = datetime.now().date()
            if close_date < today:
                return False  
        except ValueError:
            pass 

    # 2. Check if it's relevant to agriculture
    categories = fields.get("schemeCategory", [])
    tags = fields.get("tags", [])
    
    if "Agriculture,Rural & Environment" in categories:
        return True
        
    lower_tags = [t.lower() for t in tags]
    if "farmer" in lower_tags or "agriculture" in lower_tags:
        return True
        
    return False

def sync_schemes():
    logging.info("--- Starting Sync Job ---")
    
    # Prevent checking on Saturday (5) and Sunday (6)
    if datetime.now().weekday() >= 5:
        logging.info("Weekend detected. Skipping sync.")
        return

    db = SessionLocal()
    try:
        headers = {
            "User-Agent": "Mozilla/5.0",
            "Accept": "application/json",
            "Origin": "https://www.myscheme.gov.in",
            "Referer": "https://www.myscheme.gov.in/",
            "x-api-key": API_KEY
        }

        params = {
            "lang": "en",
            "q": '[{"identifier":"schemeCategory","value":"Agriculture,Rural & Environment"}]',
            "size": 10
        }

        start = 0
        new_raw_count = 0
        new_cleaned_count = 0

        while True:
            params["from"] = start
            logging.info(f"Fetching schemes from offset {start}...")
            
            response = requests.get(API_URL, params=params, headers=headers)
            data = response.json()
            items = data.get("data", {}).get("hits", {}).get("items", [])
            
            if not items:
                break 

            for item in items:
                fields = item.get("fields", {})
                slug = fields.get("slug")

                existing_raw = db.query(RawScheme).filter(RawScheme.slug == slug).first()
                
                if not existing_raw:
                    # 1. Save to Raw
                    new_raw = RawScheme(
                        slug=slug,
                        scheme_name=fields.get("schemeName", ""),
                        short_title=fields.get("schemeShortTitle", ""),
                        level=fields.get("level", ""),
                        scheme_for=fields.get("schemeFor", ""),
                        states=fields.get("beneficiaryState", []),
                        categories=fields.get("schemeCategory", []),
                        close_date=str(fields.get("schemeCloseDate")),
                        priority=fields.get("priority", 0),
                        description=fields.get("briefDescription", ""),
                        tags=fields.get("tags", [])
                    )
                    db.add(new_raw)
                    new_raw_count += 1

                    # 2. Save to Cleaned
                    if is_active_and_relevant(fields):
                        new_cleaned = CleanedScheme(
                            slug=slug,
                            scheme_name=fields.get("schemeName", ""),
                            description=fields.get("briefDescription", ""),
                            states=fields.get("beneficiaryState", []),
                            level=fields.get("level", ""),
                            scheme_for=fields.get("schemeFor", ""),
                            close_date=str(fields.get("schemeCloseDate")),
                            tags=fields.get("tags", [])
                        )
                        db.add(new_cleaned)
                        new_cleaned_count += 1

            db.commit()
            start += 10
            time.sleep(0.5) 

        logging.info(f"Sync complete. Added {new_raw_count} raw schemes and {new_cleaned_count} active cleaned schemes.")

    except Exception as e:
        logging.error("Sync failed! Full error traceback below:")
        # This prints the full error stack to the terminal and logs it
        logging.error(traceback.format_exc())
        db.rollback()
    finally:
        db.close()
        logging.info("--- Sync Job Ended ---\n")

if __name__ == "__main__":
    sync_schemes()