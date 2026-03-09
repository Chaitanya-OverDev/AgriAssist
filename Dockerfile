# Use an official Python slim image
FROM python:3.11-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the requirements file first to leverage Docker caching
COPY requirements.txt .

# Install your Python packages
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of your application code into the container
COPY . .

# Expose the default port Render looks for
EXPOSE 10000

# Run database migrations, THEN start the FastAPI server
CMD sh -c "alembic upgrade head && uvicorn api.main:app --host 0.0.0.0 --port ${PORT:-10000}"