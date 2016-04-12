#!/bin/bash
set -ue

helpmsg(){
    echo "Usage: $0 [install | update] [--help | --force]" 0>&2
    echo '  install:  add require package install and symbolic link to $HOME from dotfiles'
    echo '  update: add require package install or update. [default]'
    echo "  --: force overwrite"
    echo "  --force: force overwrite"
    echo ""
}

# コマンドの存在確認
chkcmd(){
    if ! type "$1";then
        echo "${1}コマンドが見つかりません"
        exit
    fi
}

yes_or_no_select() {
    echo "Are you ready? [yes/no]"
    read answer
    case $answer in
        yes|y)
            return 0
            ;;
        no|n)
            return 1
            ;;
        *)
            yes_or_no_select
            ;;
    esac
}

whichdistro() {
    #which yum > /dev/null && { echo redhat; return; }
    #which zypper > /dev/null && { echo opensuse; return; }
    #which apt-get > /dev/null && { echo debian; return; }
    if [ -f /etc/debian_version ]; then
        echo debian; return;
    elif [ -f /etc/redhat-release ] ;then
        echo redhat; return;
    fi
}

checkinstall(){
    for PKG in "$@";do
        if ! type "$PKG" > /dev/null 2>&1; then
            if [[ $DISTRO == "debian" ]];then
                sudo apt-get install -y $PKG
            elif [[ $DISTRO == "redhat" ]];then
                sudo yum install -y $PKG
            else
                :
            fi
        fi
    done
}

install_neobundle(){
    # ファイルの存在確認
    neobundle_dir="$HOME/.vim/bundle/neobundle.vim"
    if [ ! -f "$neobundle_dir/README.md" ];then
        echo "Installing NeoBundle.."
        echo ""
        mkdir -p "$HOME/.vim/bundle"
        git clone https://github.com/Shougo/neobundle.vim.git $neobundle_dir
    else
        echo "Pulling NeoBundle.."
        (cd $neobundle_dir; git pull origin master)
    fi
}

install_vim_plug(){
    # ファイルの存在確認
    vim_plug_dir="$HOME/.vim/plugged/vim-plug"
    if [ ! -d "$vim_plug_dir" ];then
        echo "Installing vim-plug.."
        echo ""
        mkdir -p $vim_plug_dir
        git clone https://github.com/junegunn/vim-plug.git \
            $vim_plug_dir/autoload
    else
        echo "Pulling vim-plug.."
        (cd $vim_plug_dir/autoload; git pull origin master)
    fi
}

install_dein(){
    # ファイルの存在確認
    dein_dir="$HOME/.vim/dein/repos/github.com/Shougo/dein.vim"
    if [ ! -f "$dein_dir/README.md" ];then
        echo "Installing dein.."
        echo ""
        mkdir -p $dein_dir
        git clone https://github.com/Shougo/dein.vim.git \
            $dein_dir
    else
        echo "Pulling dein.."
        (cd $dein_dir; git pull origin master)
    fi
}

install_antigen(){
    # ファイルの存在確認
    zsh_antigen="$HOME/.zsh/antigen"
    if [ ! -d "$zsh_antigen" ];then
        echo "Installing antigen..."
        echo ""
        git clone https://github.com/zsh-users/antigen.git "$zsh_antigen"
    else
        echo "Pulling antigen..."
        (cd $zsh_antigen; git pull origin master)
    fi
}

install_tmux-powerline(){
    # install tmux-powerline
    tmux_powerline="$HOME/.tmux/tmux-powerline"
    if [ ! -d "$tmux_powerline" ];then
        echo "Installing tmux-powerline..."
        echo ""
        git clone https://github.com/erikw/tmux-powerline.git "$tmux_powerline"
    else
        echo "Pulling tmux-powerline..."
        (cd $tmux_powerline; git pull origin master)
    fi
}

