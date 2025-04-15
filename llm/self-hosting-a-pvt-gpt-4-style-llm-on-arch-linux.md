# Self-Hosting a Private GPT-4-Style LLM on Arch Linux

## Specs
- CPU: AMD Ryzen 5 5600X (12) @ 4.654GHz
- GPU: NVIDIA GeForce RTX 3070 Lite Hash Rate 
- Memory: 6704MiB / 32003MiB 
- OS: Arch Linux x86_64 
- Kernel: 6.14.1-arch1-1

## Model

**Choice**: LLaVA-1.5 7B (Text mode initially)

LLaVA is chosen because it is multimodal, which combines a CLIP ViT-L/14 vision encoder (accepts images as requests) and Vicuna LLM, which is known for [good quality conversations](https://lmsys.org/blog/2023-03-30-vicuna/). LLaVA-1.5 with a 7B model uses [less than 8 GB VRAM with 4-bit quantization](https://github.com/haotian-liu/LLaVA/blob/c121f0432da27facab705978f83c4ada465e46fd/README.md?plain=1#L275). It should hopefully achieve close to GPT-4s capability on multimodal tasks for a 7B model. Downside of this is the licensing of Vicuna which has a non-commerical license. I might explore an open source alternative in the future, but this suits my need for my first self-hosted LLM for personal use.

## Installing

### Setting up the Python 3.10+ environment

```sh
yay -S pyenv
pyenv install 3.10
pyenv global 3.10.17

yay -S conda # Install miniconda3
sudo pacman -S python-cryptography

```

Add this to `~/.bashrc` or your shell RC profile:

```sh
# Initialise pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"

# If your shell is Bash or a Bourne variant, enable conda for the current user with
[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh
# or, for all users, enable conda with
# sudo ln -s /opt/miniconda3/etc/profile.d/conda.sh /etc/profile.d/conda.sh

# Suppresses conda create errors caused by OpenSSL related misconfig warnings
export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1
```

There should be no warnings or errors. Once done:

```sh
conda activate llava
```

### Installing LLaVA and deps

```sh
git clone https://github.com/haotian-liu/LLaVA.git 
cd LLaVA
pip install --upgrade pip 
pip install -e .
# Required for installing flash-attn without errors
sudo pacman -S cuda
# FLASH_ATTENTION_SKIP_CUDA_BUILD temporary to overcome CUDA_HOME error
# See https://github.com/Dao-AILab/flash-attention/issues/509#issuecomment-1703376354
FLASH_ATTENTION_SKIP_CUDA_BUILD=TRUE pip install flash-attn --no-build-isolation
```

### Get LLaVA model weights

```sh
python -m pip install huggingface_hub
# Log into huggingface and agree to licence before downloading model weights
# Paste access token
huggingface-cli login
# Make sure git-lfs is installed (https://git-lfs.com)
sudo pacman -S git-lfs # If lfs is not installed
git lfs install
# Manually download weights for your PC (Requires around 12 - 14 GB of data)
mkdir -p ~/.cache/huggingface/llava-v1.5-7b
huggingface-cli download liuhaotian/llava-v1.5-7b --local-dir ~/.cache/huggingface/llava-v1.5-7b
```

### Initialise LLM with its first test run

```sh
python -m llava.serve.cli --model-path liuhaotian/llava-v1.5-7b --load-4bit
```

Unfortunately with my GPU, I was not able to use the `--load-8bit` flag even with SDDM disabled because I'm lacking 100 to 300MB. Clear all background processes that are using your GPU so at least `--load-4bit` can work.

```sh
nvidia-smi
```

## Notes

### Pruning

Eliminates redundant / less important weights in a model, such as setting small magnitude weights to zero (i.e. magnitude pruning), dropping whole neurons or attention heads.

Useful for making the model smaller, reducing inference time and save compute and memory bandwidth. This comes at a cost of the need for tuning to avoid drops in accuracy, as well as the need for hardware/software to be sparse-aware to benefit from optimising via pruning.

### Quantization

Quantization reduces the memory to train or store the weights/parameters of a model by reducing its precision data type via number of bits which represents numbers in a model. For example, converting model weights from float32 to float16, bfloat16 or int8.

Useful for reducing model size, speeding up inference on CPUs and mobile device and consumes less power. Although it will reduuce accuracy.

Types of quantization includes:
- Quantization-aware training: Simulates quantization during training, giving more accuracy
- Post-training quantization: Done after training; faster, affects accuracy more

