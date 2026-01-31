#!/bin/bash
cd "$(dirname "$0")/.."
source venv/bin/activate
python scripts/test_gateway.py
