#!/bin/bash

# Save Homebrew's installed location.
BREW_PREFIX=$(brew --prefix)

brew tap homebrew/bundle

# Install brewfile
brew bundle

# Remove outdated versions from the cellar.
brew cleanup
