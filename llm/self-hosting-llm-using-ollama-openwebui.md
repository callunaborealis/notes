# Self hosting a private GPT-4 style LLM on Arch Linux using ollama / webui

`llava` (Large Language and Vision Assistant): Connects a vision encoder (e.g. CLIP VIT) to an LLM. Based on Vicuna but now accepts open models like Mistral 7B. See <https://ollama.com/library/llava:v1.6>. Licenced as Apache 2.0 (suitable for my open source requirement). For this set up, we will use LLaVa 7B v1.6 (Mistral)

`ollama`: LLM server and Docker-like CLI to manage LLMs. Supports quantization by default. Also supports GPU acceleration via CUDA. See <https://ollama.com/>. 

```sh
# Install pyenv, allows different python versions. tk provides
# the tktoolkit
yay -S pyenv tk
pyenv install 3.11
# Required if pip package manager going to be used
pyenv global 3.11

# I use an Nvidia GPU so I have to download
# packages to get
sudo pacman -S nvidia nvidia-utils

sudo pacman -S ollama
# Start background service to load models into memory listening on localhost:11434
# for model requests. This command can be skipped if ollama run is done already
```

If you need a different place to store ollama like in a different drive:
```sh
# Check and enable ollama
sudo systemctl status ollama
# Take note of the location of HOME and OLLAMA_MODELS listed in /usr/lib/systemd/system/ollama.service. It should be /var/lib/ollama by default
sudo ln -s /somewhere/else/to/store/ollama /var/lib/ollama
```

```
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
groups $USER # should print $USER : $USER sudo docker
# Save changes to newly created docker group
newgrp docker
# Ensures Docker runtime is integrated with Nvidia drivers
sudo pacman -S nvidia-container-toolkit

# Initialises open-webui container
# Alternative sources: https://hub.docker.com/r/openeuler/open-webui/tags
docker run -d --name open-webui --gpus=all -p 3000:8080 \
  -v ollama:/root/.ollama -v open-webui:/app/backend/data \
  ghcr.io/open-webui/open-webui:ollama

# If you need custom places to store ollama and open-webui data
# Assuming a custom folder is set for ollama (e.g. `/somewhere/else/ollama` where
# that folder contains `.ollama`, `.nv` etc)
docker run -d \
  --env PORT=3000 \
  --network=host \
  --gpus=all \
  --volume /somewhere/else/ollama:/root/.ollama \
  --volume /somewhere/else/open-webui:/app/backend/data \
  --env OLLAMA_BASE_URL=http://127.0.0.1:11434 \
  --name open-webui \
  --restart no \
  ghcr.io/open-webui/open-webui:cuda

```

- `--env PORT=3000` (or `-e`) sets the port at `3000`. Alternatively, we can use `--publish 3000:8080`to map the container port 8080 to your machine port 3000 but this is ignored with `--network=host` flag
- `--network=host` is set only if we are unable to connect to the ollama API served locally outside the container
- `--gpus=all` passes our GPU into the container (requires the container toolkit, which we installed). However, if Docker hangs up while running open-webui, consider removing
this flag first.  
- `--volume` (or `-v`) to mount 2 bind type volumes:
  - `ollama`'s model data (`/var/lib/ollama:/root/.ollama` (default) or `/somewhere/else/ollama:/root/.ollama` (custom)) which maps the directory with data used by the ollama service. We do not use `ollama:/root/.ollama` stated by the `open-webui` repo `README.md` since `ollama` was already installed separately before installing `open-webui`.
  - `open-webui`'s data (`open-webui:/app/backend/data` (default) or `/somewhere/else/open-webui:/app/backend/data` (custom)). This keeps all logs, knowledge bases and chat histories from `open-webui` in this directory.
  - It is important to note because these 2 volumes are bind-mounts of an existing local directory, they will not be listed in `docker volume ls`.
  - To verify that the 2 bind-mount volumes are created, use `docker inspect open-webui --format '{{range .Mounts}}{{printf "%s: %s\n" .Type (or .Name .Source)}}{{end}}'` to verify both bind type volumes are mounted. 

- Optional: `--restart always` if open-webui should be started on boot. However, it is excluded because we want to manually switch on every time. Set to `--restart no` if you want to use `systemctl` to handle starting on boot.
- Adding a release tag:
  - Cuda release: Uses CUDA driver to use your GPU acceleration
  - Stable release: Using the `:ollama` tag provides `ollama` support out of the box. This is not necessary since we have already installed `ollama` separately via pacman and plan to separate `ollama` from `open-webui`
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
ExecStart=/usr/bin/docker start open-webui
ExecStop=/usr/bin/docker stop open-webui

[Install]
WantedBy=multi-user.target
```

Check if docker automatically already starts `open-webui` or if you have set `--restart always` when running the open-webui image for the first time above:

```sh
# Checks if open-webui will restart automatically
docker ps -a --format '{{.Names}}' | while read name; do policy=$(docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' "$name"); echo "$name: $policy"; done
# If you see "open-webui: always" and want to always only manually start docker or leave it to `systemctl`:
docker update --restart=no open-webui
# Now when checking it you should see "open-webui: no"
```

```sh
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now ollama.service open-webui.service
systemctl status ollama
systemctl status open-webui
```

## If models disappear from custom `ollama` location

Check to see if there are sufficient permissions for `ollama` as a user, especially if `/var/lib/ollama` is symbolically linked to the custom `ollama` location.

Check if symbolic link to `ollama` custom location has not been replaced by a plain folder, which will happen if `ollama` was reinstalled.

```sh
sudo chown ollama:ollama /var/lib/ollama
sudo chmod 755 /custom/location/to/ollama
```

## Removing `open-webui` (and `ollama`) for a clean reset

```sh
docker stop open-webui
docker container open-webui
docker rmi $OPEN_WEBUI_HASH
```
If either commands result in a `"Error response from daemon: conflict: unable to delete <image hash>` (must be forced) - image is being used by stopped container <container hash>", try flushing all dangling containers first:
```sh
docker container prune
# Add `--all` flag to list both running and stopped or exited containers
docker ps -a
# In the event the above does not work even though the container is
# not longer listed, use a `--force` flag:
docker container prune -f
```

If you need to also remove the locally stored knowledge base and saved training data:
```sh
docker volume prune
```

## Updating `open-webui`

Stop and remove any existing containers.

```sh
docker stop open-webui
docker rm open-webui
```

Optional if space is a constraint. Remove any old images used previously.

```sh
docker rmi ghcr.io/open-webui/open-webui:cuda
```

Pull the latest image.

```sh
docker pull ghcr.io/open-webui/open-webui:cuda
```
