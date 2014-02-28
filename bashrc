### for all shells #############################################################

USE_CURRENT_DIR_AS_HOME=$1

PERL5LIB=~/perldev/lib

if [[ -e ~/perl5/perlbrew/etc/bashrc ]] ; then
    source ~/perl5/perlbrew/etc/bashrc
fi

if [[ ! $PERLBREW_PERL ]] ; then
    PERL5LIB=$PERL5LIB:~/perl5/lib/perl5
fi

export PERL5LIB

if [[ ! $_is_reload ]] ; then
    export PATH=~/bin:~/.bin:~/opt/bin:$PATH
fi

if [[ ! $JAVA_HOME ]] ; then
    export JAVA_HOME=/usr/lib/jvm/java-6-sun
fi

[[ $PS1 ]] || return

### for interactive shells only ################################################

if [[ $USE_CURRENT_DIR_AS_HOME ]] ; then

    [[ $REMOTE_USER   ]] || export REMOTE_USER=$(basename $PWD)
    [[ $REMOTE_HOME   ]] || export REMOTE_HOME=$PWD

else

    [[ $REMOTE_USER   ]] || export REMOTE_USER=$USER
    [[ $REMOTE_HOME   ]] || export REMOTE_HOME=$HOME
fi

[[ $REMOTE_BASHRC ]] || export REMOTE_BASHRC="$REMOTE_HOME/.bashrc"
[[ $REMOTE_HOST   ]] || export REMOTE_HOST=${SSH_CLIENT%% *}

if [[ ! $_is_reload && $REMOTE_HOME != $HOME ]] ; then
    export PATH=$REMOTE_HOME/bin:$REMOTE_HOME/.bin:$PATH
fi

################################################################################

BASHRC_COLOR_NO_COLOR='\e[33;0;m'
BASHRC_COLOR_GREEN='\e[33;0;m'
BASHRC_BG_COLOR=$BASHRC_COLOR_GREEN

export LANG="de_DE.UTF-8"
# export LC_ALL="de_DE.UTF-8"
# export LC_CTYPE="de_DE.UTF-8"

# use english messages on the command line
export LC_MESSAGES=C

export BROWSER=links

# remove domain from hostname if necessary
HOSTNAME=${HOSTNAME%%.*}

# set distribution info

if [[ -e /etc/lsb-release ]] ; then
    . /etc/lsb-release
    DISTRIBUTION=${DISTRIB_ID,,}
elif [[ -e /etc/debian_version ]] ; then
    DISTRIBUTION=debian
