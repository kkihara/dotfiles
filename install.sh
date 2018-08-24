#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -e "$HOME/.tmux.conf" ]; then mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bkp"; fi
if [ -e "$HOME/.tmux.conf.local" ]; then mv "$HOME/.tmux.conf.local" "$HOME/.tmux.conf.local.bkp"; fi
if [ -e "$HOME/.vimrc" ]; then mv "$HOME/.vimrc" "$HOME/.vimrc.bkp"; fi
if [ -e "$HOME/.vim" ]; then mv "$HOME/.vim" "$HOME/.vim.bkp"; fi

ln -s "$DIR/tmux/tmux.conf.symlink" ~/.tmux.conf
ln -s "$DIR/tmux/tmux.conf.local.symlink" ~/.tmux.conf.local
ln -s "$DIR/vim/vimrc.symlink" ~/.vimrc
ln -s "$DIR/vim/vimfolder.symlink/" ~/.vim
ln -s "$DIR/bash/sshrc" ~/.ssh/rc

# Package dependencies / OS specific stuff
if uname -s | grep --quiet Linux; then
    # YouCompleteMe
    sudo apt-get install -y build-essential cmake
    sudo apt-get install -y python-dev python3-dev python-pip python3-pip

    # tmux
    sudo apt-get install -y automake
    sudo apt-get install -y build-essential
    sudo apt-get install -y pkg-config
    sudo apt-get install -y libevent-dev
    sudo apt-get install -y libncurses5-dev

    # Neovim
    sudo apt-get install software-properties-common
    sudo add-apt-repository ppa:neovim-ppa/stable
    sudo apt-get update
    sudo apt-get install -y neovim
    sudo update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 60
    sudo update-alternatives --config vi
    sudo update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 60
    sudo update-alternatives --config vim
    sudo update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 60
    sudo update-alternatives --config editor

    # ag
    sudo apt-get install silversearcher-ag

    # rg
    # Find updates here: https://github.com/BurntSushi/ripgrep/releases/latest
    curl -LO https://github.com/BurntSushi/ripgrep/releases/download/0.8.1/ripgrep_0.8.1_amd64.deb
    sudo dpkg -i ripgrep_0.8.1_amd64.deb
else
    # Install Homebrew
    which -s brew
    if [[ $? != 0 ]] ; then
        echo "Install homebrew..."
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    else
        echo "Skipping homebrew. Already installed..."
    fi

    # Install xquartz
    which -s xterm
    if [[ $? != 0 ]] ; then
        echo "Installing xquartz..."
        brew install caskroom/cask/brew-cask
        brew cask install xquartz
    else
        echo "Skipping xquartz. Already installed..."
    fi

    # tmux-vim copy
    if ! brew info reattach-to-user-namespace &> /dev/null; then
        echo "Installing reattach-to-user-namespace..."
        brew install reattach-to-user-namespace
    else
        echo "Skipping reattach-to-user-namespace. Already installed..."
    fi

    # Neovim
    which -s nvim
    if [[ $? != 0 ]] ; then
        echo "Installing neovim..."
        brew install neovim
    else
        echo "Skipping neovim. Already installed..."
    fi

    # tmux dependencies: aclocal and libevent
    if ! brew info automake &> /dev/null; then
        echo "Installing automake..."
        brew install automake
    else
        echo "Skipping automake. Already installed..."
    fi
    if ! brew info libevent &> /dev/null; then
        echo "Installing libevent..."
        brew install libevent
    else
        echo "Skipping libevent. Already installed..."
    fi

    # ripgrep
    which -s rg
    if [[ $? != 0 ]] ; then
        echo "Installing ripgrep..."
        brew install ripgrep
    else
        echo "Skipping ripgrep. Already installed..."
    fi
fi

# Neovim
mkdir -p "$HOME/.config"
ln -s ~/.vim ~/.config/nvim
ln -s ~/.vimrc ~/.config/nvim/init.vim

pip install neovim

# Install plugins from Vundle
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall

# YouCompleteMe
cd ~/.vim/bundle/YouCompleteMe
./install.py --clang-completer
cd $OLDPWD

# .bashrc additions
ln -s "$DIR/bash/bashrc" "$HOME/.bashrc.local"
ln -s "$DIR/bash/aliases.sh" "$HOME/.aliases.sh"
echo "source $HOME/.bashrc.local" >> "$HOME/.bashrc"

# pylint
ln -s "$DIR/pylintrc" ~/.pylintrc

# .gitconfig
ln -s "$DIR/gitconfig" ~/.gitconfig

# tmux 2.6
git clone https://github.com/tmux/tmux.git ~/tmux
cd ~/tmux
git reset --hard 2c6af068d7f024b3c725777f78ee4feb1813bcf9
sh autogen.sh
if uname -s | grep --quiet Linux; then
    ./configure && make
else
    ./configure CFLAGS="-I/usr/local/include" LDFLAGS="-L/usr/local/lib" && make
fi
cp ./tmux /usr/local/bin/tmux
cd $OLDPWD
rm -rf ~/tmux
