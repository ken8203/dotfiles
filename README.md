# dotfiles

> Inspired by [thoughtbot/dotfiles](https://github.com/thoughtbot/dotfiles) and [holman/dotfiles](https://github.com/holman/dotfiles)

## Requirements

Set zsh as your login shell

```
chsh -s $(which zsh)
```

## Install

Clone dotfiles

```shell
git clone https://github.com/ken8203/dotfiles.git ~/dotfiles
```

Install the dotfiles

```shell
./dotfiles/script/install
brew install rcm
./dotfiles/script/boostrap
```

## Update

```shell
./dotfiles/script/boostrap
```
