### START

USE_CURRENT_DIR_AS_HOME=$1

### Set remote user stuff

if [[ $USE_CURRENT_DIR_AS_HOME ]] ; then
    [[ $REMOTE_USER   ]] || export REMOTE_USER=$(basename $PWD)
    [[ $REMOTE_HOME   ]] || export REMOTE_HOME=$PWD
else
    [[ $REMOTE_USER   ]] || export REMOTE_USER=$USER
    [[ $REMOTE_HOME   ]] || export REMOTE_HOME=$HOME
fi

[[ $REMOTE_BASHRC ]] || export REMOTE_BASHRC="$REMOTE_HOME/.bashrc"
[[ $REMOTE_HOST   ]] || export REMOTE_HOST=${SSH_CLIENT%% *}

### Path

if [[ ! $BASHRC_PATH_ORG ]] ; then
  BASHRC_PATH_ORG=$PATH
fi

unset PATH
if [[ $REMOTE_HOME != $HOME ]] ; then
    PATH=$REMOTE_HOME/.bin:$REMOTE_HOME/bin:
fi
PATH+=~/.bin:~/bin:~/opt/bin
PATH+=:./node_modules/.bin
# PATH+=:~/node_modules/bin
PATH+=:$BASHRC_PATH_ORG
export PATH

# Replace proxy env when using a tunneled ssh proxy
if [[ $ssh_remote_proxy ]] ; then

    http_proxy=http://$ssh_remote_proxy
    https_proxy=http://$ssh_remote_proxy
    ftp_proxy=ftp://$ssh_remote_proxy

    HTTP_PROXY=http://$ssh_remote_proxy
    HTTPS_PROXY=http://$ssh_remote_proxy
    FTP_PROXY=ftp://$ssh_remote_proxy
fi

### Run local rc scripts

