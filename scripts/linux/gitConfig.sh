#!/usr/bin/env bash
set -e
set -o pipefail
set -o xtrace

lUserName=$(git config --global user.name || true)
lUserName=${1:-$lUserName}
lUserName=${lUserName:-Luca Guzzon}

lUserMail=$(git config --global user.email || true)
lUserMail=${2:-$lUserMail}
lUserMail=${lUserMail:-luca.guzzon@gmail.com}

git config --global user.name "${lUserName}"
git config --global user.email "${lUserMail}"

# https://stackoverflow.com/questions/2596805/how-do-i-make-git-use-the-editor-of-my-choice-for-commits#2596835
git config --global core.editor "vim"

git config --global url."https://".insteadOf git://
git config --global url."https://github.com/".insteadOf git@github.com:

git config --global --replace-all alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
git config --global --replace-all alias.lg-ascii "log --graph --pretty=format:'%h -%d %s (%cr) <%an>' --abbrev-commit"

# https://githowto.com/setup
# git config --global core.autocrlf true
# original --> git config --global core.safecrlf true
# git config --global core.safecrlf warn

# https://stackoverflow.com/questions/2517190/how-do-i-force-git-to-use-lf-instead-of-crlf-under-windows#13154031
git config --global --replace-all core.autocrlf false
git config --global --replace-all core.eol lf
# ma be in a single repo -> git config core.eol auto

git config --global --replace-all alias.co "checkout"
git config --global --replace-all alias.ci "commit"
git config --global --replace-all alias.st "status"
git config --global --replace-all alias.sti "status --ignored"
git config --global --replace-all alias.br "branch"
git config --global --replace-all alias.brs "branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate"
git config --global --replace-all alias.undo "reset HEAD~1 --mixed"
git config --global --replace-all alias.rst "reset --hard"

# https://switowski.com/git/2019/01/18/7-git-functions-to-make-your-life-easier.html
git config --global --replace-all alias.aliases "!git config --get-regexp alias | sort | more"
git config --global --replace-all alias.squash '!f(){ git reset --soft HEAD~${1} && git commit --edit -m"$(git log --format=%B --reverse HEAD..HEAD@{1})"; }; f'

# https://github.com/durdn/cfg/blob/master/.gitconfig
git config --global --replace-all alias.sqc '!f(){ git reset --soft HEAD~$1 && git commit --edit -m"$(git log --format=%B --reverse HEAD..HEAD@{1})"; }; f'

# https://www.freecodecamp.org/news/how-to-use-git-aliases/
git config --global --replace-all alias.graph "log --oneline --graph --decorate"
git config --global --replace-all alias.ls "log --pretty=format:'%C(yellow)%h%Cred%d - %Creset%s%Cblue - [%cn]' --decorate"
git config --global --replace-all alias.ll "log --pretty=format:'%C(yellow)%h%Cred%d - %Creset%s%Cblue - [%cn]' --decorate --numstat"
git config --global --replace-all alias.lds "log --pretty=format:'%C(yellow)%h - %ad%Cred%d - %Creset%s%Cblue - [%cn]' --decorate --date=short"
git config --global --replace-all alias.conflicts "diff --name-only --diff-filter=U"
git config --global --replace-all alias.brl "!git branch -vv | cut -c 3- | awk '\$3 !~/\\[/ { print \$1 }'"
git config --global --replace-all alias.brr "!git branch --sort=-committerdate | head"
git config --global --replace-all alias.authors "!git log --format='%aN <%aE>' | grep -v 'users.noreply.github.com' | sort -u --ignore-case"

# https://git-scm.com/docs/git-credential-cache
# Setting to half an hour
git config --global --replace-all credential.helper 'cache --timeout=3600'

# See also
#   https://github.com/nvie/git-toolbelt
#   Bash Prompt
#   https://gist.github.com/eliotsykes/47516b877f5a4f7cd52f#gistcomment-2835293
#   https://github.com/magicmonty/bash-git-prompt
#   https://gist.github.com/eliotsykes/47516b877f5a4f7cd52f
#   https://snyk.io/blog/10-git-aliases-for-faster-and-productive-git-workflow/

# https://github.com/lguzzon/sexy-bash-prompt
(cd /tmp \
  && touch ~/.bash_profile \
  && touch ~/.bashrc \
  && (rm -Rf sexy-bash-prompt || true) \
  && git clone --depth 1 --config core.autocrlf=false https://github.com/twolfson/sexy-bash-prompt \
  && cd sexy-bash-prompt \
  && make install \
  && cd .. \
  && rm -Rf sexy-bash-prompt) \
  && echo Restart shell to see new promt
