FROM condaforge/miniforge3:latest

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1

WORKDIR /app

# OpenMM + pdbfixer (refinement) and ANARCI (numbering) come from conda
RUN mamba install -y -c conda-forge -c bioconda \
        python=3.10 openmm pdbfixer anarci && \
    mamba clean -afy

# PyTorch with CUDA (the wheel bundles the CUDA runtime; RunPod provides the driver)
RUN pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cu121 && \
    pip install --no-cache-dir runpod

COPY . /app
RUN pip install --no-cache-dir /app

# Bake the model weights into the image so workers don't download them on cold start
RUN python -c "from ImmuneBuilder import ABodyBuilder2, NanoBodyBuilder2, TCRBuilder2; ABodyBuilder2(); NanoBodyBuilder2(); TCRBuilder2()"

CMD ["python", "-u", "/app/handler.py"]
