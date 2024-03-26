## How to use chezmoi to make changes

To modify the source dot files, you can either:
Update the source state dotfile directly at

```git
~/.local/share/chezmoi/dot_zshrc
```

OR
A quick way to do so is to use the

```git
chezmoi edit ~/.zshrc command
```

## How to apply above changes to source dotfiles

```git
# To view the diff between ~/.local/share/chezmoi/dot_zshrc & ~/.zshrc
chezmoi diff

# To apply the changes to your original ~/.zshrc
chezmoi -v apply
```

## Committing and pushing to GitHub (again)

```git
chezmoi cd
git add .
git commit -m "<Your update commit message>"
git push -u origin main
```

## Adding new dotfiles

```git
chezmoi add ~/.newdotfile
chezmoi cd
git add .
git commit -m "<New dotfile commit message>"
git push -u origin main
```
