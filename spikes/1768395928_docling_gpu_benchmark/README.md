# Docling GPU Benchmark Spike

This spike aims to benchmark `docling` performance with and without GPU support, and integrate it with `ollama`.

## Objective
- Verify `docling` installation via Nixpkgs.
- Enable GPU support (AMD ROCm/Vulkan) for `docling`.
- Benchmark conversion speed (CPU vs GPU).
- Test integration with `ollama`.

## Usage

1. **Enter the development shell:**
   ```bash
   nix develop
   ```
   This will download dependencies (including PyTorch and Ollama) and generate a dummy `test_doc.pdf`.

2. **Start Ollama (Optional):**
   If you want to test Ollama integration, start the server in a separate terminal (inside `nix develop`):
   ```bash
   ollama serve
   ```
   Then pull a model (e.g., llama3):
   ```bash
   ollama pull llama3
   ```

3. **Run the Benchmark:**
   ```bash
   python benchmark.py
   ```

4. **Monitor GPU:**
   Open a separate terminal and run:
   ```bash
   watch -n 1 rocm-smi
   ```
