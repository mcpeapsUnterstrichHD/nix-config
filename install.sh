#!/bin/sh
#only run this on linux
#only run this on fresh install
# synchronizing dotfiles
sudo stow .

nixos-rebuild switch --use-remote-sudo
