"""RunPod serverless handler for ImmuneBuilder.

Example input:
{
  "input": {
    "model": "antibody",            # "antibody" | "nanobody" | "tcr"
    "sequences": {"H": "EVQL...", "L": "DIQM..."},
    "refine": true                  # optional, default true
  }
}

Chains: antibody -> H, L; nanobody -> H; tcr -> A, B.
Returns {"pdb": "<PDB file contents>"}.
"""
import os
import tempfile

import runpod
from ImmuneBuilder import ABodyBuilder2, NanoBodyBuilder2, TCRBuilder2

PREDICTORS = {
    "antibody": ABodyBuilder2,
    "nanobody": NanoBodyBuilder2,
    "tcr": TCRBuilder2,
}
_loaded = {}


def get_predictor(name):
    if name not in _loaded:
        _loaded[name] = PREDICTORS[name]()
    return _loaded[name]


def handler(job):
    job_input = job.get("input", {})
    model = job_input.get("model", "antibody").lower()
    sequences = job_input.get("sequences")
    refine = job_input.get("refine", True)

    if model not in PREDICTORS:
        return {"error": f"Unknown model '{model}'. Choose from {list(PREDICTORS)}."}
    if not isinstance(sequences, dict) or not sequences:
        return {"error": "'sequences' must be a dict of chain id -> sequence."}

    try:
        prediction = get_predictor(model).predict(sequences)
        with tempfile.TemporaryDirectory() as tmp:
            out_file = os.path.join(tmp, "prediction.pdb")
            if refine:
                prediction.save(out_file)
            else:
                prediction.save_single_unrefined(out_file)
            with open(out_file) as f:
                pdb = f.read()
    except Exception as e:
        return {"error": str(e)}

    return {"pdb": pdb}


if __name__ == "__main__":
    get_predictor("antibody")  # warm up the most common model at startup
    runpod.serverless.start({"handler": handler})
