import time
import torch
from docling.document_converter import DocumentConverter, PdfFormatOption
from docling.datamodel.pipeline_options import PdfPipelineOptions, AcceleratorOptions, AcceleratorDevice
from docling.datamodel.base_models import InputFormat

def benchmark(device_type):
    print(f"\n--- Benchmarking with {device_type} ---")
    
    if device_type == "GPU":
        if not torch.cuda.is_available():
            print("CUDA/ROCm not available, skipping GPU benchmark.")
            return
        device = AcceleratorDevice.CUDA
    else:
        device = AcceleratorDevice.CPU

    # Configure pipeline
    pipeline_options = PdfPipelineOptions()
    pipeline_options.accelerator_options = AcceleratorOptions(
        num_threads=8, 
        device=device
    )

    doc_converter = DocumentConverter(
        format_options={
            InputFormat.PDF: PdfFormatOption(pipeline_options=pipeline_options)
        }
    )

    start_time = time.time()
    try:
        # Convert the generated test file
        result = doc_converter.convert("test_doc.pdf")
        end_time = time.time()
        
        duration = end_time - start_time
        print(f"Conversion successful.")
        print(f"Time taken: {duration:.4f} seconds")
        
        # Access some result to ensure it worked
        # print(result.document.export_to_markdown()[:100])
        
    except Exception as e:
        print(f"Conversion failed: {e}")

if __name__ == "__main__":
    print("Checking PyTorch environment...")
    print(f"Torch version: {torch.__version__}")
    print(f"CUDA available: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"Device name: {torch.cuda.get_device_name(0)}")
    
    # Generate PDF if not exists (though shell hook does it)
    import os
    if not os.path.exists("test_doc.pdf"):
        print("Generating test_doc.pdf...")
        from reportlab.pdfgen import canvas
        c = canvas.Canvas("test_doc.pdf")
        c.drawString(100, 750, "Hello World")
        c.save()

    # Run benchmarks
    benchmark("CPU")
    benchmark("GPU")
