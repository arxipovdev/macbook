#!/bin/bash

sudo pacman -S lxappearance \
  gtk-engine-murrine \
  gtk-engines \
  gtk2-perl \
  gnome-themes-extra \
  papirus-icon-theme \
  --noconfirm

yay -S everforest-gtk-theme-git \
  bibata-cursor-theme --noconfirm

git clone https://github.com/Fausto-Korpsvart/Everforest-GTK-Theme.git
cd Everforest-GTK-Theme/icons
mkdir ~/.local/share/icons
cp -r Everforest-* ~/.local/share/icons/
