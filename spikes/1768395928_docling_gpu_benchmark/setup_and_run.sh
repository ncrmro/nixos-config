#!/usr/bin/env bash
set -e

if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    uv venv .venv
fi

source .venv/bin/activate

echo "Installing dependencies..."
# Install docling. It will pull in torch (likely CPU or CUDA).
uv pip install docling reportlab ipython

# Check what torch version we got
echo "Checking initial Torch version..."
python -c "import torch; print(f'Torch: {torch.__version__}, CUDA: {torch.cuda.is_available()}')"

# Run benchmark
echo "Running benchmark..."
python benchmark.py
