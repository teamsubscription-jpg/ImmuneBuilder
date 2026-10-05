FROM mambaorg/micromamba:1.5.10-jammy

ENV PYTHONUNBUFFERED=1
# Activate the conda env for every RUN step below
ARG MAMBA_DOCKERFILE_ACTIVATE=1

WORKDIR /app

# OpenMM + pdbfixer (refinement) and ANARCI (numbering) come from conda.
# The micromamba base env is empty, so pinning python here causes no conflicts.
RUN micromamba install -y -n base -c conda-forge -c bioconda \
        python=3.10 pip openmm pdbfixer anarci && \
    micromamba clean -afy

# PyTorch with CUDA (the wheel bundles the CUDA runtime; RunPod provides the driver)
RUN pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cu121 && \
    pip install --no-cache-dir runpod

COPY --chown=$MAMBA_USER:$MAMBA_USER . /app
RUN pip install --no-cache-dir /app

# Bake the model weights into the image so workers don't download them on cold start
RUN python -c "from ImmuneBuilder import ABodyBuilder2, NanoBodyBuilder2, TCRBuilder2; ABodyBuilder2(); NanoBodyBuilder2(); TCRBuilder2()"

CMD ["python", "-u", "/app/handler.py"]
