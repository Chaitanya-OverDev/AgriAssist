# Use an official Python slim image
FROM python:3.11-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the requirements file first to leverage Docker caching
COPY requirements.txt .

# Install your Python packages
RUN pip install --no-cache-dir -r requirements.txt

# Install Playwright's Chromium browser AND all required OS-level dependencies
RUN playwright install chromium
RUN playwright install-deps chromium

# Copy the rest of your application code into the container
COPY . .

# Expose the default port Render looks for (mostly for local Docker documentation)
EXPOSE 10000

# Start the FastAPI server dynamically using the PORT env variable
# (Note: Using the shell form of CMD so environment variables are evaluated)
CMD uvicorn api.main:app --host 0.0.0.0 --port ${PORT:-10000}