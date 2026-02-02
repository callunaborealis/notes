# Print system info

Generates full system tree

```sh
sudo pacman -S neofetch lshw

path_to_file=/home/calluna/Desktop
touch $path_to_file/full-lshw.txt
touch $path_to_file/system-info.txt
# Print full system tree
sudo lshw -sanitize > $path_to_file/full-lshw.txt
# Print system info
neofetch --off > $path_to_file/system-info.txt && echo -e "\n\n# Detailed Hardware Info\n" >> $path_to_file/system-info.txt && sudo inxi -Fazxx >> $path_to_file/system-info.txt
```