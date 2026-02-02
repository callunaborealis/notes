# Self hosting a private GPT-4 style LLM on Arch Linux using ollama / webui

`llava` (Large Language and Vision Assistant): Connects a vision encoder (e.g. CLIP VIT) to an LLM. Based on Vicuna but now accepts open models like Mistral 7B. See <https://ollama.com/library/llava:v1.6>. Licenced as Apache 2.0 (suitable for my open source requirement). For this set up, we will use LLaVa 7B v1.6 (Mistral)

`ollama`: LLM server and Docker-like CLI to manage LLMs. Supports quantization by default. Also supports GPU acceleration via CUDA. See <https://ollama.com/>. 

```sh
# Install pyenv, allows different python versions
yay -S pyenv
pyenv install 3.11
# Required if pip package manager going to be used
pyenv global 3.11

# I use an Nvidia GPU so I have to download
# packages to get
sudo pacman -S nvidia nvidia-utils

sudo pacman -S ollama
# Start background service to load models into memory listening on localhost:11434
# for model requests. This command can be skipped if ollama run is done already
ollama serve
# Get the chosen LLaVA 7B v1.6 model, with a Mistral backbone
# 5-bit weighted quantisation balancing speed and accuracy (Q5_1 format)
ollama pull llava:7b-v1.6-mistral-q5_1
# Verify the model is pulled
ollama list
# Interact with the model via CLI
ollama run llava:7b-v1.6-mistral-q5_1
```

`open-webui` (formerly ollama-webui): Web GUI with a ChatGPT styled UI. `open-webui` reportedly uses Svelte.

```sh
# Installs docker required for open-webui
sudo pacman -S docker
sudo systemctl enable --now docker.service
sudo usermod -aG docker $USER
# Ensures Docker runtime is integrated with Nvidia drivers
sudo pacman -S nvidia-container-toolkit

# Initialises open-webui container
# Alternative sources: https://hub.docker.com/r/openeuler/open-webui/tags
docker run -d --name open-webui --gpus=all -p 3000:8080 \
  -v ollama:/root/.ollama -v openwebui_data:/app/backend/data \
  ghcr.io/open-webui/open-webui:ollama

docker run -d \
 --env PORT=3000 \
 --network=host \
 --gpus=all \
 --volume ollama:/root/.ollama \
 --volume open-webui:/app/backend/data \
 --env OLLAMA_BASE_URL=http://127.0.0.1:11434 \
 --name open-webui \
 --restart always \
 ghcr.io/open-webui/open-webui:cuda
```

- `--env PORT=3000` (or `-e`) sets the port at `3000`. Alternatively, we can use `--publish 3000:8080`to map the container port 8080 to your machine port 3000 but this is ignored with `--network=host` flag
- `--network=host` is set only if we are unable to connect to the ollama API served locally outside the container
- `--gpus=all` passes our GPU into the container (requires the container toolkit, which we installed). However, if Docker hangs up while running open-webui, consider removing
this flag first.
- `--volume` (or `-v`) to mount 2 volumes:
  - `ollama`'s model data (`ollama:/root/.ollama`)
  - `open-webui`'s data (`openwebui_data:/app/backend/data`).
  - This will preserve models downloaded or configs saved on container restart

- Optional: `--restart always` if open-webui should be started on boot. However, it is excluded because we want to manually switch on every time.
- Adding a release tag:
  - Cuda release: Uses CUDA driver to use your GPU acceleration
  - Stable release: Using the `:ollama` tag provides `ollama` support out of the box
  - Development release: Using the `:dev` tag allows open-webui to have the latest but sometimes buggy features

Once done, open the locally run <https://localhost:3000> (Ensuring that `ollama` is also running separately in the background). From the UI, sign up for an admin account. Click the top right, "Settings", "Admin Settings". Under connections, ensure Ollama API is set as <http://localhost:11434> (You can also verify this link is ollama by opening it on a web browser and receiving a "Ollama is running" message). Do not set tags to ensure all running LLMs are visible on `open-webui`.

Restart `docker stop open-webui` / `docker start open-webui` or remove `error` subpath to access the localhost host directly if you are unable to receive the login screen.

For subsequent sessions (if the container was not explicitly removed on your machine):

```sh
ollama serve
docker start open-webui
firefox localhost:3000
```

## Simplify starting up open-webui via `systemd`

If privacy, security, portability are less of a concern while setting this up on the machine (or if you like the convenience of `systemd`), consider `systemd`:

Setup `ollama` as a `systemd` service

```sh
sudo vim /etc/systemd/system/ollama.service
```

```vim
[Unit]
Description=ollama
After=network.target docker.service
Requires=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/ollama serve
User=$YOU
WorkingDirectory=/home/$YOU
Environment="OLLAMA_MODELS=/home/$YOU/.ollama"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

[Install]
WantedBy=multi-user.target
```

Setup `open-webui` as a `systemd` service

```sh
sudo vim /etc/systemd/system/open-webui.service
```


```vim
[Unit]
Description=open-webui
After=network.target docker.service ollama.service
Requires=docker.service ollama.service

[Service]
Restart=always
ExecStart=/usr/bin/docker run -d \
 --publish 3000:8080 \
 --gpus=all \
 --volume ollama:/root/.ollama \
 --volume open-webui:/app/backend/data \
 --env OLLAMA_BASE_URL=http://127.0.0.1:11434 \
 --name open-webui \
 --restart always \
 ghcr.io/open-webui/open-webui:ollama
ExecStop=/usr/bin/docker stop open-webui

[Install]
WantedBy=multi-user.target
```

```sh
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now ollama.service open-webui.service
systemctl status ollama
systemctl status open-webui
```

## Updating `open-webui`

```sh
docker stop open-webui
docker container open-webui
docker rmi $OPEN_WEBUI_HASH
# If either commands result in a "Error response from daemon: conflict: unable to delete <image hash> (must be forced) - image is being used by stopped container <container hash>",
# try:
docker container prune
# If you need to also remove the locally stored knowledge base and saved training data:
docker volume prune
```