from playwright.sync_api import sync_playwright

def fetch_agmarknet_prices(state_name: str, district_name: str = None):
    print(f"\n--- 1. Launching Browser for {district_name or 'ALL DISTRICTS'}, {state_name}... ---")
    
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36")
        page = context.new_page()
        
        try:
            page.goto("https://agmarknet.gov.in/home", timeout=60000)
            page.wait_for_load_state("networkidle")
            
            # --- 1. STATE SELECTION ---
            page.locator("#state").click()
            page.wait_for_timeout(1000)
            page.locator("div.py-1").get_by_text("All States", exact=True).click()
            page.wait_for_timeout(500)
            page.locator("div.py-1").get_by_text(state_name.title(), exact=True).click()
            page.locator("body").click(position={"x": 0, "y": 0})
            
            page.wait_for_timeout(3000)

            # --- 2. DISTRICT SELECTION (Conditional) ---
            if district_name:
                page.locator("#district").click()
                page.wait_for_timeout(1000)
                page.locator("div.py-1").get_by_text("All Districts", exact=True).click()
                page.wait_for_timeout(500)
                page.locator("div.py-1").get_by_text(district_name.title(), exact=True).click()
                page.locator("body").click(position={"x": 0, "y": 0})
                page.wait_for_timeout(1000)

            # --- 3. CLICK GO BUTTON ---
            page.locator("button[aria-label='Apply filters and fetch data']").click()
            
            # --- 4. WAIT FOR INITIAL TABLE ---
            print("--- Waiting for the data table to load... ---")
            page.wait_for_selector("table tbody tr", timeout=15000)
            page.wait_for_timeout(2000) 
            
            # --- 5. HANDLE PAGINATION (Show Max Items) ---
            items_select = page.locator("#itemsPerPage")
            if items_select.is_visible():
                print("--- Adjusting Items Per Page... ---")
                options = items_select.locator("option").all()
                
                # Extract all numerical values from the dropdown options
                values = []
                for opt in options:
                    val = opt.get_attribute("value")
                    if val and val.isdigit():
                        values.append(int(val))
                
                if values:
                    max_val = max(values) # Find the biggest option (e.g., 20, 30, 40)
                    print(f"--- Selecting {max_val} items per page to reveal all data ---")
                    # Select the highest value to expand the table
                    items_select.select_option(value=str(max_val))
                    # Give React a moment to render the new rows
                    page.wait_for_timeout(3000)

            # --- 6. EXTRACT DATA ---
            rows = page.locator("table tbody tr").all()
            scraped_records = []
            
            def clean_val(val):
                """Helper to convert dashes or empty strings to N/A"""
                val = val.strip()
                return "N/A" if val in ("-", "NR", "") else val

            for row in rows:
                cols = row.locator("td").all_inner_texts()
                
                # Check for 9 columns
                if len(cols) >= 9: 
                    group = cols[0].strip()
                    commodity = cols[1].strip()
                    
                    # Store exact values with the cleaner
                    msp = clean_val(cols[2])
                    price_latest = clean_val(cols[3])
                    price_mid = clean_val(cols[4])
                    price_old = clean_val(cols[5])

                    # Skip empty rows or "No Data" rows
                    if commodity and commodity.lower() != "no data found":
                        record = {
                            "state": state_name.title(),
                            "district": district_name.title() if district_name else "All Districts",
                            "commodity": commodity,
                            "commodity_group": group,
                            "msp": msp,
                            "price_latest": price_latest,
                            "price_mid": price_mid,
                            "price_old": price_old
                        }
                        scraped_records.append(record)
            
            print(f"--- SUCCESS: Extracted {len(scraped_records)} structured records! ---")
            return scraped_records

        except Exception as e:
            print(f"--- PLAYWRIGHT SCRAPING ERROR: {e} ---")
            return []