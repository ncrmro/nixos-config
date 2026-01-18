#!/usr/bin/env bash
set -e

if [ ! -d ".venv" ]; then
    echo "Creating virtual environment..."
    uv venv --python python3.12 .venv
fi

source .venv/bin/activate

echo "Installing dependencies..."

# Uninstall torch if it was already installed (to prevent conflicts or using the wrong one)
uv pip uninstall torch torchvision torchaudio || true

# Install PyTorch with ROCm support
echo "Installing PyTorch with ROCm support..."
uv pip install --index-url https://download.pytorch.org/whl/rocm6.2 torch torchvision torchaudio

# Install docling. It will see torch is already installed.
uv pip install docling reportlab ipython

# Check what torch version we got
echo "Checking initial Torch version..."
python -c "import torch; print(f'Torch: {torch.__version__}, CUDA: {torch.cuda.is_available()}')"

# Run benchmark
echo "Running benchmark..."
python benchmark.py