else
    DISTRIBUTION=$(cat /etc/*{version,release} 2>/dev/null \
        | perl -0777 -ne 'print lc $1 if /(debian|suse|redhat)/igm')
fi

export DISTRIBUTION
export LINES COLUMNS

export _bashrc_tty=$(tty)

export FTP_PASSIVE=1

### input config ###############################################################

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

### aliases ####################################################################

export VIM_HOME=$REMOTE_HOME/.vim

EDITOR="vi"
if [[ $REMOTE_HOST ]] ; then
    EDITOR="DISPLAY= $EDITOR"
fi

if [[ -e $VIM_HOME/vimrc ]] ; then
    EDITOR="$EDITOR -u $VIM_HOME/vimrc"
else
    EDITOR="$EDITOR -i $REMOTE_HOME/._viminfo"
fi

export EDITOR
alias vi=$EDITOR
export VISUAL=vi

alias cp="cp -i"
alias mv="mv -i"
export LESS="-j0.5 -inRgS"
alias crontab="crontab -i"

# https://github.com/seebi/dircolors-solarized
export LS_COLORS='no=00:fi=00:di=36:ln=35:pi=30;44:so=35;44:do=35;44:bd=33;44:cd=37;44:or=05;37;41:mi=05;37;41:ex=01;31:*.cmd=01;31:*.exe=01;31:*.com=01;31:*.bat=01;31:*.reg=01;31:*.app=01;31:*.txt=32:*.org=32:*.md=32:*.mkd=32:*.h=32:*.c=32:*.C=32:*.cc=32:*.cxx=32:*.objc=32:*.sh=32:*.csh=32:*.zsh=32:*.el=32:*.vim=32:*.java=32:*.pl=32:*.pm=32:*.py=32:*.rb=32:*.hs=32:*.php=32:*.htm=32:*.html=32:*.shtml=32:*.xml=32:*.json=32:*.yaml=32:*.rdf=32:*.css=32:*.js=32:*.man=32:*.0=32:*.1=32:*.2=32:*.3=32:*.4=32:*.5=32:*.6=32:*.7=32:*.8=32:*.9=32:*.l=32:*.n=32:*.p=32:*.pod=32:*.tex=32:*.bmp=33:*.cgm=33:*.dl=33:*.dvi=33:*.emf=33:*.eps=33:*.gif=33:*.jpeg=33:*.jpg=33:*.JPG=33:*.mng=33:*.pbm=33:*.pcx=33:*.pdf=33:*.pgm=33:*.png=33:*.ppm=33:*.pps=33:*.ppsx=33:*.ps=33:*.svg=33:*.svgz=33:*.tga=33:*.tif=33:*.tiff=33:*.xbm=33:*.xcf=33:*.xpm=33:*.xwd=33:*.xwd=33:*.yuv=33:*.aac=33:*.au=33:*.flac=33:*.mid=33:*.midi=33:*.mka=33:*.mp3=33:*.mpa=33:*.mpeg=33:*.mpg=33:*.ogg=33:*.ra=33:*.wav=33:*.anx=33:*.asf=33:*.avi=33:*.axv=33:*.flc=33:*.fli=33:*.flv=33:*.gl=33:*.m2v=33:*.m4v=33:*.mkv=33:*.mov=33:*.mp4=33:*.mp4v=33:*.mpeg=33:*.mpg=33:*.nuv=33:*.ogm=33:*.ogv=33:*.ogx=33:*.qt=33:*.rm=33:*.rmvb=33:*.swf=33:*.vob=33:*.wmv=33:*.doc=31:*.docx=31:*.rtf=31:*.dot=31:*.dotx=31:*.xls=31:*.xlsx=31:*.ppt=31:*.pptx=31:*.fla=31:*.psd=31:*.7z=1;35:*.apk=1;35:*.arj=1;35:*.bin=1;35:*.bz=1;35:*.bz2=1;35:*.cab=1;35:*.deb=1;35:*.dmg=1;35:*.gem=1;35:*.gz=1;35:*.iso=1;35:*.jar=1;35:*.msi=1;35:*.rar=1;35:*.rpm=1;35:*.tar=1;35:*.tbz=1;35:*.tbz2=1;35:*.tgz=1;35:*.tx=1;35:*.war=1;35:*.xpi=1;35:*.xz=1;35:*.z=1;35:*.Z=1;35:*.zip=1;35:*.ANSI-30-black=30:*.ANSI-01;30-brblack=01;30:*.ANSI-31-red=31:*.ANSI-01;31-brred=01;31:*.ANSI-32-green=32:*.ANSI-01;32-brgreen=01;32:*.ANSI-33-yellow=33:*.ANSI-01;33-bryellow=01;33:*.ANSI-34-blue=34:*.ANSI-01;34-brblue=01;34:*.ANSI-35-magenta=35:*.ANSI-01;35-brmagenta=01;35:*.ANSI-36-cyan=36:*.ANSI-01;36-brcyan=01;36:*.ANSI-37-white=37:*.ANSI-01;37-brwhite=01;37:*.log=01;32:*~=01;32:*#=01;32:*.bak=01;36:*.BAK=01;36:*.old=01;36:*.OLD=01;36:*.org_archive=01;36:*.off=01;36:*.OFF=01;36:*.dist=01;36:*.DIST=01;36:*.orig=01;36:*.ORIG=01;36:*.swp=01;36:*.swo=01;36:*,v=01;36:*.gpg=34:*.gpg=34:*.pgp=34:*.asc=34:*.3des=34:*.aes=34:*.enc=34:';

alias  ls='ls --color=auto --time-style=+"%a %F %H:%M" -v '
alias  ll='ls -lh'
alias   l='ls -1'
alias  lr='ls -rt1'
alias llr='ls -rtlh'
alias  lc='ls -rtlhc'
alias  la='ls -1d \.*'
alias lla='ls -lhd \.*'

alias cdt='cd $REMOTE_HOME/tmp'
alias type='type -a'

alias lsop='netstat -tapnu | less -S'

alias shell-turn-off-line-wrapping="tput rmam"
alias shell-turn-on-line-wrapping="tput smam"

alias pgrep="pgrep -fl"
alias ps-attach="sudo strace -ewrite -s 1000 -p"

function df() {

    if [[ $@ ]] ; then
        command df "$@"
        return
    fi

    command df -h | perl -0777 -pe 's/^(\S+)\n/$1/gm' | csvview
}

alias prove="prove -lv --merge"

# search history for an existing directory containing string and go there
function cdh() {

    if ! [[ $@ ]] ; then
        cd $REMOTE_HOME
        return
    fi

    local dir=$(bash-history-search -d --skip-current-dir --existing-only -c 1 "$@")

    if [[ ! "$dir" ]] ; then
        return 1
    fi

    cd "$dir"
}

# search history for an existing file an open it in vi
function vih() {(
    set -e
    local file=$(bash-history-search --file -c 1 "$@")
    command vi "$file"
)}

# search for file or dir in cur dir and go there
function cdf() {

    local entry=$(f "$@" | head -1)

    if [[ ! "$entry" ]] ; then
        return 1
    fi

    if [[ -f "$entry" ]] ; then
        entry=$(dirname "$entry")
    fi

    cd "$entry"
}

# recursively find a file and open it in vim
function vif() {

    local search=$(perl -e '$_ = "'"$@"'" ; s#\:\:#/#g; print')

    local entry=$(f "$search" | head -1)

    if [[ ! "$entry" ]] ; then
        return 1
    fi

    command vi "$entry"
}

function cdm() {
    mkdir "$@" || return 1
    cd "$@"
}

# edit perl modul that is located within perls module path
function vip() {
    pm "$@" | v 1
}

alias grep-path="compgen -c | grep -i"
alias xargs='xargs -I {} -d \\n'
alias pm=perl-module-find

alias apts="apt-cache search"
alias aptw="apt-cache show"
alias apti="sudo apt-get install"
alias aptp="sudo dpkg -P"
alias aptc="sudo apt-get autoremove"
alias aptl="dpkg -l | g "

function  t() { tree --summary "$@" | less ; }
function td() { tree -d "$@" | less ; }

# make less more friendly for non-text input files, see lesspipe(1)
if [[ $(type -p lesspipe ) ]] ; then
    eval "$(lesspipe)"
fi

function vnc-vino-preferences {
    vino-preferences
}

function vnc-start-vino {
    /usr/lib/vino/vino-server --display :0 &
}

### distri fixes ###############################################################

if [[ $DISTRIBUTION = "suse" ]] ; then
    unalias crontab
fi

function env-grep {
    env | grep -i "$@"
}

function switch_to_iso() { export LANG=de_DE@euro ; }

### misc functions #############################################################

alias text-remove-comments="perl -ne 'print if ! /^#/ && ! /^$/'"
alias text-quote="fmt -s | perl -pe 's/^/> /g'"

### shell helper functions #####################################################

# get parent process id
function parent() {
    echo $(ps -p $PPID -o comm=)
}

### file handling functions ####################################################

function find-older-than-days() {
    find . -type f -ctime +$@ | less
}

function find-newest() {
    find -type f -printf "%CF %CH:%CM %h/%f\n" | sort | tac | less
}

function ls-from-date() {
    find -maxdepth 1 -type f -printf "%CF %CH:%CM %h/%f\n" \
        | perl -ne 'print substr($_, 17) if m#^\Q'$@'\E#'
}

function find-largest-files() {
    find . -mount -type f -printf "%k %p\n" \
        | sort -rg \
        | cut -d \  -f 2- \
        | xargs -I {} du -sh {} \
        | less
}

export GREP_OPTIONS="--color=auto"
alias listgrep="grep -xFf"

# a simple grep without the need for quoting or excluding dot files
function g() {
(
    trap "exit 1" SIGINT
    set -f

    if [[ -t 0 ]] ; then
        ff | while read i; do _andgrep -pf "$i" "$@" ; done
    else
        _andgrep $@
    fi
)

    local exit_code=$?
    set +f
    return $exit_code
}

# quick find a file or dir matching pattern
function fa() { (

    local search="$@"

    if [[ ! $search ]] ; then
        search=.
    fi

    find . -mount \
        | perl -MFile::Basename -ne 'print if m#'$search'(?!.*\/.*)#i' \
        | grep -i "$search"
) }

# quick find a file or dir matching pattern exclude hidden
function f() { (

    local search="$@"

    if [[ ! $search ]] ; then
        search=.
    fi

    fa "$search" \
        | perl -MFile::Basename -ne 'print if ! m#/\.#' \
        | grep -i "$search"
) }

function ff() {

    local search="$@"

    if [[ ! $search ]] ; then
        search=.
    fi

    f "$search" \
        | perl -MFile::Basename -nle 'print if ! m#/\.# && ! -d $_' \
        | grep -i "$search"
    true;
}

### process management #########################################################

# display or search pstree, exclude current process
function p() {
    local search=${@:-,$PPID}
    pstree -apl \
        | perl -ne '$x = "xxSKIPme"; print if $_ !~ /[\|`]\-\{[\w-_]+},\d+$|less.+\+\/'$1'|$x/' \
        | less "+/$search"
}

if [[ ! $(type -t pstree) ]] ; then
    alias p="ps axjf"
fi

function pswatch() { watch -n1 "ps -A | grep -i $@ | grep -v grep"; }

### bashrc handling ############################################################

# cp dotfile from github
function bashrc-fetch-file() {(
    local tmp="/tmp/cphub.$$"
    set -e
    wcat http://github.com/evenless/dotfiles/raw/master/$1 -fr
)}

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
        wcat tinyurl.com/phatbashrc2 -o .bashrc
    )
    bashrc-reload
}

function bashrc-reload() {
    bashrc-clean-env
    source ~/.bashrc
}

### xorg #######################################################################

if [[ $DISPLAY ]] ; then

    # swap caps lock with escape
    xmodmap -e 'clear Lock' -e 'keycode 0x42 = Escape'

    # make windows blink if prompt appears
    if [[ $(type -p wmctrl) ]] ; then
        _PROMPT_WMCTRL="wmctrl -i -r $WINDOWID -b add,DEMANDS_ATTENTION"
    fi

    # Make Control-v paste, xclip available - Josh Triplett
    if [[ $(type -p xclip) ]] ; then
        # Work around a bash bug: \C-@ does not work in a key binding
        bind '"\C-x\C-m": set-mark'
        # The '#' characters ensure that kill commands have text to work on; if
        # not, this binding would malfunction at the start or end of a line.
        bind 'Control-v: "#\C-b\C-k#\C-x\C-?\"$(xclip -o -selection c)\"\e\C-e\C-x\C-m\C-a\C-y\C-?\C-e\C-y\ey\C-x\C-x\C-d"'
    fi

    export BROWSER=firefox
fi

### SSH ########################################################################

alias ssh="ssh -A"

function _ssh_completion() {
    perl -ne 'print "$1 " if /^Host (.+)$/' $REMOTE_HOME/.ssh/config
}

if [[ -e $REMOTE_HOME/.ssh/config ]] ; then
    complete -W "$(_ssh_completion)" ssh scp ssh-with-reverse-proxy sshfs \
        sshnocheck sshtunnel vncviewer
    complete -fdW "$(_ssh_completion)" scp
fi

### SCREEN #####################################################################

alias screen="xtitle screen@$HOSTNAME ; screen -c $REMOTE_HOME/.screenrc"
alias   tmux="xtitle   tmux@$HOSTNAME ; tmux"
alias srd=tmux-reattach

function tmux-reload-environment() {
    eval $(tmux show-env | grep -v '^-')
}

### vim and editing ############################################################

# edit a file from a list on STDIN
function v() {
    local line=$1

    if [[ ! $line ]] ; then
        cat | nl
        return
    fi

    local file=$(cat | perl -ne 'print if $. == '$line)

    # close STDIN by connecting it back to the terminal
    exec < $_bashrc_tty

    vi $file
}

### history ####################################################################

# ignore commands  for history that start  with a space
HISTCONTROL=ignorespace:ignoredups
# HISTIGNORE="truecrypt*:blubb*"
# HISTTIMEFORMAT="[ %Y-%m-%d %H:%M:%S ] "

# Make Bash append rather than overwrite the history on disk
shopt -s histappend

# prevent history truncation
unset HISTFILESIZE

### eternal history

# echo $REMOTE_HOME
export HISTFILE_ETERNAL=$REMOTE_HOME/.bash_eternal_history

if [ ! -e $HISTFILE_ETERNAL ] ; then
    touch $HISTFILE_ETERNAL
    chmod 0600 $HISTFILE_ETERNAL
fi

function _add_to_history() {

    if [[ $BASHRC_NO_HISTORY ]] ; then
        return
    fi

    # remove history position (by splitting)
    local history=$(history 1)

    [[ $_last_history = $history ]] && return;

    read -r pos cmd <<< $history

    if [[ $cmd == "rm "* ]] ; then
        cmd="# $cmd"
        history -s "$cmd"
    fi

    local quoted_pwd=${PWD//\"/\\\"}

    # update cleanup_eternal_history if changed:
    local line="$USER"
    line="$line $(date +'%F %T')"
    line="$line $BASHPID"
    line="$line \"$quoted_pwd\""
    line="$line \"$bashrc_last_return_values\""
    line="$line $cmd"
    echo "$line" >> $HISTFILE_ETERNAL

    _last_history=$history

    history -a
}

alias h="bash-history-search -e -s"

### PROMPT #####################################################################

function bashrc-prompt-command() {

    local pipe_status="${PIPESTATUS[*]}"

    [[ $BASHRC_TIMER_START ]] || BASHRC_TIMER_START=$SECONDS

    echo -ne $BASHRC_COLOR_NO_COLOR

    PS1=$(
        elapsed=$(($SECONDS - $BASHRC_TIMER_START)) \
        jobs=$(jobs) \
        BASHRC_PROMPT_COLORS=1 \
        $BASHRC_PROMPT_COMMAND \
    )

    pipe_status=$pipe_status bash-print-on-error

    echo -ne $BASHRC_BG_COLOR
    BASHRC_TIMER_START=$SECONDS
}


# turn of history for testing passwords etc
function godark() {
    BASHRC_NO_HISTORY=1
    unset HISTFILE
    BASHRC_BG_COLOR=$BASHRC_COLOR_GREEN
}

### STARTUP ####################################################################

# set the appropriate prompt
function prompt-set() {

    local prompt=$1

    if [[ $prompt ]] ; then
        BASHRC_PROMPT_COMMAND=prompt-$prompt
        return
    fi

    case $(parent) in
        screen|screen.real|tmux)
            prompt_simple
        ;;
        *)
            if [[ $REMOTE_HOST ]] ; then
                BASHRC_PROMPT_COMMAND=prompt-host
            else
                BASHRC_PROMPT_COMMAND=prompt-simple
            fi
        ;;
    esac
}

return 0

if [[ ! $_is_reload ]] ; then

    _OLDPWD=$(bash-history-search -d -c 2 --existing-only | head -1)
    LAST_SESSION_PWD=$(bash-history-search -d -c 1 --existing-only)

    # cd to dir used last before logout
    if [[ $LAST_SESSION_PWD ]] ; then

        if [[ -d "$LAST_SESSION_PWD" ]] ; then
            cd "$LAST_SESSION_PWD"
        fi

    elif [[ -d "$REMOTE_HOME" ]] ; then
        cdh
    fi

    OLDPWD=$_OLDPWD
fi
_is_reload=1

if [ -d $REMOTE_HOME/.bashrc.d ] ; then
    for rc in $(ls $REMOTE_HOME/.bashrc.d/* 2>/dev/null) ; do
        source $rc
    done
fi

### perl functions #############################################################

alias normalizefilenames="xmv -ndx"

function csvview() {
    csvview "$@" | LESS= less -S
}

function j() { jobs=$(jobs) bash-jobs ; }

### bashrc-unpack ##############################################################

function bashrc-unpack() {

    # unpack scripts fatpacked to this bashrc

    perl - $@ <<'EOF'
        use strict;
        use warnings;

        $/ = undef;
        open(my $f, $ENV{REMOTE_BASHRC}) || die $!;
        my $bashrc = <$f>;

        my $home = $ENV{REMOTE_HOME} || die "REMOTE_HOME not set";
        my $dst_dir = $ENV{REMOTE_HOME} . "/.bin";

        system("mkdir -p $dst_dir") && die $!;

        print "\n";
        print STDERR "About to export to $dst_dir...\n";
        print "\n";

        my $x = <STDIN>;

        my $export_count = 0;
        while ($bashrc =~ /^### fatpacked app ([\w-]+) #*\n\n(.*?)### /igsm) {

            my $app_name = $1;
            my $app_data = $2;

            my $app_file_name = "$dst_dir/$app_name";

            # print STDERR "Exporting $app_name to $app_file_name...\n";

            open(my $APP_FILE, ">", $app_file_name) || die $!;
            print $APP_FILE $app_data;
            print $APP_FILE
                "\n# This app was created automatically and may be overridden"
                . " - DONT TOUCH THIS!";

            chmod(0755, $app_file_name) || die $!;

            $export_count++;
        }

        print STDERR "Done - apps exported: $export_count.\n\n";
EOF

}

# bashrc ends here
return 0

### fatpacked apps start here ##################################################
