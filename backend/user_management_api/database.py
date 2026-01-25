from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv
from urllib.parse import quote_plus  # <--- Import this tool

load_dotenv()

# 1. Get raw values
db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")
db_host = os.getenv("DB_HOST")
db_name = os.getenv("DB_NAME")

# 2. URL Encode the password (safely converts '#' to '%23')
encoded_password = quote_plus(db_password)

# 3. Construct the full connection string
SQLALCHEMY_DATABASE_URL = f"postgresql://{db_user}:{encoded_password}@{db_host}/{db_name}"

# The rest remains the same...
engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()