install_tmuxinator(){
    # install tmuxinator
    if ! type tmuxinator;then
        echo "Installing tmuxinator..."
        echo ""
        if [[ $DISTRO == "debian" ]];then
            sudo apt-get install -y ruby ruby-dev
        elif [[ $DISTRO == "redhat" ]];then
            sudo yum install -y ruby ruby-devel rubygems
        else
            :
        fi
        sudo gem install tmuxinator
        mkdir -p $HOME/.tmuxinator/completion
        wget https://raw.github.com/aziz/tmuxinator/master/completion/tmuxinator.zsh -O $HOME/.tmuxinator/completion/tmuxinator.zsh
    fi
}

install_tmux-plugins(){
    # install tmux-plugins
    tmux_plugins="$HOME/.tmux/plugins/tpm"
    if [ ! -d "$tmux_plugins" ];then
        echo "Installing tmux-plugins..."
        echo ""
        mkdir -p $tmux_plugins
        git clone https://github.com/tmux-plugins/tpm $tmux_plugins
    else
        echo "Pulling tmux-plugins..."
        (cd $tmux_plugins; git pull origin master)
    fi
}

install_fzf(){
    fzf_dir="$HOME/.fzf"
    if [ ! -d "$fzf_dir" ];then
        echo "Installing fzf..."
        echo ""
        git clone --depth 1 https://github.com/junegunn/fzf.git $fzf_dir
    else
        echo "Pulling fzf..."
        (cd $fzf_dir; git pull origin master)
    fi
    $fzf_dir/install --no-key-bindings --completion  --no-update-rc
}

copy_to_homedir() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    DOTDIR=$(readlink -f ${SCRIPT_DIR}/..)
    if [[ "$HOME" != "$DOTDIR" ]];then
        echo "cp -r${FORCE_OVERWRITE} ${DOTDIR}/* ${DOTDIR}/.[^.]* $HOME"
        if yes_or_no_select; then
            cp -r${FORCE_OVERWRITE} ${DOTDIR}/* ${DOTDIR}/.[^.]* $HOME
        fi
    fi
}


link_to_homedir() {
    if [ ! -d "$HOME/dotbackup" ];then
        echo "$HOME/dotbackup not found. Auto Make it"
        mkdir "$HOME/dotbackup"
    fi

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    DOTDIR=$(readlink -f ${SCRIPT_DIR}/..)
    if [[ "$HOME" != "$DOTDIR" ]];then
        for f in $DOTDIR/.??*; do
            [[ "$f" == ".git" ]] && continue
            if [[ -e "$HOME/`basename $f`" ]];then
                #\rm -ir "$HOME/`basename $f`"
                \mv "$HOME/`basename $f`" "$HOME/dotbackup"
            fi
            ln -snf $f $HOME
        done
    fi
}


############
### main ###
############
WITHOUT_TMUX_EXTENSIONS="false"
INSTALL_MODE="false"
FORCE_OVERWRITE=""

while [ $# -gt 0 ];do
    case ${1} in
        --debug|-d)
            set -uex
        ;;
        --help|-h)
            helpmsg
            exit 1
        ;;
        install)
            INSTALL_MODE="true"
        ;;
        --with-link-to-home|-l)
            LINK_TO_HOME_MODE="true"
        ;;
        --force|-f)
            FORCE_OVERWRITE="f"
        ;;
        *)
        ;;
    esac
    shift
done


DISTRO=`whichdistro`

if [[ "$INSTALL_MODE" = true ]];then
    link_to_homedir
    #copy_to_homedir
fi

checkinstall zsh git vim tmux ctags bc wget xsel
#install_vim_plug
#install_antigen
install_tmux-plugins
install_fzf

if [[ $WITHOUT_TMUX_EXTENSIONS != "true" ]];then
    #install_tmux-powerline
    #install_tmuxinator
fi

echo ""
echo ""
echo "#####################################################"
echo -e "\e[1;36m $(basename $0) install finish!!! \e[m"
echo "#####################################################"
echo ""

