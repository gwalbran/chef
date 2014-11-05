#!/bin/bash

echo "Installing Homebrew"
ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)"

echo "Installing git via homebrew"
brew install git

echo "Installing rbenv"
brew install rbenv
brew install ruby-build

echo "Installing ruby -v 1.9.3"
rbenv install 1.9.3-p392

rbenv rehash

echo "Installing Chef gem"
gem install chef --no-rdoc --no-ri
rbenv rehash

echo "Installing Berkshelf gem"
gem install berkshelf --no-rdoc --no-ri
rbenv rehash
