from playwright.sync_api import sync_playwright

def fetch_agmarknet_prices(state_name: str, district_name: str = None):
    print(f"\n--- 1. Launching Browser for {district_name or 'ALL DISTRICTS'}, {state_name}... ---")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        # Added viewport to ensure the site doesn't render in a weird mobile view that hides the dropdown
        context = browser.new_context(
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36",
            viewport={'width': 1920, 'height': 1080}
        )
        page = context.new_page()

        try:
            # wait_until="domcontentloaded" is much safer than "networkidle"
            page.goto("https://agmarknet.gov.in/home", timeout=60000, wait_until="domcontentloaded")

            # Explicitly wait for the dropdown to exist AND be visible
            print("--- Waiting for the #state dropdown to appear... ---")
            page.wait_for_selector("#state", state="visible", timeout=60000)

            # --- 1. STATE SELECTION ---
            # force=True ignores invisible overlays that might be blocking the click
            page.locator("#state").click(force=True)
            page.wait_for_timeout(1000)

            page.locator("div.py-1").get_by_text("All States", exact=True).click(force=True)
            page.wait_for_timeout(500)

            page.locator("div.py-1").get_by_text(state_name.title(), exact=True).click(force=True)

            # Click away to close the dropdown
            page.locator("body").click(position={"x": 0, "y": 0}, force=True)
            page.wait_for_timeout(3000)

            # --- 2. DISTRICT SELECTION (Conditional) ---
            if district_name:
                print(f"--- Selecting District: {district_name}... ---")
                page.locator("#district").click(force=True)
                page.wait_for_timeout(1000)
                page.locator("div.py-1").get_by_text("All Districts", exact=True).click(force=True)
                page.wait_for_timeout(500)
                page.locator("div.py-1").get_by_text(district_name.title(), exact=True).click(force=True)
                page.locator("body").click(position={"x": 0, "y": 0}, force=True)
                page.wait_for_timeout(1000)

            # --- 3. CLICK GO BUTTON ---
            page.locator("button[aria-label='Apply filters and fetch data']").click(force=True)

            # --- 4. WAIT FOR INITIAL TABLE ---
            print("--- Waiting for the data table to load... ---")
            page.wait_for_selector("table tbody tr", state="visible", timeout=30000)
            page.wait_for_timeout(2000)

            # --- 5. HANDLE PAGINATION (Show Max Items) ---
            items_select = page.locator("#itemsPerPage")
            if items_select.is_visible():
                print("--- Adjusting Items Per Page... ---")
                options = items_select.locator("option").all()

                values = []
                for opt in options:
                    val = opt.get_attribute("value")
                    if val and val.isdigit():
                        values.append(int(val))

                if values:
                    max_val = max(values)
                    print(f"--- Selecting {max_val} items per page to reveal all data ---")
                    items_select.select_option(value=str(max_val))
                    page.wait_for_timeout(3000)

            # --- 6. EXTRACT DATA ---
            rows = page.locator("table tbody tr").all()
            scraped_records = []

            def clean_val(val):
                val = val.strip()
                return "N/A" if val in ("-", "NR", "") else val

            for row in rows:
                cols = row.locator("td").all_inner_texts()

                if len(cols) >= 9:
                    group = cols[0].strip()
                    commodity = cols[1].strip()
                    msp = clean_val(cols[2])
                    price_latest = clean_val(cols[3])
                    price_mid = clean_val(cols[4])
                    price_old = clean_val(cols[5])

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