if [ -d $REMOTE_HOME/.bashrc.d ] ; then
    for rc in $(ls $REMOTE_HOME/.bashrc.d/* 2>/dev/null) ; do
        source $rc
    done
fi

### Checking if running inside docker

grep docker /proc/1/cgroup &>/dev/null && export BASHRC_INSIDE_DOCKER=1

### Return if not an interactive shell

[[ $PS1 ]] || return

### Env

BASHRC_COLOR_NO_COLOR='\[\e[33;0;m\]'
BASHRC_COLOR_GREEN='\[\e[38;5;2m\]'
BASHRC_BG_COLOR=$BASHRC_COLOR_NO_COLOR

if [[ "$LANG" =~ utf || "$LANG" =~ UTF ]] ; then
    # all good
    true
else
    _available_locales=$(locale -a 2>/dev/null)
    if [[ "$_available_locales" =~ "en_US.utf8" ]] ; then
        LANG="en_US.utf8"
    fi
    unset _available_locales
fi

if [[ ! "$LANG" ]] ; then
    LANG=C
fi

# use english messages on the command line
export LC_MESSAGES=C

export BROWSER=links

# remove domain from hostname if necessary
HOSTNAME=${HOSTNAME%%.*}

export LINES COLUMNS

export BASHRC_TTY=$(tty)

export FTP_PASSIVE=1


### Input config

export INPUTRC=$REMOTE_HOME/.inputrc

# set vi edit mode
bind 'set editing-mode vi'

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# case insensitive pathname expansion
shopt -s nocaseglob

# turn off beeping
bind 'set bell-style none'
# xset b off

# keep original version of edited history entries
bind 'set revert-all-at-newline on'

# add slash to symlinks to directoryies on tab completion
bind 'set mark-symlinked-directories on'

# skip directories starting with a dot from tab completion
bind 'set match-hidden-files off'

# case insensitive tab completion
bind 'set completion-ignore-case on'

# treat - and _ as equal in completion
bind 'set completion-map-case on'

# show common postfixes in completion
bind 'set completion-prefix-display-length 1'

# tab completion with single tab (don't ring the bell)
bind 'set show-all-if-ambiguous on'

# don't duplicate completed part off already complete term when within a term
bind 'set skip-completed-text on'

# never ask to show all completions - just do
bind 'set completion-query-items -1'

# don't show completions in pager
bind 'set page-completions off'

# don't expand tilde - disables e-key?!?
# bind 'tilde-expand off'

# expand hi to underscores
set 'completion-map-case on'

# do not attempt to search the PATH for possible completions
# when completion is attempted on an empty line
shopt -s no_empty_cmd_completion

# reenable ctrl+s for forward history search (XOFF)
stty stop ^-

# reenable ctrl+q (XON)
stty start ^-

# ctrl-l clear screen but stay in current row
bind -x '"\C-l":printf "\33[2J"'

### Aliases

alias    ls='ls --color=auto --time-style=+"%a %F %H:%M" -v '
alias     l='ls -1'
alias    ll='ls -lh'
alias    lr='ls -rt1'
alias   llr='ls -rtlh'
alias    lc='ls -rtlhc'
alias    la='ls -1d \.*'
alias   lla='ls -lhd \.*'

function lls() {
  ls -1d *$**
}

# https://github.com/seebi/dircolors-solarized
export LS_COLORS='no=00:fi=00:di=36:ln=35:pi=30;44:so=35;44:do=35;44:bd=33;44:cd=37;44:or=05;37;41:mi=05;37;41:ex=01;31:*.cmd=01;31:*.exe=01;31:*.com=01;31:*.bat=01;31:*.reg=01;31:*.app=01;31:*.txt=32:*.org=32:*.md=32:*.mkd=32:*.h=32:*.c=32:*.C=32:*.cc=32:*.cxx=32:*.objc=32:*.sh=32:*.csh=32:*.zsh=32:*.el=32:*.vim=32:*.java=32:*.pl=32:*.pm=32:*.py=32:*.rb=32:*.hs=32:*.php=32:*.htm=32:*.html=32:*.shtml=32:*.xml=32:*.json=32:*.yaml=32:*.rdf=32:*.css=32:*.js=32:*.man=32:*.0=32:*.1=32:*.2=32:*.3=32:*.4=32:*.5=32:*.6=32:*.7=32:*.8=32:*.9=32:*.l=32:*.n=32:*.p=32:*.pod=32:*.tex=32:*.bmp=33:*.cgm=33:*.dl=33:*.dvi=33:*.emf=33:*.eps=33:*.gif=33:*.jpeg=33:*.jpg=33:*.JPG=33:*.mng=33:*.pbm=33:*.pcx=33:*.pdf=33:*.pgm=33:*.png=33:*.ppm=33:*.pps=33:*.ppsx=33:*.ps=33:*.svg=33:*.svgz=33:*.tga=33:*.tif=33:*.tiff=33:*.xbm=33:*.xcf=33:*.xpm=33:*.xwd=33:*.xwd=33:*.yuv=33:*.aac=33:*.au=33:*.flac=33:*.mid=33:*.midi=33:*.mka=33:*.mp3=33:*.mpa=33:*.mpeg=33:*.mpg=33:*.ogg=33:*.ra=33:*.wav=33:*.anx=33:*.asf=33:*.avi=33:*.axv=33:*.flc=33:*.fli=33:*.flv=33:*.gl=33:*.m2v=33:*.m4v=33:*.mkv=33:*.mov=33:*.mp4=33:*.mp4v=33:*.mpeg=33:*.mpg=33:*.nuv=33:*.ogm=33:*.ogv=33:*.ogx=33:*.qt=33:*.rm=33:*.rmvb=33:*.swf=33:*.vob=33:*.wmv=33:*.doc=31:*.docx=31:*.rtf=31:*.dot=31:*.dotx=31:*.xls=31:*.xlsx=31:*.ppt=31:*.pptx=31:*.fla=31:*.psd=31:*.7z=1;35:*.apk=1;35:*.arj=1;35:*.bin=1;35:*.bz=1;35:*.bz2=1;35:*.cab=1;35:*.deb=1;35:*.dmg=1;35:*.gem=1;35:*.gz=1;35:*.iso=1;35:*.jar=1;35:*.msi=1;35:*.rar=1;35:*.rpm=1;35:*.tar=1;35:*.tbz=1;35:*.tbz2=1;35:*.tgz=1;35:*.tx=1;35:*.war=1;35:*.xpi=1;35:*.xz=1;35:*.z=1;35:*.Z=1;35:*.zip=1;35:*.ANSI-30-black=30:*.ANSI-01;30-brblack=01;30:*.ANSI-31-red=31:*.ANSI-01;31-brred=01;31:*.ANSI-32-green=32:*.ANSI-01;32-brgreen=01;32:*.ANSI-33-yellow=33:*.ANSI-01;33-bryellow=01;33:*.ANSI-34-blue=34:*.ANSI-01;34-brblue=01;34:*.ANSI-35-magenta=35:*.ANSI-01;35-brmagenta=01;35:*.ANSI-36-cyan=36:*.ANSI-01;36-brcyan=01;36:*.ANSI-37-white=37:*.ANSI-01;37-brwhite=01;37:*.log=01;32:*~=01;32:*#=01;32:*.bak=01;36:*.BAK=01;36:*.old=01;36:*.OLD=01;36:*.org_archive=01;36:*.off=01;36:*.OFF=01;36:*.dist=01;36:*.DIST=01;36:*.orig=01;36:*.ORIG=01;36:*.swp=01;36:*.swo=01;36:*,v=01;36:*.gpg=34:*.gpg=34:*.pgp=34:*.asc=34:*.3des=34:*.aes=34:*.enc=34:';

alias f=find-and
alias g=find-or-grep

alias cdt='cd $REMOTE_HOME/tmp'
function cdh() { cd $(cd-history $@) ; } 
function cdf() { cd $(cd-find $@) ; } 

alias type='type -a'

alias shell-turn-off-line-wrapping="tput rmam"
alias shell-turn-on-line-wrapping="tput smam"

alias cp="cp -i"
alias mv="mv -i"
alias df="df -h"
alias du="du -sch"
alias crontab="crontab -i"
alias xargs='xargs -I {} -d \\n'

function apts() { apt-cache search --names-only "$1" | g "$@" | less ; }
alias aptg="apt search"
alias aptw="apt show"
alias apti="sudo apt install"
alias aptp="sudo dpkg -P"
alias aptc="sudo apt-get autoremove"
alias apt-list-package-contents="dpkg -L"
alias apt-find-package-containing="dpkg -S"
alias apt-list-installed="apt list --installed | g"

alias normalizefilenames="xmv -ndx"
alias m=man-multi-lookup
alias srd=tmux-reattach

alias ps-grep="pgrep -fl"
alias ps-attach="sudo strace -ewrite -s 1000 -p"
alias pgrep="pgrep -af"

alias p=pstree-search
if [[ ! $(type -t pstree) ]] ; then
    alias p="ps axjf"
fi

alias top="top -c"
alias rsync="rsync -h"

function  j() { jobs=$(jobs) bash-jobs ; }
function  t() { tree -C --summary "$@" | less ; }
function td() { tree -d "$@" | less ; }
function csvview() { command csvview "$@" | LESS= less -S ; }

### Vim and less

EDITOR=vi
if [[ $REMOTE_HOST ]] ; then
    EDITOR="DISPLAY= $EDITOR"
fi

export EDITOR
export VISUAL="$EDITOR"

alias v=vi-choose-file-from-list
alias vie=vi-from-path
alias vif=vi-from-find
alias vih=vi-from-history

export LESS="-j0.5 -inRgS"
# Make less more friendly for non-text input files, see lesspipe(1)
if [[ $(type -p lesspipe ) ]] ; then
    eval "$(lesspipe)"
fi
export PAGER=less

export MANWIDTH=80

### Misc

# Get parent process id
function parent() {
    # ps can not deal with PID 0 which might be set when running inside docker
    if [[ $PPID = 0 ]] ; then
        return
    fi
    echo $(ps -p $PPID -o comm=)
}

### Xorg

if [[ $DISPLAY ]] ; then

    # make windows blink when prompt reappears
    if [[ $(type -p wmctrl) ]] ; then
      export BASHRC_PROMPT_WMCTRL=window-blink
    fi

    export BROWSER=firefox
fi

### SSH

# ServerAliveInterval=5 make sure there is ssh traffic so no firewall closes
#     the connection
# GSSAPIAuthentication=no - usually not used - speeds up connection time
alias ssh="ssh -AC -o GSSAPIAuthentication=no -o ServerAliveInterval=5"

function _ssh_completion() {
    perl -ne 'print "$1 " if /^Host (.+)$/' $REMOTE_HOME/.ssh/config
}

if [[ -e $REMOTE_HOME/.ssh/config ]] ; then
    complete -W "$(_ssh_completion)" ssh scp ssh-with-reverse-proxy sshfs \
        sshnocheck sshtunnel vncviewer
    complete -fdW "$(_ssh_completion)" scp
fi

function fixssh() {
    eval $(ssh-agent-env-restore)
}

function nossh() {
    source ssh-agent-env-clear
}

### History

# ignore commands  for history that start  with a space
HISTCONTROL=ignorespace:ignoredups
# HISTIGNORE="truecrypt*:blubb*"
# HISTTIMEFORMAT="[ %Y-%m-%d %H:%M:%S ] "

# Make Bash append rather than overwrite the history on disk
shopt -s histappend

# prevent history truncation
unset HISTFILESIZE

# echo $REMOTE_HOME
export HISTFILE_ETERNAL=$REMOTE_HOME/.bash_eternal_history

if [ ! -e $HISTFILE_ETERNAL ] ; then
    touch $HISTFILE_ETERNAL
    chmod 0600 $HISTFILE_ETERNAL
fi

# TODO: do at logout?
history -a

alias h="bash-eternal-history-search -e -s"

function bashrc-eternal-history-add() {

    if [[ "$PRIVATE_SHELL" ]] ; then
        return
    fi

    local pos
    local cmd
    read -r pos cmd <<<$(history 1)

    [[ "$PREVIOUS_COMMAND" == "$cmd" ]] && return
    [[ "$PREVIOUS_COMMAND" ]] || PREVIOUS_COMMAND="$cmd"
    PREVIOUS_COMMAND="$cmd"

    if [[ "$cmd" == "rm "* ]] ; then
        cmd="# $cmd"
        history -s "$cmd"
    fi

    local quoted_pwd=${PWD//\"/\\\"}

    local line="$USER"
    line="$line $(date +'%F %T')"
    line="$line $BASHPID"
    line="$line \"$quoted_pwd\""
    line="$line \"$BASHRC_PIPE_STATUS\""
    line="$line $cmd"
    echo "$line" >> $HISTFILE_ETERNAL
}

### PROMPT

# This is the default prompt command which is always set.
# It sets some variables to be used by the specialized command prompts.
function bashrc-prompt-command() {

    BASHRC_PIPE_STATUS="${PIPESTATUS[*]}"

    bashrc-eternal-history-add

    [[ $BASHRC_TIMER_START ]] || BASHRC_TIMER_START=$SECONDS

    PS1=$(
        elapsed=$(($SECONDS - $BASHRC_TIMER_START)) \
        jobs=$(jobs) \
        BASHRC_PROMPT_COLORS=1 \
        BASHRC_PROMPT_HELPERS=$BASHRC_PROMPT_HELPERS \
        $BASHRC_PROMPT_COMMAND
    )"$BASHRC_BG_COLOR"

    $BASHRC_PROMPT_WMCTRL

    pipe_status=$BASHRC_PIPE_STATUS bash-print-on-error

    BASHRC_TIMER_START=$SECONDS
}

# Add a helper command to display in the prompt
function prompt-helper-add() {

    cmd=${1?Specify helper command}

    if [[ $BASHRC_PROMPT_HELPERS ]] ; then
        BASHRC_PROMPT_HELPERS=$BASHRC_PROMPT_HELPERS";"
    fi

    BASHRC_PROMPT_HELPERS="$BASHRC_PROMPT_HELPERS""prefixif \$($@)"
}

# Remove all helpers
function prompt-helper-remove-all() {

    unset BASHRC_PROMPT_HELPERS
}

# Set the specified prompt or guess which one to set
function prompt-set() {

    local prompt=$1

    PROMPT_COMMAND=bashrc-prompt-command

    if [[ $prompt ]] ; then

        if [[ $(type -p prompt-$prompt) ]] ; then
            BASHRC_PROMPT_COMMAND=prompt-$prompt
            return
        fi

        if [[ $(type -p prompt-helper-$prompt) ]] ; then
            prompt-helper-add prompt-helper-$prompt
            return
        fi

        echo "Prompt not found $prompt" >&2
        return 1
    fi

    if [[ $(parent) =~ (screen|screen.real|tmux) ]] ; then
        BASHRC_PROMPT_COMMAND=prompt-local
        return
    fi

    if [[ $REMOTE_HOST || $BASHRC_INSIDE_DOCKER ]] ; then
        BASHRC_PROMPT_COMMAND=prompt-host
        return
    fi

    BASHRC_PROMPT_COMMAND=prompt-local
}

# cd to dir used last before logout
function bashrc-set-last-session-pwd() {

    if [[ $BASHRC_IS_LOADED ]] ; then
        return
    fi

    local LAST_PWD=$(bash-eternal-history-search -d -c 1 --existing-only | tail -1)
            OLDPWD=$(bash-eternal-history-search -d -c 2 --existing-only)

    if [[ $LAST_PWD ]] ; then
        cd "$LAST_PWD"
    elif [[ -d "$REMOTE_HOME" ]] ; then
        cdh
    fi
}

# Turn of history for testing passwords etc
function shell-private() {
    export PRIVATE_SHELL=1
    unset HISTFILE
    BASHRC_BG_COLOR=$BASHRC_COLOR_GREEN
}

### bashrc handling

function bashrc-clean-env() {

    unset PROMPT_COMMAND

    # remove aliases
    unalias -a

    # remove functions
    while read funct ; do
        unset -f $funct
    done<<EOF
        $(perl -ne 'foreach (/^function (.+?)\(/) {print "$_\n" }' $REMOTE_BASHRC)
EOF
}

function bashrc-update() {
    (
        set -e
        cd $REMOTE_HOME
        mkdir -p $REMOTE_HOME/.bashrc.d
        wcat https://raw.githubusercontent.com/nilsboy/bashrc/master/bashrc \
          -o .bashrc
    )
    bashrc-reload
    bashrc-unpack
}

function bashrc-reload() {
    bashrc-clean-env
    source $REMOTE_BASHRC
}

# Unpack scripts fatpacked to this bashrc
function bashrc-unpack() {

    if [[ -d $REMOTE_HOME/.bin ]] ; then
       rm $REMOTE_HOME/.bin -rf
    fi

    perl - $@ <<'EOF'
        use strict;
        use warnings;

        $/ = undef;
        open(my $f, $ENV{REMOTE_BASHRC}) || die $!;
        my $bashrc = <$f>;

        my $home = $ENV{REMOTE_HOME} || die "REMOTE_HOME not set";
        my $dst_dir = $ENV{REMOTE_HOME} . "/.bin";

        system("mkdir -p $dst_dir") && die $!;

        print STDERR "Exporting apps to $dst_dir...\n";

        my $export_count = 0;
        while ($bashrc =~ /^### fatpacked app ([\w-]+) #*$(.+?)(?=\n^### fatpacked app)/igsm) {

            my $app_name = $1;
            my $app_data = $2;

            $app_data =~ s/^\s+//g;

            my $app_file_name = "$dst_dir/$app_name";

            # print STDERR "Exporting $app_name to $app_file_name...\n";

            open(my $APP_FILE, ">", $app_file_name) || die $!;
            print $APP_FILE $app_data;

            chmod(0755, $app_file_name) || die $!;

            $export_count++;
        }

        print STDERR "Done - $export_count apps exported.\n";
EOF

}

### STARTUP

[ -e "$REMOTE_HOME/.bin" ] || bashrc-unpack

eval $(linux-distribution-info)
if [[ $DISTRIB_ID ]] ; then
  fix_file=bashrc-linux-distribution-fix-$DISTRIB_ID
  if [[ $(type -t $fix_file) ]] ; then
      source $fix_file
  fi
fi

prompt-set
bashrc-set-last-session-pwd

export BASHRC_IS_LOADED=1

# test -n "$REMOTE_HOST" && srd

true

### END
return 0
### fatpacked apps start here
