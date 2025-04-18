# Atoma SDK Python Test Project

This project demonstrates how to use the Atoma Python SDK for confidential chat interactions.

## Setup

1. Create a virtual environment (recommended):
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Set up environment variables:
   - Copy `.env.example` to `.env`
   - Add your Atoma Bearer Token to the `.env` file

## Usage

Run the main script:
```bash
python main.py
```

The script will:
1. Perform a health check
2. Start a confidential chat session
3. Stream the response from the model

## Features

- Health check verification
- Confidential chat creation
- Streaming response handling
- Environment variable management