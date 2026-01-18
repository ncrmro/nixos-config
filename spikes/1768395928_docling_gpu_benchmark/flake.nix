{
  description = "Docling GPU Benchmark Spike";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      # Libraries that pip wheels might need
      libraryPath = pkgs.lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
        pkgs.zlib
        pkgs.glib
        pkgs.libGL
        pkgs.libffi
        pkgs.openssl
      ];

      # Function to generate a dummy PDF for testing
      generatePdfScript = ''
        from reportlab.pdfgen import canvas
        c = canvas.Canvas("test_doc.pdf")
        c.drawString(100, 750, "Hello World")
        c.drawString(100, 700, "This is a test document for Docling.")
        # Add some complexity (tables, images, etc.) to make it worth benchmarking
        for i in range(10):
            c.drawString(100, 600 - i*20, f"Line number {i} of text content.")
        c.save()
        print("Generated test_doc.pdf")
      '';

    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          # Tools
          git
          wget
          uv # Fast python package installer

          # System dependencies for Docling/OCR/PDF

          tesseract

          poppler-utils

          # GPU Monitoring

          rocmPackages.rocm-smi

          # Ollama

          ollama-rocm

          # Python

          python312

        ];

        shellHook = ''


          echo "Docling GPU Spike Environment"

          # Setup Venv
          if [ ! -d ".venv" ]; then
            echo "Creating virtual environment..."
            uv venv .venv
          fi

          source .venv/bin/activate

          # Install dependencies
          echo "Installing/Updating dependencies with uv..."
          uv pip install docling reportlab ipython

          echo "Generating test PDF..."
          python -c '${generatePdfScript}'

          echo "Check GPU status with: rocm-smi"
          echo "Run benchmark with: python benchmark.py"
        '';

        LD_LIBRARY_PATH = "${libraryPath}";
      };
    };
}
