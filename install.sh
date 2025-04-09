#!/bin/sh
#only run this on linux
#only run this on fresh install
# synchronizing dotfiles
stow -t /etc/nixos . --adopt
