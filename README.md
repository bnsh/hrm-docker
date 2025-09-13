# HRM Docker

This repo provides a working Dockerfile that demonstrates everything needed to get the [HRM (Hierarchical Reasoning Model)](https://github.com/sapientinc/HRM) repo running **with CUDA + `flash-attn` support**.

## ⚠️ Purpose

This image is **not really meant to be used directly**.

Instead, it serves as a reference for:

- How to set up a system (or container) with:
  - CUDA 12.9
  - `flash-attn` (which requires `--no-build-isolation`)
  - Dependencies from the `HRM` repo
  - Additional utilities (`numpy`, `psutil`, `adam-atan2-pytorch`)
- Patching the HRM source minimally for:
  - Optimizer replacement (`AdamATan2`)
  - Learning rate override
- Directory structure and `wandb` setup

## 🐳 What's Included

- `Dockerfile`: Full install of CUDA 12.9 and HRM with flash-attn
- `Makefile`: Commands to build, run, and test the container setup
- `extra-requirements.txt`: Additional pip requirements
- `enable-gpus.sh`: How to set up GPU support on **Ubuntu hosts**

## 🧰 Key Steps

Look inside the `Dockerfile` for:

- CUDA 12.9 install via `.deb` (no `.run` file needed)
- Virtualenv setup and PATH management
- Flash-attn installation quirks
- Safe in-place edits of the HRM training script

```bash
perl -p -i -e 's/^from adam_atan2 import AdamATan2$/from adam_atan2_pytorch import AdamAtan2 as AdamATan2/g' pretrain.py
```

## 📦 Where Are the Weights?

This repo only sets up the **environment** (CUDA, flash-attn, HRM code).
The actual trained checkpoint weights are published separately on Hugging Face:

➡️ [sapientinc/HRM-checkpoint-sudoku-extreme](https://huggingface.co/sapientinc/HRM-checkpoint-sudoku-extreme)
  - **Trained on most "extreme" 1k examples** (Sapient):
  - Accuracy @ 16 steps ≈ **83.7%**
  - Exact Accuracy @ 16 steps ≈ **55.1%**

➡️ [bnsh/HRM-checkpoint-sudoku-full](https://huggingface.co/bnsh/HRM-checkpoint-sudoku-full)
  - **Trained on full dataset**:
  - Accuracy @ 16 steps ≈ **99.5%**
  - Exact Accuracy @ 16 steps ≈ **98.7%**


## 🧠 Why This Exists

HRM has a lot of moving parts and GPU requirements. This Dockerfile exists so that others (or future me) can:

- See exactly what worked
- Avoid chasing cryptic build errors
- Use this as a baseline for configuring their **host machines** or **bare-metal installs**

## 💡 TL;DR

Don't try to use this container directly.
Just **read the Dockerfile**, steal what you need, and apply it to your own system or project.

