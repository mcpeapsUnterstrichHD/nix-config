#!/bin/sh

# synchronizing dotfiles
sudo stow .

nixos-rebuild switch --use-remote-sudo
