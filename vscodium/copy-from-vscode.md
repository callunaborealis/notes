```sh
code --list-extensions > ~/vscode-extensions.md
cd ~/.config/Code/User/

cp ~/.config/Code/User/settings.json ~/config/Code/VScodium/vscode-settings.json
# If any
cp ~/.config/Code/User/keybindings.json ~/vscode-keybindings.json


xargs -n1 codium --install-extension < ~/vscode-extensions.md
```