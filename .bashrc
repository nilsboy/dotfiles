### for all shells #############################################################

if [[ ! $_is_reload ]] ; then
    export PATH=~/bin:~/perl5/bin:$PATH
    export PERL5LIB=~/perl5/lib/perl5:~/perldev/lib:$PERL5LIB
fi

if [[ ! $JAVA_HOME ]] ; then
    export JAVA_HOME=/usr/lib/jvm/java-6-sun
fi

[ -z "$PS1" ] && return

### for interactive shells only ################################################

### variables ##################################################################

[[ $REMOTE_USER   ]] || export REMOTE_USER=$USER
[[ $REMOTE_HOME   ]] || export REMOTE_HOME=$HOME
[[ $REMOTE_BASHRC ]] || export REMOTE_BASHRC="$REMOTE_HOME/.bashrc"
[[ $REMOTE_HOST   ]] || export REMOTE_HOST=${SSH_CLIENT%% *}

if [[ ! $_is_reload && $REMOTE_HOME != $HOME ]] ; then
    export PATH=$REMOTE_HOME/bin:$PATH
fi

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

# reenable ctrl+s for forward history search (XOFF)
stty stop ^-

# reenable ctrl+q (XON)
stty start ^-

### keyboard shortcuts #########################################################

# ctrl-l clear screen but stay in current row
bind -x '"\C-l":printf "\33[2J"'

if [[ $DISPLAY ]] ; then
    # swap caps lock with escape
    xmodmap -e 'clear Lock' -e 'keycode 0x42 = Escape'
fi

### aliases ####################################################################

export EDITOR="DISPLAY= vi -i $REMOTE_HOME/.viminfo -u $REMOTE_HOME/.vimrc"
alias vi=$EDITOR

export VISUAL=vi

alias cp="cp -i"
alias mv="mv -i"
export LESS="-j.5 -inRgS"
alias crontab="crontab -i"

alias ls='ls --color=auto --time-style=+"%F %H:%M" '
alias  l='ls -lh'
alias lr='ls -rtlh'
alias lc='ls -rtlhc'

alias cdt='cd $REMOTE_HOME/tmp'

alias lsop='netstat -tapn'
alias df="df -h | perl -0777 -pe 's/^(\S+)\n/\$1/gm' | csvview"

# search history for an existing directory containing string and go there
function cdh() {

    if ! [[ $@ ]] ; then
        cd $REMOTE_HOME
        return
    fi

    local dir=$(historysearch -d --skip-current-dir --existing-only -c 1 "$@")

    if [[ ! "$dir" ]] ; then
        return 1
    fi

    cd "$dir"
}

# search history for an existing file an open it in vi
function vih() {(
    set -e
    local file=$(historysearch --file -c 1 "$@")
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

# search for file from cur dir and edit it with vi
function vif() {

    local entry=$(f -type f "$@" | head -1)

    if [[ ! "$entry" ]] ; then
        return 1
    fi

    command vi "$entry"
}

alias greppath="compgen -c | grep -i"

alias xargs="xargs -I {}"

alias apts="apt-cache search"
alias aptw="apt-cache show"
alias apti="sudo apt-get install"
alias aptp="sudo dpkg -P"
alias aptc="sudo apt-get autoremove"
function  t() { simpletree "$@" | less ; }
function td() { simpletree -d "$@" | less ; }
function ts() { simpletree -sc "$@" | less ; }
alias diffdir="diff -rq"

# make less more friendly for non-text input files, see lesspipe(1)
if [[ $(type -p lesspipe ) ]] ; then
    eval "$(lesspipe)"
fi

### distri fixes ###############################################################

if [[ $DISTRIBUTION = "suse" ]] ; then
    unalias crontab
fi

### functions ##################################################################

## helper functions ############################################################

function _LOG() {

    local level=$1 ; shift
    local color=$1 ; shift
    local output_to=$1 ; shift

    if [ -t $output_to ] ; then
        echo -e "${color}${level}> $@${NO_COLOR2}" >&$output_to ;
    else
        echo -e "$(date +'%F %T') ${level}> $@" >&$output_to ;
    fi
}

function DEBUG() { _LOG "DEBUG" $GRAY2   1 "$@" ; }
function INFO()  { _LOG "INFO " $GREEN2  1 "$@" ; }
function WARN()  { _LOG "WARN " $ORANGE2 1 "$@" ; }
function ERROR() { _LOG "ERROR" $RED2    2 "$@" ; }
function DIE()   { _LOG "FATAL" $RED2    2 "$@" ; exit 1 ; }

function SHOW()  {
    local var=$1
    shift
    echo -e "$GREEN2$var$NO_COLOR2: $@"
}

## system functions ############################################################

# display infos about the system
function showenv() {

    while read v ; do
        SHOW $v ${!v}
    done<<EOF
        DISTRIBUTION
        REMOTE_USER
        REMOTE_HOME
        REMOTE_HOST
        REMOTE_BASHRC
        HISTFILE_ETERNAL
        SHELL
        PATH
        PERL5LIB
EOF

    SHOW Uname $(uname -a)
    SHOW Kernel $(cat /proc/version)

    local ubuntu_version=$(cat /etc/issue | perl -ne 'print $1 if /ubuntu (\d+\.\d+)/i')

    if [[ $ubuntu_version ]] ; then
        local release=$(note ubuntu | perl -ne 'print $_ if /^\s+'$ubuntu_version'\s+(.+?)\s+\d+/')
        SHOW Ubuntu $release
    else
        SHOW Linux $(cat /etc/issue.net)
    fi
}

function switch_to_iso() { export LANG=de_DE@euro ; }

## misc functions ##############################################################

alias filter_remove_comments="perl -ne 'print if ! /^#/ && ! /^$/'"
alias filter_quote="fmt -s | perl -pe 's/^/> /g'"

# run a previous command independent of the history
function r() { (

    local CMD_FILE=$REMOTE_HOME/.run_command

    local cmd=$@

    if [ "$cmd" = "" ] ; then
        if [ ! -e $CMD_FILE ] ; then
            DIE "got no command to run"
        fi
    else
        cmd=$(echo $cmd | perl -pe 's#./#cd $ENV{PWD} && \./#g')
        echo "$cmd" > $CMD_FILE
    fi

    v

    bash -i $CMD_FILE
) }

function timestamp2date() {
    local timestamp=$1
    perl -MPOSIX -e \
    'print strftime("%F %T", localtime(substr("'$timestamp'", 0, 10))) . "\n"'
}

## shell helper functions ######################################################

# clear screen also create distance to last command for easy viewing
function v() {

    local i=0
    while [ $i -le 80 ] ; do
        i=$(($i + 1))
        echo
    done
}

# get parent process id
function parent() {
    echo $(ps -p $PPID -o comm=)
}

## file handling functions #####################################################

# replace strings in files
function replace() { (

    local search=$1
    local replace=$2
    local files=$3

    if [[ $search = "" || $replace = "" || $files = "" ]] ; then
        DIE 'usage: replace "search" "replace" "file pattern"'
    fi

    find -iname "$files" -exec perl -p -i -e 's/'$search'/'$replace'/g' {} \;
) }

# absolute path
function abs() {

    perl - "$@" <<'EOF'

        use strict;
        use warnings;
        use Cwd;

        my $cwd = $ENV{PWD};
        my @cwd = split("/", $cwd);

        my $file = $ARGV[0] || ".";

        if($file !~ m#^/#) {

            while($file =~ s#^\.\./##g) {
                pop(@cwd);
            }

            $file = join("/", @cwd) . "/" . $file;
        }

        $file =~ s#/\.##g;
        $file .= "/" if -d $file;

        print $file . "\n";
EOF

}

function findolderthandays() {
    find . -type f -ctime +$@ | less
}

function findnewest() {
    find -type f -printf "%CF %CH:%CM %h/%f\n" | sort | tac | less
}

function lsfromdate() {
    find -maxdepth 1 -type f -printf "%CF %CH:%CM %h/%f\n" \
        | perl -ne 'print substr($_, 17) if m#^\Q'$@'\E#'
}

function findlargestfiles() {
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
        ff | while read i; do _andgrep -pf "$i" $@ ; done
    else
        _andgrep $@
    fi
)

    local exit_code=$?
    set +f
    return $exit_code
}

# or-grep list matching lines
function go() {
    perl -e 'while(my $l = <STDIN>) { foreach(@ARGV) { if($l =~ /$_/i) { print $l; last; }; } }' "$@"
}

# or-grep but list matching search strings instead of matching lines
# only longest matches are returned
function goo() {
    perl -e 'while (my $l = <STDIN>) { foreach (sort { length($b) <=> length($a) } @ARGV) { print "$_\n" x $l =~ s/$_//ig; } }' "$@"
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

# backup a file appending a date
function bak() {
    cp -v ${1?filename not specified}{,_$(date +%Y%m%d_%H%M%S)};
}

function dos2unix() {
    perl -i -pe 's/\r//g' "$@"
}

function unix2dos() {
    perl -i -pe 's/\n/\r\n/' "$@"
}

## process management ##########################################################

if [[ ! $(type -t pstree) ]] ; then
    alias p="ps axjf"
fi

# display or search pstree, exclude current process
function p() {

    local args

    if [[ $@ ]] ; then
        args=" +/$@"
    fi

    pstree -apl \
        | perl -ne '$x = "xxSKIPme"; print if $_ !~ /[\|`]\-\{[\w-_]+},\d+$|less.+\+\/'$1'|$x/' \
        | less $args
}

function pswatch() { watch -n1 "ps -A | grep -i $@ | grep -v grep"; }

### functions for lookups ######################################################

# display notes defined inside the bashrc
function noteall() {
    local search=$1
    ga $search <$REMOTE_BASHRC | grep -v '#'
    note $search
}

function note() {

    local search=$1

    if [[ ! $search ]] ; then
        perl -ne 'print " * $1\n" if /^# NOTES ON (.*)/' \
            $REMOTE_BASHRC| sort
        return
    fi

    perl -0777 -ne \
      'foreach(/^(# NOTES ON '$search'.+?\n\n)/imsg){ s/# //g; print "\n$_" }' \
        $REMOTE_BASHRC
}

# query wikipedia via dns
function wp() {
    dig +short txt "$*".wp.dg.cx | perl -0777 -pe 'exit 1 if ! $_ ; s/\\//g'
}

# quick command help lookup
function m() {

    local cmd=$1 ; shift
    local arg="$@"

    if [[ $arg =~ ^- ]] ; then
       arg=" {3,}"$arg
    elif [[ ! $arg ]] ; then
        arg='(^[A-Z]+[A-Z ]+)|---'
    fi

    (
        _printifok help help -m $cmd
        _printifok man man -a $cmd || \
        _printifok internet _man_internet $cmd
        _printifok perldoc perldoc -f $cmd
        _printifok apt-search apt-cache search $cmd
        _printifok related man -k $cmd

    ) | LESS="-j.5 -inRg" less +/"$arg"
}

function _man_internet() {
    local cmd=$1
    wcat -s http://man.cx/$cmd \
        | perl -0777 -pe 's/^.*\n(?=\s*NAME\s*$)|\n\s*COMMENTS.*$//smg' \
        | perl -0777 -pe 'exit 1 if /Sorry, I don.t have this manpage/' \
        && echo
}

function _printifok() {
    local msg=$1 ; shift
    local cmd="$*"

    local out=$(MANWIDTH=80 MAN_KEEP_FORMATTING=1 $cmd 2>/dev/null)
    [[ ${out[@]} ]] || return 1
    line $msg
    echo "${out[@]}"
    echo
}

function line() {
    perl - $@ <<'EOF'
        my $msg = " " . join(" ", @ARGV) . " ";
        print "---", $msg , q{-} x ($ENV{COLUMNS} - 3 - length($msg)), "\n\n";
EOF
}

# translate a word
function tl() {
    wcat -s "http://dict.leo.org/ende?lang=de&search=$@" \
        | perl -0777 -ne 'print "$1\n" if /Treffer(.+)$/igsm' \
        | less
}

### network functions ##########################################################

# find own public ip if behind firewall etc
function publicip() {
    wcat http://checkip.dyndns.org \
        | perl -ne '/Address\: (.+?)</i || die; print $1'
}

# find an unused port
function freeport() {

    local port=$1
    local ports="32768..61000";

    if [[ $port ]] ; then
        ports="$port,$ports";
    fi

    netstat  -atn \
        | perl -0777 -ne '@ports = /tcp.*?\:(\d+)\s+/imsg ; for $port ('$ports') {if(!grep(/^$port$/, @ports)) { print $port; last } }'
}

### conf files handling ########################################################

# cp dotfile from github
function _cphub() {(
    local tmp="/tmp/cphub.$$"
    set -e
    wcat http://github.com/evenless/etc/raw/master/$1 >$tmp
    mv -f $tmp $1
)}

function bashrc_clean_environment() {

    unset PROMPT_COMMAND

    # remove aliases
    unalias -a

    # remove functions
    while read funct ; do
        unset $funct
    done<<EOF
        $(perl -ne 'foreach (/^function (.+?)\(/) {print "$_\n" }' $REMOTE_BASHRC)
EOF
}

function updatebashrc() {
    (
        set -e
        cd $REMOTE_HOME
        _cphub .bashrc
    )
    reloadbashrc
}

function reloadbashrc() {
    bashrc_clean_environment
    source ~/.bashrc
}

function setupdotfiles() { (
    set -e

    cd $REMOTE_HOME

    mkdir -p .vim/colors .vim/plugin

    _cphub .vimrc
    _cphub .vim/colors/autumnleaf256.vim
    _cphub .vim/plugin/taglist.vim

    echo 'set editing-mode vi' > $INPUTRC
) }

function bashrc_export_function() {

    local funct=${1?specify function name}

    echo "export LINES COLUMNS"
    echo -n "# "
    type $funct
    echo
    echo $funct '"$@"'
}

function bashrc_export_function_to_file() {

    local funct=${1?specify function name}
    local file=$2

    if ! [[ $file ]] ; then
        file=$funct
    fi

    local note="# automatic bashrc export - do not edit"
    local is_export=

    if [ -e $funct ] ; then
        grep -q "$note" $funct && is_export=1

        if ! [ $is_export ] ; then
            WARN "skipping - file exists: $funct"
            continue
        fi
    fi

    # bash interactive mode to export LINES and COLUMNS vars
    echo '#!/bin/bash -i'          > $file
    echo "$note"                  >> $file
    bashrc_export_function $funct >> $file

    chmod +x $file
}

function bashrc_export_functions_to_files() {

    while read funct ; do

    bashrc_export_function_to_file $funct

    done<<EOF
        $(perl -ne 'foreach (/^function ((?!_).+?)\(/) {print "$_\n" }' \
            $REMOTE_BASHRC)
EOF
}

### export multiuser environment ###############################################

# setup multi user account on remote machine
function setup_remote_multiuser_account() {

    local remote_user=$REMOTE_USER
    local remote_home=users/$REMOTE_USER
    local server=${1?specify server}

    ssh $server "mkdir -p $remote_home/.ssh"

    ssh-add -L | ssh $server "cat > $remote_home/.ssh/authorized_keys"
    scp $REMOTE_BASHRC $server:$remote_home/
    scp $REMOTE_HOME/.vimrc $server:$remote_home/
    scp $REMOTE_HOME/.screenrc $server:$remote_home/

    local funct=bashrc_setup_multiuser_environment

    bashrc_export_function $funct \
        | perl -0777 -pe 's/^.*?\n{|\n}.*//smg' \
        | ssh $server "cat > ~/.$funct"

    echo 'source ~/.'$funct \
        | ssh $server "grep -q $funct ~/.bashrc || cat >> ~/.bashrc"
}

# load user bashrc on a multi user account identifying a user via ssh key
# expected dir structure: ~/users/your_username/.ssh/authorized_keys
function bashrc_setup_multiuser_environment() {

    [[ $SSH_CONNECTION ]] || return

    export REMOTE_HOST=${SSH_CLIENT%% *}

    type -p ssh-add 1>/dev/null || return

    shopt -s nullglob
    auth_files=(~/users/*/.ssh/authorized_keys)
    shopt -u nullglob

    [[ $auth_files ]] || return

    while read agent_key ; do

        agent_key=${agent_key%%=*}

        [[ $agent_key ]] || continue;

        for auth_file in ${auth_files[@]} ; do

            if grep -q "${agent_key}" $auth_file ; then
                REMOTE_USER=${auth_file%%/.ssh/authorized_keys};
                REMOTE_USER=${REMOTE_USER##$HOME/users/};
                export REMOTE_USER
                break 2
            fi

        done

    done<<<$(ssh-add -L 2>/dev/null)

    [[ $REMOTE_USER ]] || return

    export REMOTE_HOME="$HOME/users/$REMOTE_USER"
    export REMOTE_BASHRC="$REMOTE_HOME/.bashrc"

    if [[ -e $REMOTE_BASHRC ]] ; then
        source $REMOTE_BASHRC
    fi
}

### xorg #######################################################################

function xtitle () {

    case "$TERM" in
        *term | rxvt)
            echo -ne "\033]0;$*\007"
            ;;
        screen)
            # echo -ne "%{ESC_#$WINDOW %m:%c3ESC\\%}%h (%m:%.)%# "
            # echo -ne "\033]$*\033\]"
            ;;
        *)
            ;;
    esac
}

if [[ $DISPLAY ]] ; then

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

# NOTES ON ssh
# * prevent timeouts: /etc/ssh/ssh_config + ServerAliveInterval 5
# * tunnel (reverse/port forwarding):
#     * forward: ssh -v -L 3333:localhost:443 host
#     * reverse:  ssh -nNT [via host] -R [local src port]:[dst host]:[dst port]
#     * socks proxy: ssh -D 1080 host -p port / tsocks program
#     * keep tunnel alive: autossh
# * mount using ssh: sshfs / shfs
# * cssh = clusterssh

alias ssh="ssh -A"

# save ssh-agent vars to be loaded in a nother session or on reconnect inside
# screen or tmux
function grabssh () {
    local SSHVARS="SSH_CLIENT SSH_TTY SSH_AUTH_SOCK SSH_CONNECTION DISPLAY"

    for x in ${SSHVARS} ; do
        (eval echo $x=\$$x) | sed  's/=/="/
                                    s/$/"/
                                    s/^/export /'
    done 1>$REMOTE_HOME/.ssh_agent_env
}

# load ssh-agent vars stored by grabssh()
alias fixssh="source $REMOTE_HOME/.ssh_agent_env"

# remove connection to ssh-agent for testing purposes etc
alias nosshagent="grabssh && unset SSH_AUTH_SOCK SSH_CLIENT SSH_CONNECTION SSH_TTY"

# ssh url of a file or directory
function url() {
    echo $USER@$HOSTNAME:$(abs "$@")
}

# nicer ssh tunnel setup
function sshtunnel() { (

    local  in=$1
    local  gw=$2
    local out=$3

    if [[ ${#@} < 2 ]] ; then
        DIE "usage: sshtunnel [[in_host:]in_port] user@gateway [out_host:]out_port"
    fi

    if [[ ${#@} < 3 ]] ; then
        gw=$1
        out=$2
        unset in
    fi

    local out_host
    local out_port

    if [[ $out =~ ^.+\:.+$ ]] ; then
        out_host=${out%%:*}
        out_port=${out##*:}
    else
        out_host="localhost"
        out_port=$out
    fi

    local in_host
    local in_port

    if [[ $in ]] ; then
        if [[ $in =~ ^.+\:.+$ ]] ; then
            in_host=${in%%:*}
            in_port=${in##*:}
        else
            in_host="localhost"
            in_port=$in
        fi
    else
        in_host="localhost"
        in_port=$(freeport $out_port)
    fi

    if [[ $in_port != $out_port ]] ; then
        WARN "Using local port: $in_port"
    fi

    local cmd="ssh -N -L $in_host:$in_port:$out_host:$out_port $gw"
    INFO "Running: $cmd"
    xtitle "sshtunnel $cmd" && $cmd
) }

# remove ssl encryption from https etc
function sslstrip() { (

    local  in=$1
    local out=$2

    if [[ $@ < 2 ]] ; then
        die "usage: sslstrip [in_host:]in_port out_host:out_port"
    fi

    local cmd="sudo stunnel -c -d $in -r $out -f"
    INFO "running: $cmd"
    xtitle "sslstrip $cmd" && $cmd
) }

function sdiff() {(
    _pscp 1 $1 $2
)}

function pscp() {(
    _pscp 0 $1 $2
)}

# scp the same file from or to a remote host
function _pscp() {(
    local diff=$1
    local file=${2?specify filename}
    local host=${3?specify host}

    if [[ -e $file ]] ; then
        file=$(abs $file)
        rel_file=$(echo $file | perl -pe 's/$ENV{HOME}\///g');
        scp="scp -q $file $host:$rel_file"
    else
        tmp=$file
        file=$(abs $host)
        rel_file=$(echo $file | perl -pe 's/$ENV{HOME}\///g');
        host=$tmp
        scp="scp -q $host:$rel_file $file"
    fi


    if [[ $diff = 1 ]] ; then
        ssh -q $host cat $rel_file | diff $file -
    else
        command $scp
    fi
)}

function _ssh_completion() {
    perl -ne 'print "$1 " if /^Host (.+)$/' $REMOTE_HOME/.ssh/config
}

if [[ -e $REMOTE_HOME/.ssh/config ]] ; then
    complete -W "$(_ssh_completion)" ssh
fi

### SCREEN #####################################################################

alias screen="xtitle screen@$HOSTNAME ; export DISPLAY=; screen -c $REMOTE_HOME/.screenrc"
alias   tmux="xtitle   tmux@$HOSTNAME ; export DISPLAY= ; tmux"

# reconnect to a screen or tmux session
function srd() {

    local session=$1

    if [[ ! $session ]] ; then
        session=main
    fi

    grabssh

    (
        if tmux has-session -t $session ; then
            tmux -2 att -d -t $session
            exit 0
        fi

        if tmux has-session ; then
            tmux -2 att -d
            exit 0
        fi

        screen -rd $session && exit
        screen -rd && exit

        exit 1

    ) && clear
}

### mysql ######################################################################

# fix mysql prompt to show real hostname - NEVER localhost
function mysql() {

    local h=$(perl -e '"'"$*"'" =~ /[-]+h(?:ost)*\ (\S+)/ && print $1')

    if [[ ! $h || $h = localhost ]] ; then
        h=$HOSTNAME
    fi

    xtitle "mysql@$h" && MYSQL_PS1="\\u@$h:\\d db> " \
        command mysql --show-warnings --pager="less -FX" "$@"
}

### perl #######################################################################

# NOTES ON perl
# * profiling: perl -d:NYTProf <SCRIPTNAME> && nytprofhtml
# * debugging: perl -d:ptkdb <SCRIPTNAME>
# * call graph: perl -d:DProf <SCRIPTNAME> && dprofpp -T tmon.out (or B::Xref)
# * Print out each line before it is executed: perl -d:Trace <SCRIPTNAME>
# * if header files missing: see note compiling
# * check module version: perl -MCGI -e 'print "$CGI::VERSION\n"'
# * Devel::Cover for test coverage
# * One liners
#     http://blog.ksplice.com/2010/05/top-10-perl-one-liner-tricks/
# * DBI->trace(2 => "/tmp/dbi.trace");
# * ignore broken system locales in perl programs
#    PERL_BADLANG=0
# * corelist - perl core modules

# for cpan
export FTP_PASSIVE=1

export MODULEBUILDRC=~/perl5/.modulebuildrc
export PERL_MM_OPT=INSTALL_BASE=~/perl5

# less questions from cpan
export PERL_MM_USE_DEFAULT=1

# testing
alias prove="prove -lv --merge"

function perlmoduleversion() {
    perl -le 'eval "require $ARGV[0]" and print $ARGV[0]->VERSION' "$@"
}

function cpanm_reinstall_local_modules() {(
    set -e
    cpanm -nq App::cpanoutdated
    cpan-outdated | cpanm -nq --reinstall
)}

# find a lib via PERL5LIB
function pmpath() {

     perl - $@ <<'EOF'
        use strict;
        use warnings;
        my $module = $ARGV[0] or die q{specify module.};
        eval qq{require $module};
        $module =~ s{::}{/}g;
        $module =~ s/$/.pm/g;
        $INC{$module} || exit 1;
        print $INC{$module} . "\n";
EOF
}

# fuzzy find
function _pathfuzzyfind() {

     perl - $@ <<'EOF'
        use warnings;
        no warnings 'uninitialized';
        use File::Find;

        my $to_find = shift @ARGV;

        my $dirs = $ENV{$to_find};

        @ARGV || die "specify module.";

        my $module = join("/", @ARGV);
        $module =~ s{::}{/}g;

        my @dirs = ( split( ":", $dirs ) );
        push(@dirs, @INC) if $to_find eq "PERL5LIB";
        push(@dirs, "lib") if $to_find eq "PERL5LIB";

        my $exact_match = $module;

        if($to_find eq "PERL5LIB") {
            $exact_match = "$module\.pm";
        }

        my %matches       = ();
        my %fuzzy_matches = ();
        foreach my $dir (@dirs) {

            $dir .= "/";

            next if !-d $dir;
            next if $dir =~ /^\./;

            find(
                sub {
                    my $abs = $File::Find::name;
                    my $file = $dir . $abs;

                    if($to_find eq "PERL5LIB") {
                        return if $file !~ /\.pm$/;
                    } else {
                        $file = $abs;

                        my $top_dir_depth = $dir =~ tr!/!!;
                        my $depth = $file =~ tr!/!!;

                        return if $depth != $top_dir_depth;
                    }

                    return if -d $file;

                    $file =~ s/^$dir(\/i486-linux-gnu-thread-multi\/)*//g;

                    return if $file !~ /$module/i;

                    if($file =~ /^((\/)*\/|)$exact_match$/i) {
                        $matches{$file} = $abs;
                        return;
                    }

                    $fuzzy_matches{$file} = $abs;
                },
                $dir
            );
        }

        if ( keys %matches == 1 ) {
            print values %matches;
            exit 0;
        }

        if(exists $matches{$exact_match}) {
            print $matches{$exact_match};
            exit 0;
        }

        if( ! %matches && keys %fuzzy_matches == 1) {
            print values %fuzzy_matches;
            exit 0;
        }

        if (%matches) {
            print STDERR "\n---- exact matches " , "-" x 61, "\n";
            print STDERR join("\n", sort keys %matches) . "\n";
        }

        if (!%matches && %fuzzy_matches) {
            print STDERR "\n---- fuzzy matches ", "-" x 61, "\n";
            print STDERR join("\n", sort keys %fuzzy_matches) . "\n";
        }

        if(! %matches && ! %fuzzy_matches) {
            print STDERR "nothing found.\n";
        } else {
            print STDERR "-" x 80, "\n\n";
        }

        exit 1;
EOF
}

# fuzzy find a lib via $PERL5LIB
function pmpathfuzzy() {
    _pathfuzzyfind PERL5LIB "$@"
}

# fuzzy find a bin via $PATH
function binpathfuzzy() {
    _pathfuzzyfind PATH "$@"
}

# edit a lib via PERL5LIB
function vii() {

    local file=$(pmpathfuzzy "$@")

    if  ! [[ $file ]] ; then
        return 1;
    fi

    command vi $file
}

# edit a lib via PATH
function vib() {

    local file=$(binpathfuzzy "$@")

    if  ! [[ $file ]] ; then
        return 1;
    fi

    command vi $file
}

function vif() {

    local entry=$(f "$@" | perl -lne 'print if ! -d' | head -1)

    if [[ ! "$entry" ]] ; then
        return 1
    fi

    command vi "$entry"
}

# setup local::lib and cpanm
function setupcpanm() { (

    set -e

    if [ -e ~/.cpan ] ; then
        DIE "remove ~/.cpan first" >&2
    fi

    WD=$(mktemp -d)
    cd $WD

    INFO "setting up local::lib..."
    wcat \
    search.cpan.org/CPAN/authors/id/G/GE/GETTY/local-lib-1.006007.tar.gz \
    | tar xfz -

    cd local-lib*/

    perl Makefile.PL --bootstrap >/dev/null
    make install >/dev/null

    cd /tmp
    rm $WD -rf

    INFO "setting up cpanm..."
    cd ~/bin

    if [ -e cpanm ] ; then
        rm cpanm
    fi

    wcat cpansearch.perl.org/src/MIYAGAWA/App-cpanminus-1.1001/bin/cpanm \
        > cpanm
    perl -p -i -e 's/^#\!perl$/#\!\/usr\/bin\/perl/g' cpanm
    chmod +x cpanm

    INFO "Now set your lib path like: PERL5LIB=$HOME/perl5/lib/perl5:$HOME/perldev/lib"
    INFO "You may now install modules with: cpanm -nq [module name]"
) }

# allow cpanm to install modules specified via Path/File.pm
function cpanm() {
    perl -e 'map { s/\//\:\:/g ; s/\.pm$//g } @ARGV; system("cpanm", "-nq" , @ARGV) && exit 1;' \
         -- "$@"
}

### java #######################################################################

# recursively decompile a jar including contained jars
function unjar() { (

    set -e

    local org_jar=$1
    local tmp_dir=$(basename $org_jar).decompiled

    mkdir $tmp_dir
    cp $org_jar $tmp_dir/

    cd $tmp_dir

    while true ; do

        for jar in $(find -iname "*.jar") ; do

            INFO "Unpacking jar: $jar..."
            jar xf $jar
            rm $jar

        done

        if [[ ! $(find -iname "*.jar") ]] ; then
            break
        fi

    done

    INFO "Decompiling classes..."

    set +e
    for class in `find . -name '*.class'`; do

        if jad -d $(dirname $class) -s java -lnc $class 2>/dev/null 1>/dev/null ; then
            rm $class
        else
            ERROR "Can not be decompiled: $class"
        fi

    done
) }

### NOTES ######################################################################

# NOTES ON apt
# * apt-cache depends -i 

# NOTES ON bash
# * zenity for dialogs?
# * Advanced Bash-Scripting Guide:
#    http://tldp.org/LDP/abs/html/index.html
# * expand only if files exist: shopt -s nullglob / for x in *.ext ; ...
# * generate unique ID: uuidgen (not thread safe?)
# * unaliased version of a program: prefix with slash i.e.: \ls file

# NOTES ON cron
# * make cron scripts use bashrc (now path can use ~ too)
#    SHELL=/bin/bash
#    BASH_ENV=~/.bashrc
#    PATH=~/bin:/usr/bin/:/bin

# NOTES ON bios
# * infos of system: getSystemId

# NOTES on chroot
# * chroot to fix broken system using live-cd
#   cd /
#   mount -t ext4 /dev/sda1 /mnt
#   mount -t proc proc /mnt/proc
#   mount -t sysfs sys /mnt/sys
#   mount -o bind /dev /mnt/dev
#   cp -L /etc/resolv.conf /mnt/etc/resolv.conf
#   chroot /mnt /bin/bash
#   ...
#   exit
#   umount /mnt/{proc,sys,dev}
#   umount /mnt

# NOTES ON compiling
# * basic steps
#    apt-get install build-essential
#    sudo apt-get build-dep Paketname
#    ./configure
#    sudo checkinstall -D

# NOTES ON console
# * switch console: chvty
# * turn off console-blanking: echo -ne "\033[9;0]" > /dev/tty0
# * lock: ctrl+s / unlock: ctrl+q

# NOTES ON encoding
# * recode UTF-8..ISO-8859-1 file_name
# * convmv: filename encoding conversion tool
# * luit - Locale and ISO 2022 support for Unicode terminals
#      luit -encoding 'ISO 8859-15' ssh legacy_machine

# NOTES ON man and the like
# * apropos - search the manual page names and descriptions

# NOTES ON processes
# * to kill a long running job
#    ps -eafl |\
#       grep -i "dot \-Tsvg" |\ 
#       perl -ane '($h,$m,$s) = split /:/,$F[13];
#          if ($m > 30) { print "killing: " . $_; kill(9, $F[3]) };'
# * disown, (cmd &) - keep jobs running after closing shell
# * continue a stoped disowned job: sudo kill -SIGCONT $PID

# NOTES ON networking
# * fuser
# * lsof -i -n

# NOTES ON recovery
# * recover removed but still open file
#   lsof | grep -i "$file"
#   cp /proc/$pid/fd/$fd $new_file
#   (fd = file descriptor)
# * recover partition: ddrescue
# * recover deleted files: foremost jpg -o out_dir -i image_file

# NOTES ON text csv and other files
# * sort by numeric column: sort -u -t, -k 1 -n file.csv > sort
# * comm - compare two sorted files line by line with 3 column output
# * join files horizontally: paste
# * truncate a file without removing its inode: > file
# * join csv files: join
# * edit shell commands in vi with Ctrl-x Ctrl-e

# NOTES ON sql / mysql
# * INSERT
#    * REPLACE INTO x ( f1, f2 ) SELECT ... - replaces on duplicate key
#    * INSERT IGNORE INTO ... - skips insert on duplicate key
# * default-storage-engine = innodb
# * mysql full join: left join union right join
# * split: SUBSTRING_INDEX(realaccount,'@',-1)
# * convert string to date: STR_TO_DATE(created, "%d.%m.%y")
# * NULL does no match regex use: (f IS NULL OR f NOT REGEXP '^regex$')

# NOTES ON sftp
# * use specifc key file
#     sftp -o IdentityFile=~/.ssh/$keyfile $user@$host
# * use password
#     ltp -u login,pass sftp://host

# NOTES ON user management
# * newgrp - log in to a new group
# * sg - execute command as different group ID

# NOTES ON vnc
# ssh -v -L 5900:localhost:59[display] -p sshport sshgateway
# export VNC_VIA_CMD='/usr/bin/ssh -x -p port -l user -f -L %L:%H:%R %G sleep 20'
# xtightvncviewer -via ssh-host -encodings tight -fullscreen localhost:0

# NOTES ON ubuntu
# * Releases:
#                                                  Supported until
#                                                Desktop      Server
#      4.10       Warty Warthog     2004-10-20   2006-04-30
#      5.04       Hoary Hedgehog    2005-04-08   2006-10-31
#      5.10       Breezy Badger     2005-10-13   2007-04-13
#      6.06 LTS   Dapper Drake      2006-06-01   2009-07-14   2011-06
#      6.10       Edgy Eft          2006-10-26   2008-04-25
#      7.04       Feisty Fawn       2007-04-19   2008-10-19
#      7.10       Gutsy Gibbon      2007-10-18   2009-04-18
#      8.04 LTS   Hardy Heron       2008-04-24   2011-04      2013-04
#      8.10       Intrepid Ibex     2008-10-30   2010-04-30
#      9.04       Jaunty Jackalope  2009-04-23   2010-10-23
#      9.10       Karmic Koala      2009-10-29   2011-04
#     10.04 LTS   Lucid Lynx        2010-04-29   2013-04      2015-04
#     10.10       Maverick Meerkat  2010-10-10   2012-04
#     11.04       Natty Narwhal     2011-04-28   2012-10
#     11.10       Oneiric Ocelot    2011-10-??   2013-04

# NOTES ON vim
# * :help quickref
# * :help quickfix

# NOTES ON x
# * ssh -X host x2x -west -to :4.0

# NOTES ON init
# * sudo update-rc.d vncserver defaults 
# * sudo update-rc.d -f vncserver remove

# NOTES ON encryption
# * fsck encrypted volume
#    - sudo cryptsetup luksOpen /dev/hda5 mydisk
#    - fsck /dev/mapper/mydisk

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
HISTFILE_ETERNAL=$REMOTE_HOME/.bash_eternal_history

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

alias h="set -f && historysearch -e -s"

# search in eternal history
function historysearch() {

(
    HISTFILE_ETERNAL=$HISTFILE_ETERNAL perl - "$@" <<'EOF'

use strict;
use warnings;
no warnings 'uninitialized';
use Getopt::Long;
use Cwd;

my $gray        = "\x1b[38;5;250m";
my $reset_color = "\x1b[38;5;0m";
my $red         = "\x1b[38;5;124m";

my $pipe_mode = ! -t STDOUT;

if($pipe_mode) {
    $gray = $reset_color = $red = "";
}

my $opts = {
    "a|all" => \my $show_all,
    "e|everything" => \my $show_everything,
    "existing-only" => \my $show_existing_only,
    "skip-current-dir" => \my $skip_current,
    "d|directories" => \my $show_dirs_only,
    "files" => \my $find_files,
    "s|search-directories" => \my $search_dirs,
    "r|succsessful-result-only" => \my $show_successful,
    "l|commands-here" => \my $show_local,
    "c|count=i" => \my $count,
};
GetOptions(%$opts) or die "Usage:\n" . join("\n", sort keys %$opts) . "\n";

my @search = @ARGV;
my $wd = cwd;

# user 2011-08-20 21:02:47 19202 "dir" "0 1" cmd with options ...
#                  usr  date time  pid   dir   exit codes  cmd
my $hist_regex = '^(.+) (.+) (.+) (\d*) "(.+)" "([\d ]+)" (.+)$';

my $h = $ENV{HISTFILE_ETERNAL};
open(F, "tac $h |") || die $!;

my %shown = ();
$count ||= 100;
my @to_show = ();

ENTRY: while(<F>) {
    my(@all) = $_ =~ /$hist_regex/g;
    my($user, $date, $time, $pid, $dir, $result, $cmd) = @all;
    my $was_successful = $result =~ /[0 ]+/g;

    next if $show_successful && ! $was_successful;
    next if $dir ne $wd && $show_local;

    my $to_match;
    my $show;

    if($show_dirs_only) {
        next if $show_existing_only && ! -d $dir;
        $to_match = $dir;
        $show = $dir;
        $show_everything = 0;
    }
    else {
        $to_match = $cmd;
        $show = $cmd;
        $show = $red . $show . $reset_color if ! $was_successful;
    }

    if($search_dirs) {
        $to_match .= " $dir";
    }

    if(@search) {
        foreach my $search (@search) {

            next ENTRY if $to_match !~ /$search/i;

            my $found;
            if($find_files) {
                foreach(split(" ", $cmd)) {
                    if(/^\//) {
                    } elsif(/^~/) {
                        s/^~/$ENV{HOME}/g;
                    } else {
                        $_ = "$dir/$_";
                    }
                    next if $_ !~ /$search/i;
                    next if ! -f $_;
                    $found = $_;
                    last;
                }
                next ENTRY if ! $found;
                $to_match = $found;
                $show = $found;
            }
        }
    }

    next if exists $shown{$to_match};

    $shown{$to_match} = 1;

    $show .= "\n";
    $show .= $gray . "   (" . join(" ", @all[0..$#all-1]) . ")\n" . $reset_color
        if $show_everything;

    push(@to_show, $show);

    last if !$show_all && keys %shown == $count;
}

map { print $_ } reverse @to_show;

EOF
)

    local exit_code=$?
    set +f
    return $exit_code
}

# uniq replacement without the need of sorted input
function uniqunsorted() {
    perl -ne 'print $_ if ! exists $seen{$_} ; $seen{$_} = 1'
}

### PROMPT #####################################################################

# some default colors
function _set_colors() {

    # disable any colors
    NO_COLOR="\[\033[0m\]"
    NO_COLOR2="\033[0m"

    BLACK="\[\033[0;30m\]"

    RED="\[\033[0;31m\]"
    RED2="\033[0;31m"

    GREEN="\[\033[0;32m\]"
    GREEN2="\033[0;32m"

    GRAY="\[\033[0;37m\]"
    GRAY2="\033[0;37m"

    ORANGE="\[\033[0;33m\]"
    ORANGE2="\033[0;33m"

    BLUE="\[\033[0;34m\]"
    BLUE2="\033[0;34m"

    MAGENTA="\[\033[0;35m\]"
    CYAN="\[\033[0;36m\]"
    WHITE="\[\033[0;37m\]"

    BROWN="\[\033[0;33m\]"

    # background colors
    BG_BLACK="\[\033[40m\]"
    BG_RED="\[\033[41m\]"
    BG_GREEN="\[\033[42m\]"
    BG_YELLOW="\[\033[43m\]"
    BG_BLUE="\[\033[44m\]"
    BG_MAGENTA="\[\033[45m\]"
    BG_CYAN="\[\033[46m\]"
    BG_WHITE="\[\033[47m\]"
    BG_BROWN="\[\033[44;XXm\]"
}

# shorten prompt dir to max 15 chars
function _fix_pwd () {

    _pwd=$PWD

    local top_dir

    if [[ $_pwd = $HOME ]] ;  then
        _pwd="~"
    elif [[ $_pwd = $HOME/ ]] ;  then
        _pwd="~"
    else
        _pwd=${_pwd##/*/}
    fi

    local max_length=14
    local length=${#_pwd}

    if [ $length -gt $(($max_length + 1)) ] ; then

        local left_split=$(($max_length-4))
        local right_split=4

        local right_start=$(($length-$right_split))

        local left=${_pwd:0:$left_split}
        local right=${_pwd:$right_start:$length}

        _pwd=$left${RED}"*"${NO_COLOR}$right
        _xtitle_pwd=$left"..."$right

    else
        _xtitle_pwd=$_pwd
    fi
}

# count seconds between prompt displays
function _track_time() {
    _track_now=$SECONDS

    if [ "$_track_then" = "" ] ; then
        _track_then=$_track_now
    fi

    echo $(($_track_now-$_track_then))
    # _then=$now # useless here!?!
}

function humanize_secs() {

    local secs=$1
    local human

    if  [ $secs -ge 359999 ] ; then # 99 h
        human=$(($secs / 60 / 60 / 24))d
    elif [ $secs -ge 5999 ] ; then # 99 m
        human=$(($secs / 60 / 60))h
    elif [ $secs -ge 60 ] ; then
        human=$(($secs / 60))m
    else
        human=$secs"s"
    fi

    if [ ${#human} = 2 ] ; then
        human=" "$human
    fi

    echo "$human"
}

# count background jobs running and stoped
function _set_bg_jobs_count() {

    local job
    _bg_jobs_count=0
    _bg_jobs_running_count=0

    while read job state crap ; do

        if [[ $job =~ ^\[[0-9]+\] ]] ; then

            _bg_jobs_count=$(($_bg_jobs_count+1))

            if [[ $state = Running ]] ; then
                _bg_jobs_running_count=$(($_bg_jobs_running_count+1))
            fi
        fi

    done<<EOF
        $(jobs)
EOF

    if [[ $_bg_jobs_count == 0 ]] ; then
        unset _bg_jobs_count
    else
        if [[ $_bg_jobs_running_count -gt 0 ]] ; then
            _bg_jobs_count=${RED}$_bg_jobs_count${NO_COLOR}
        fi

        _bg_jobs_count=" "$_bg_jobs_count
    fi
}

function _color_user() {

    if [[ $USER == "root" ]] ; then
        echo ${RED}$USER${NO_COLOR}
    else
        echo $USER
    fi
}

# print error code of last command on failure
function _print_on_error() {

    for item in ${bashrc_last_return_values[*]} ; do

        if [ $item != 0 ] ; then
            echo -e ${RED2}exit: $bashrc_last_return_values$NO_COLOR2 >&2
            break
        fi

    done
}

function _prompt_command_default() {

    bashrc_last_return_values=${PIPESTATUS[*]}

    _print_on_error
    local secs=$(_track_time)
    local time=$(humanize_secs $secs)
    local hostname=$(_color_user)@$GREEN$HOSTNAME$NO_COLOR
    _fix_pwd
    _set_bg_jobs_count

    # $NO_COLOR first to reset color setting from other programs
    PS1=$GRAY"$time$NO_COLOR $hostname:$_pwd${_bg_jobs_count}"">$BASHRC_BG_COLOR "
    xtitle $USER@$HOSTNAME:$_xtitle_pwd

    _add_to_history

    # has to be done here!?!
    _track_then=$SECONDS

    # TODO
    # $_PROMPT_WMCTRL
}

function _prompt_command_simple() {

    bashrc_last_return_values=${PIPESTATUS[*]}

    _print_on_error
    local secs=$(_track_time)
    local time=$(humanize_secs $secs)
    _fix_pwd
    _set_bg_jobs_count

    local if_root=""
    if [[ $USER == "root" ]] ; then
        if_root="${RED}root$NO_COLOR "
    fi

    PS1=$NO_COLOR"$GRAY$time$NO_COLOR $if_root$_pwd${_bg_jobs_count}"">$BASHRC_BG_COLOR "
    xtitle $USER@$HOSTNAME:$_xtitle_pwd

    _add_to_history

    # has to be done here!?!
    _track_then=$SECONDS
}

function _prompt_command_spare() {

    bashrc_last_return_values=${PIPESTATUS[*]}

    _print_on_error
    _fix_pwd
    _set_bg_jobs_count

    PS1=$NO_COLOR"$_pwd${_bg_jobs_count}""$BASHRC_BG_COLOR> "
    xtitle  $USER@$HOSTNAME:$_xtitle_pwd

    _add_to_history
}

function prompt_default() {
    PROMPT_COMMAND=_prompt_command_default
}

function prompt_simple() {
    PROMPT_COMMAND=_prompt_command_simple
}

function prompt_spare() {
    PROMPT_COMMAND=_prompt_command_spare
}

# turn of history for testing passwords etc
function godark() {
    BASHRC_NO_HISTORY=1
    unset HISTFILE
    BASHRC_BG_COLOR=$GREEN
}

### STARTUP ####################################################################

_set_colors
unset _set_colors

# set the appropriate prompt
case $(parent) in
    screen|screen.real|tmux)
        prompt_simple
    ;;
    *)
        if [[ $REMOTE_HOST ]] ; then
            prompt_default
        else
            prompt_simple
        fi
    ;;
esac

if [[ ! $_is_reload ]] ; then

    _OLDPWD=$(historysearch -d -c 2 --existing-only | head -1)
    LAST_SESSION_PWD=$(historysearch -d -c 1 --existing-only)

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

if [ -r $REMOTE_HOME/.bashrc_local ] ; then
    source $REMOTE_HOME/.bashrc_local
fi

### perl functions #############################################################

# run a perl app located at the end of this file
function _run_perl_app() {(
    local function=${1?Specify function}
    shift

    code=$(perl -0777 -ne \
        'print $1 if /(^### function '$function'\(\).*?)### /igsm' \
        $REMOTE_BASHRC
    )

    if ! [[ $code ]] ; then
        DIE "Function not found: $function"
    fi

    code="no warnings qw{uninitialized}; use Data::Dumper; $code"

    export code
    perl -we 'eval $ENV{code}; die $@ if $@;' -- "$@"
)}

# setup aliases for all the perl apps at the end of this file
function _setup_perl_apps() {

    while read funct ; do
        eval "function $funct() { _run_perl_app $funct \"\$@\" ; }"
    done<<EOF
        $(perl -ne 'foreach (/^### function (.+?)\(/) {print "$_\n" }' \
            $REMOTE_BASHRC)
EOF
}

_setup_perl_apps

alias normalizefilenames="xmv -ndx"

function csvview() {
    _run_perl_app csvview "$@" | LESS= less -S
}

function j() {
    export _bashrc_jobs=$(jobs)
    export _bashrc_columns=$COLUMNS
    _run_perl_app _display_jobs
}

# bashrc ends here
return 0

### function csvview() #########################################################

use Getopt::Long;
use Encode;

my $opts = {
    "c|count=i" => \my $count,
};
GetOptions(%$opts) or die "Usage:\n" . join("\n", sort keys %$opts) . "\n";

my %field_types = (
    num   => qr/^[\.,\d]+[%gmt]{0,1}$/i,
    nnum  => qr/^[\-\.,\d]+$/,
    alph  => qr/^[a-z]+$/i,
    anum  => qr/^[a-z0-9]+$/i,
    msc   => qr/./i,
    blank => qr/^[\s]*$/,
    empty => qr/^$/,
);

my @field_type_order = qw(num nnum alph anum blank empty msc);

my $file;
my $is_temp_file = 0;
if(! -t STDIN) {
    $file = "/tmp/csvvview.stdin.$$.csv";
    $is_temp_file = 1;

    open(F, ">", $file) || die $!;
    while(<>) {
        print F $_;
    }
    close(F);

} else {
    $file = shift @ARGV || die "File?";
}

open(F, $file) || die $!;

my %stats        = (File => $file);
my %fields       = ();
my $delimiter    = find_delimiter();
my $screen_lines = $ENV{LINES} - 1;

my $empty_line_regex = qr/^[$delimiter\s]*$/;

my @header;
my $header;
my @column_ids_header;
my $column_ids_header;
my @line;
my $line;

analyze_data();

my $lines_shown = 0;

my $last_line;
open(F, $file) || die $!;
binmode STDOUT, ":utf8";
while (<F>) {

    s/[\r\n]//g;

    # convert latin to utf8 if necessary
    if(/[\xc0\xc1\xc4-\xff]/) {
        $stats{encoding} = "latin1";
        $_ = decode( "iso-8859-15", $_);
    }

    if ($_ =~ $empty_line_regex || $_ =~ /^#/) {
        next;
    }

    if ($lines_shown % $screen_lines == 0) {
        print stats() . $column_ids_header . $header . padded_line(\@line, "-");
        $lines_shown += 4;
        next;
    }

    print padded_line([ split($delimiter) ]);

    $lines_shown++;
    $last_line = $.;
}

print "\n" x ($screen_lines -
        ($lines_shown - int($lines_shown / $screen_lines) * $screen_lines));

close(F);

sub find_delimiter {

    my $sample;

    open(F, $file) || die $!;
    my $line = 0;
    while (<F>) {
        next if /^#/;
        s/[\r\n]//g;
        $line++;
        $sample .= $_;
        last if $line == 3;
    }
    close(F);

    my @special_chars = $sample =~ /(\W)/g;
    my %special_char_count = ();
    map { $special_char_count{$_}++ } @special_chars;

    my $delimiter;

    if($sample =~ / {3,}/) {
        $delimiter = " +";
    } else {
        my $max = 0;
        foreach my $special_char (keys %special_char_count) {
            next if $special_char_count{$special_char} < $max;
            $delimiter = $special_char;
            $max       = $special_char_count{$special_char};
        }
    }

    $stats{delimiter} = '"' . $delimiter . '"';
    return $delimiter || die "No delimiter found.";
}

sub calculate_alpha_column_name {
    my ($num) = @_;

    my $r;
    while ($num != 0) {
        $r = chr($num % 26 + 64) . $r if $num % 26;
        $num = int($num / 26);
    }

    return $r;
}

sub analyze_data {

    my $header_line;
    open(F, $file) || die $!;

    while (<F>) {

        $stats{format} = "dos" if /\r/;
        s/[\r\n]//g;

        $stats{Lines} = $.;

        if ($. == 1) {
            $header_line = $_;
            next;
        }

        if ($_ =~ $empty_line_regex) {
            $stats{"Empty Lines"}++;
            next;
        }

        add_field_stats([ split($delimiter) ]);
    }
    close(F);


    @header = split($delimiter, $header_line);
    add_field_stats(\@header, 1);

    set_field_types();
    create_column_ids_header();
    add_field_stats(\@column_ids_header, 1);

    $column_ids_header = padded_line(\@column_ids_header);
    $header            = padded_line(\@header);

    my $i = -1;
    foreach my $value (@header) {
        $i++;
        $line[$i] = "-" x $fields{$i}{length};
    }
    $line = padded_line(\@line);

    foreach my $field (keys %fields) {

        if($fields{$field}{type} eq "blank") {
            $stats{"Blank columns"}++;
            next;
        }

        if($fields{$field}{type} eq "empty") {
            $stats{"Empty columns"}++;
            next;
        }
    }
}

sub add_field_stats {
    my ($line, $ignore_empty) = @_;
    my $i = -1;
    foreach my $value (@$line) {
        $i++;
        if(! $ignore_empty || $fields{$i}{length} ) {
            $fields{$i}{length} = length($value)
                if length($value) > $fields{$i}{length};
        }

        next if $ignore_empty;

        $fields{$i}{values}{$value}++;

        foreach my $field_type (@field_type_order) {
            my $regex = $field_types{$field_type};
            if($value =~ $regex) {
                $fields{$i}{types}{$field_type} = $value;
                last;
            }
        }
    }
}

sub padded_line {
    my ($in, $pad) = @_;

    $pad ||= " ";

    my @out;
    my $i2 = -1;
    foreach my $i (sort { $a <=> $b } keys %fields) {
        my $value = $in->[$i];
        next if $fields{$i}{type} =~ /empty|blank/;
        $i2++;
        $fields{$i}{name} = $header[$i];
        my $justify = $fields{$i}{type} eq "num" ? "" : "-";
        $out[$i2] = sprintf('%' . $justify . $fields{$i}{length} . 's', $value);
    }
    return join(" | ", @out) . "\n";
}

sub stats {
    my $s = "File: " . $stats{File};
    local $stats{File};
    delete $stats{File};
    my @r;
    my $i = -1;
    map { $i++; $r[$i] = $_ . ": " . $stats{$_} } sort keys %stats;
    return $s . ", " . join(", ", @r) . "\n";
}

sub create_column_ids_header {
    my $i = -1;
    foreach my $value (@header) {
        $i++;
        $column_ids_header[$i] =
            ($i + 1) . " (" . calculate_alpha_column_name($i + 1) . ") "
            . $fields{$i}{type}
            . " " . keys(%{$fields{$i}{values}});
    }
}

sub set_field_types {
    my $i = -1;
    foreach my $field (@header) {
        $i++;
        foreach my $type (@field_type_order) {
            next if ! exists $fields{$i}{types}{$type};
            $fields{$i}{type} = $type;
            last;
        }
    }
}

END {
    if($is_temp_file) {
        unlink($file) if -e $file;
    }
}

### function _display_jobs() ###################################################
# cleaned up jobs replacement

my $black     = "\x1b[38;5;0m";
my $gray      = "\x1b[38;5;250m";
my $dark_gray = "\x1b[38;5;244m";
my $red       = "\x1b[38;5;124m";

my %cmds      = ();
my %last_args = ();

foreach ( split( "\n", $ENV{_bashrc_jobs} ) ) {

    my ( $jid, $state, $cmd ) = /^(\[\d+\][+-]*)\s+(\S+)\s+(.+)\s*$/;

    next if !$jid;

    $jid =~ s/[\[\]]//g;
    $jid = " $jid" if $jid !~ /\d\d/g;
    my ($wd) = $cmd =~ /\s+\(wd\:\ (.+)\)\s*$/;
    $cmd =~ s/\s+\(wd\:\ (.+)\)\s*$//g;

    $cmd =~ s/^(\w+=\w*\s+)*//g;

    my $args = $cmd;

    ($cmd) = $cmd =~ /^\s*([^\s]+)/;

    my ($last_arg) = $args;
    $last_arg =~ s/(\||\().*$//g;
    $last_arg =~ s/\w*>.*$//g;
    $last_arg =~ s/[\s&]*$//g;
    ($last_arg) = $last_arg =~ /[\s]*([^\s]+|$)$/;
    my $full_last_arg = $last_arg;
    $last_arg =~ s/.*\///g;

    if ( $args eq $cmd ) {
        $args = "";
    }

    if ( $last_arg eq $cmd ) {
        $last_arg = "";
    }

    if ( $cmd eq "(" ) {
        $cmd .= ")";
    }
    else {
        $args = "";
    }

    my $max = $ENV{_bashrc_columns} - length($cmd) - length($last_arg) - 5 - 1;
    my $length = length($args);

    if ( $length > $max ) {
        my $leave = $max / 2;
        $args
            = substr( $args, 0, $leave - 1 )
            . "$red*$gray"
            . substr( $args, $length - $leave + 1, $leave );
    }

    push( @{ $last_args{$last_arg} }, $jid ) if $last_arg;
    $cmds{$jid} = [ $cmd, $last_arg, $args, $full_last_arg, $state ];
}

# lengthen args that are the same until they are not
foreach my $jid ( keys %last_args ) {

    next if @{ $last_args{$jid} } == 1;

    my %diff       = ();
    my $length     = 0;
    my $max_length = 0;

    while (1) {

        %diff = ();
        $length++;

        foreach my $same_jid ( @{ $last_args{$jid} } ) {

            my $arg = $cmds{$same_jid}[3];

            $max_length = length($arg) if length($arg) > $max_length;

            if ( length($arg) <= $length ) {
                $diff{$arg} = $same_jid;
                next;
            }

            $arg = substr( $arg, length($arg) - $length, length($arg) );

            $diff{$arg} = $same_jid;
        }

        last if keys(%diff) == @{ $last_args{$jid} };
        last if $length == $max_length;
    }

    my $final_length = 0;

    # add everything after the first slash
    foreach my $arg ( keys %diff ) {

        my $jid = $diff{$arg};

        my $org_arg = $cmds{$jid}[3];

        ($arg) = $org_arg =~ /.*\/(.+$arg)$/;

        $arg =~ s#/.+/#/\*/#g;

        $final_length = length($arg) if length($arg) > $final_length;

        $cmds{$jid}[1] = $arg;
    }

    # prefix with space to same length
    foreach my $jid ( values %diff ) {
        my $arg = $cmds{$jid}[1];
        $cmds{$jid}[1] = sprintf( "%${final_length}s", $arg );
    }
}

foreach my $jid ( sort keys %cmds ) {

    my ( $cmd, $last_arg, $args, $full_last_arg, $state ) = @{ $cmds{$jid} };

    my $fg = $black;
    $fg = $red if $state =~ /running/i;

    print $fg;
    printf( "%-3s %s %s %s\n",
        $jid, $cmd, $last_arg, $gray . $args . $black );
}

### function simpletree() ######################################################
# tree substitute which groups similar named files

use strict;
use warnings;
no warnings 'uninitialized';
binmode STDOUT, ":utf8";
use File::Basename;
use Cwd;

use Getopt::Long;
Getopt::Long::Configure("bundling");
my $opts = {
    "d|directories-only" => \my $dirs_only,
    "s|summary"          => \my $summary_only,
    "c|sort-by-count"    => \my $sort_by_count,
    "l|list-counts"      => \my $list_counts,
    "a|show-dot-files"   => \my $show_dot_files,
};
GetOptions(%$opts) or die "Usage:\n" . join("\n", sort keys %$opts) . "\n";

my $blue     = "\x1b[34;5;250m";
my $green    = "\x1b[32;5;250m";
my $red      = "\x1b[31;5;250m";
my $gray     = "\x1b[37;5;250m";
my $no_color = "\x1b[33;0m";

my $depth      = -1;
my $max        = $ENV{COLUMNS};
my ($root_dev) = stat ".";
my $mounted    = 0;
my $dirlinks   = 0;
my $root_dir   = $ARGV[0] || getcwd;
my $prefix;

listdir($root_dir);

print $red . "==> Skipped $mounted mounted directories.\n" . $no_color
    if $mounted;
print $red . "==> Skipped $dirlinks linked directories.\n" . $no_color
    if $dirlinks;

sub inc_prefix {
    my ($has_next) = @_;

    return if $depth == -1;

    if ($has_next) {
        $prefix .= "\x{2502}";
    }
    else {
        $prefix .= " ";
    }

    $prefix .= "   ";
}

sub prefix {
    my ( $is_dir, $has_next ) = @_;
    return if $depth == -1;
    my $add_prefix .= $has_next ? "\x{251c}" : "\x{2514}";
    return $prefix . $add_prefix . "\x{2500}\x{2500} ";
}

sub dec_prefix {
    $prefix = substr( $prefix, 0, length($prefix) - 4 );
}

sub listdir {
    my ( $dir, $has_next ) = @_;

    my $normal_dir = 0;
    my ($dev)      = stat $dir;
    my $label      = $depth == -1 && ! $ARGV[0] ? "." : basename($dir);

    if ( -l $dir ) {
        $label .= $red . " -> " . readlink($dir);
        $dirlinks++;
    }
    elsif ( $dev != $root_dev ) {
        $label .= $red . " MOUNTED" . $no_color;
        $mounted++;
    }
    else {
        $normal_dir = 1;
    }

    if ( !$normal_dir ) {
        print prefix(1, $has_next) . $blue . $label . $no_color . "\n";
        return;
    }

    my @dirs       = ();
    my %files      = ();
    my $file_count = 0;

    my @entries;
    opendir(DIR, "$dir") || die $!;
    while(my $entry = readdir(DIR) ) {

        next if $entry =~ /^\.{1,2}$/;
        next if ! $show_dot_files && $entry =~ /^\./;

        $entry = "$dir/$entry";
        push(@entries, $entry);
    }
    closedir(DIR) || die $!;

    foreach my $entry (sort @entries) {

        if ( -d $entry ) {
            push( @dirs, $entry );
            next;
        }

        $file_count++;

        next if $dirs_only;

        my $file    = basename($entry);
        my $cleaned = $file;
        my $link;

        if ( -l $entry ) {
            $link = readlink($entry);
            $cleaned .= $red . " -> $link";
        }
        else {
            $cleaned =~ s/[\d\W_\s]+//g;
        }

        $files{$cleaned}{count}++;
        if ( exists $files{$cleaned}{name} ) {
            if ( length $entry > length $files{$cleaned}{name} ) {
                next;
            }
        }
        $files{$cleaned}{name} = $file;
        $files{$cleaned}{link} = $link if $link;
    }

    if ($list_counts) {
        $label .= " $gray" . @dirs . "/" . $file_count . $no_color
            if $file_count || @dirs;
    }
    print prefix( 1, $has_next ) . $blue . $label . $no_color . "\n";

    inc_prefix($has_next);

    $depth++;
    {
        my $dir_entry_number = 0;
        my $dir_entry_count  = @dirs;
        foreach my $lower_dir (@dirs) {

            $dir_entry_number++;

            my $has_next = $dir_entry_number != $dir_entry_count;
            listdir( $lower_dir, %files || $has_next );
        }
    }

    if ($dirs_only) {
        dec_prefix();
        $depth--;
        return;
    }

    my %file_counts = ();
    foreach my $file ( sort keys %files ) {
        my $count = $files{$file}{count};
        $count = 1 if !$sort_by_count;
        my $example_file = $files{$file}{name};
        $file_counts{$count}{$file} = $example_file;
    }

    my $shown_files = 0;

DIR: foreach my $count_order ( sort { $b <=> $a } keys %file_counts ) {

        my $entry_number = 0;
        my $entry_count  = keys %{ $file_counts{$count_order} };
        foreach my $cleaned ( sort keys %{ $file_counts{$count_order} } ) {

            $entry_number++;

            my $count = $count_order;
            $count = $files{$cleaned}{count} if !$sort_by_count;

            my $count_label;
            if ( $count > 1 ) {
                $count_label = $gray . "$count*" . $no_color if $count > 1;
            }

            my $file = $files{$cleaned}{name};
            my $link = $files{$cleaned}{link};

            if($count > 1) {
                $file =~ s/[\d\W_\s]+/$red*$green/g;
            }

            $file = $green . $file . $no_color;

            $file = $red . "{" . $file . $red . "}" . $no_color
                if $count > 1;
            $file .= $red . " -> $link" . $no_color if $link;

            print prefix( 0, $entry_number != $entry_count ) 
                . $count_label
                . $file
                . " \n";

            $shown_files++;

            if ( $shown_files == 3 && $summary_only ) {

                next if keys %files == 4;

                if ( keys %files > 3 ) {
                    print prefix . "...\n";
                }

                last DIR;
            }
        }
    }

    dec_prefix();
    $depth--;
}

### function xmv() #############################################################
# Rename files by perl expression protect against duplicate resulting file names

# use warnings FATAL => 'all';
use File::Basename;

use Getopt::Long;
Getopt::Long::Configure('bundling');

my $dry = 1;

my $opts = {
    'x|execute' => sub { $dry = 0 },
    'd|include-directories' => \my $include_directories,
    'n|normalize'           => \my $normalize,
    'e|execute-perl=s'      => \my $op,
    'l|list-from-file=s'    => \my $list_file,
    'S|dont-split-off-dir'  => \my $dont_split_off_dir,
};
GetOptions(%$opts) or die "Usage:\n" . join("\n", sort keys %$opts) . "\n";

if($list_file) {
    open(F, $list_file) || die $!;
    @ARGV = <F>;
    close(F);
    map { chop } @ARGV;
}

if (!@ARGV) {
    die "Usage: xmv [-x] [-d] [-n] [-l file] [-S] [-e perlexpr] [filenames]\n";
}

my %will  = ();
my %was   = ();
my $abort = 0;
my $COUNT = 0;

for (@ARGV) {

    next if /^\.{1,2}$/;

    my $abs = $_;
    my $dir = dirname($_);
    my $file = basename($_);

    if($dont_split_off_dir) {
        $dir = "";
        $file = $_;
    }

    $dir = "" if $dir eq ".";
    $dir .= "/" if $dir;

    $abs = $dir . $file;
    my $was = $file;
    $_ = $file;

    $_ = normalize($abs) if $normalize;

    # vars to use in perlexpr
    $COUNT++;
    $COUNT = sprintf("%0". length(scalar(@ARGV)) ."d", $COUNT);

    if ($op) {
        eval $op;
        die $@ if $@;
    }

    my $will = $dir . $_;

    if (!-e $abs) {
        warn "no such file: '$was'";
        $abort = 1;
        next;
    }

    if (-d $abs && !$include_directories) {
        next;
    }

    my $other = $will{$will} if exists $will{$will};
    if ($other) {
        warn "name '$will' for '$abs' already taken by '$other'.";
        $abort = 1;
        next;
    }

    next if $will eq $abs;

    if (-e $will) {
        warn "file '$will' already exists.";
        $abort = 1;
        next;
    }

    $will{$will} = $abs;
    $was{$abs}   = $will;
}

exit 1 if $abort;

foreach my $was (sort keys %was) {

    my $will = $was{$was};

    print "moving '$was' -> '$will'\n";

    next if $dry;

    system("mv", $was, $will) && die $!;
}

sub normalize {
    my ($abs) = @_;

    my $file = basename($abs);
    my $ext  = "";

    if (!-d $abs && $file =~ /^(.+)(\..+?)$/) {
        ($file, $ext) = ($1, $2);
    }

    $_ = $file;

    s/www\.[^\.]+\.[[:alnum:]]+//g;
    s/'//g;
    s/[^\w\.]+/_/g;
    s/[\._]+/_/g;
    s/^[\._]+//g;
    s/[\._]+$//g;

    $_ ||= "_empty_file_name";

    return $_ . lc($ext);
}

### function filltemplate() ####################################################
# create a file from a template

use File::Copy;

die "Usage: filltemplate" .
    " file_to_create_from_template field1=value1 field2=value2 ...\n"
    if @ARGV < 2;

my ($file, @tuples) = @ARGV;
my $template = $file. ".template";

die "Template not found: $template" if !-e $template;
die "Specify mappings." if !@tuples;

$/ = undef;

open(my $templatef, "<", $template) || die $!;
my $data = <$templatef>;
close($templatef);

for my $tuple (@tuples) {

    my ($name, $value) = $tuple =~ /^(.+?)=(.+)$/;

    $name = "TEMPL_" . uc($name);

    die "No such field: $name\n" if $data !~ /$name/;

    $data =~ s/$name/$value/igm;
}

my $temp = "/tmp/$file.$$"; 
open(my $tempf, ">", $temp) || die $!;
print $tempf $data;
close($tempf);

move($temp, $file) || die $!;

### function wcat() ############################################################

use Getopt::Long;
Getopt::Long::Configure("bundling");

my $opts = {
    "h|headers"      => \my $show_headers,
    "s|strip-tags"   => \my $strip_tags,
    "f|save-to-file" => \my $to_file,
    "o|overwrite"    => \my $overwrite,
};
GetOptions(%$opts) or die "Usage:\n" . join( "\n", sort keys %$opts ) . "\n";

my $url = $ARGV[0] || die "Specify URL.";

if ( $url !~ m#^(.+?)://# ) {
    $url = "http://$url";
}

my $file;
if($to_file) {
    ($file) = $url =~ m#^.+?://.*?/(.+)$#;
    print "Saving as: $file\n";
    die "Error creating file name from url." if ! $file;
    die "File exists: $file" if -f $file && ! $overwrite;
}

my $response = HTTP::Tiny->new->get($url);

die "Failed: " . $response->{status} . " = " . $response->{reason} . "\n"
    unless $response->{success};

if ($show_headers) {
    while ( my ( $k, $v ) = each %{ $response->{headers} } ) {
        for ( ref $v eq 'ARRAY' ? @$v : $v ) {
            print "$k: $_\n";
        }
    }
    exit;
}

exit if ! length $response->{content};

my $content = $response->{content};

if($strip_tags) {
    $content =~ s#<\s*script.+?>.+?</script>##imsg;
    $content =~ s#<\s*head.+?>.+?</head>##imsg;
    $content =~ s#\n+##igms;
    $content =~ s#<(br)/*>#\n#igms;
    $content =~ s#<(li).*?>#\* #igms;
    $content =~ s#</(li).*?>#\n#igms;
    $content =~ s#</(p|div).*?>#\n\n#igms;
    $content =~ s#</h\d+.*?>#\n\n#igms;
    $content =~ s#<.+?/>\n*##igms;
    $content =~ s#<td.*?>#\t#igms;
    $content =~ s#</tr.*?>#\n#igms;

    $content =~ s#<.+?>##igms;

    $content =~ s#&minus;#-#igms;
    $content =~ s#&gt;#>#igms;
    $content =~ s#&lt;#<#igms;
    $content =~ s#&\w+;# #igms;
    $content =~ s/&#\d+;/ /igms;
}

if($to_file) {
    open(F, ">", $file) || die $!;
    print F $content;
    close(F);
} else {
    print $content;
}

BEGIN {

    package HTTP::Tiny;

    use strict;
    use warnings;
    our $VERSION = '0.013';    # VERSION

    use Carp ();

    my @attributes;

    BEGIN {
        @attributes
            = qw(agent default_headers max_redirect max_size proxy timeout);
        no strict 'refs';
        for my $accessor (@attributes) {
            *{$accessor} = sub {
                @_ > 1 ? $_[0]->{$accessor} = $_[1] : $_[0]->{$accessor};
            };
        }
    }

    sub new {
        my ( $class, %args ) = @_;
        ( my $agent = $class ) =~ s{::}{-}g;
        my $self = {
            agent => $agent . "/" . ( $class->VERSION || 0 ),
            max_redirect => 5,
            timeout      => 60,
        };
        for my $key (@attributes) {
            $self->{$key} = $args{$key} if exists $args{$key};
        }

        # Never override proxy argument as this breaks backwards compat.
        if ( !exists $self->{proxy} && ( my $http_proxy = $ENV{http_proxy} ) ) {
            if ( $http_proxy =~ m{\Ahttp://[^/?#:@]+:\d+/?\z} ) {
                $self->{proxy} = $http_proxy;
            }
            else {
                Carp::croak(
                    qq{Environment 'http_proxy' must be in format http://<host>:<port>/\n}
                );
            }
        }

        return bless $self, $class;
    }

    sub get {
        my ( $self, $url, $args ) = @_;
        @_ == 2 || ( @_ == 3 && ref $args eq 'HASH' )
            or Carp::croak( q/Usage: $http->get(URL, [HASHREF])/ . "\n" );
        return $self->request( 'GET', $url, $args || {} );
    }

    sub mirror {
        my ( $self, $url, $file, $args ) = @_;
        @_ == 3 || ( @_ == 4 && ref $args eq 'HASH' )
            or
            Carp::croak( q/Usage: $http->mirror(URL, FILE, [HASHREF])/ . "\n" );
        if ( -e $file and my $mtime = ( stat($file) )[9] ) {
            $args->{headers}{'if-modified-since'} ||= $self->_http_date($mtime);
        }
        my $tempfile = $file . int( rand( 2**31 ) );
        open my $fh, ">", $tempfile
            or Carp::croak(
            qq/Error: Could not open temporary file $tempfile for downloading: $!\n/
            );
        binmode $fh;
        $args->{data_callback} = sub { print {$fh} $_[0] };
        my $response = $self->request( 'GET', $url, $args );
        close $fh
            or Carp::croak(
            qq/Error: Could not close temporary file $tempfile: $!\n/);
        if ( $response->{success} ) {
            rename $tempfile, $file
                or Carp::croak(qq/Error replacing $file with $tempfile: $!\n/);
            my $lm = $response->{headers}{'last-modified'};
            if ( $lm and my $mtime = $self->_parse_http_date($lm) ) {
                utime $mtime, $mtime, $file;
            }
        }
        $response->{success} ||= $response->{status} eq '304';
        unlink $tempfile;
        return $response;
    }

    my %idempotent = map { $_ => 1 } qw/GET HEAD PUT DELETE OPTIONS TRACE/;

    sub request {
        my ( $self, $method, $url, $args ) = @_;
        @_ == 3 || ( @_ == 4 && ref $args eq 'HASH' )
            or Carp::croak(
            q/Usage: $http->request(METHOD, URL, [HASHREF])/ . "\n" );
        $args ||= {};    # we keep some state in this during _request

        # RFC 2616 Section 8.1.4 mandates a single retry on broken socket
        my $response;
        for ( 0 .. 1 ) {
            $response = eval { $self->_request( $method, $url, $args ) };
            last
                unless $@
                    && $idempotent{$method}
                    && $@ =~ m{^(?:Socket closed|Unexpected end)};
        }

        if ( my $e = "$@" ) {
            $response = {
                success => q{},
                status  => 599,
                reason  => 'Internal Exception',
                content => $e,
                headers => {
                    'content-type'   => 'text/plain',
                    'content-length' => length $e,
                }
            };
        }
        return $response;
    }

    my %DefaultPort = (
        http  => 80,
        https => 443,
    );

    sub _request {
        my ( $self, $method, $url, $args ) = @_;

        my ( $scheme, $host, $port, $path_query ) = $self->_split_url($url);

        my $request = {
            method => $method,
            scheme => $scheme,
            host_port =>
                ( $port == $DefaultPort{$scheme} ? $host : "$host:$port" ),
            uri     => $path_query,
            headers => {},
        };

        my $handle = HTTP::Tiny::Handle->new( timeout => $self->{timeout} );

        if ( $self->{proxy} ) {
            $request->{uri} = "$scheme://$request->{host_port}$path_query";
            die(qq/HTTPS via proxy is not supported\n/)
                if $request->{scheme} eq 'https';
            $handle->connect(
                ( $self->_split_url( $self->{proxy} ) )[ 0 .. 2 ] );
        }
        else {
            $handle->connect( $scheme, $host, $port );
        }

        $self->_prepare_headers_and_cb( $request, $args );
        $handle->write_request($request);

        my $response;
        do { $response = $handle->read_response_header }
            until ( substr( $response->{status}, 0, 1 ) ne '1' );

        if ( my @redir_args
            = $self->_maybe_redirect( $request, $response, $args ) )
        {
            $handle->close;
            return $self->_request( @redir_args, $args );
        }

        if ( $method eq 'HEAD' || $response->{status} =~ /^[23]04/ ) {

            # response has no message body
        }
        else {
            my $data_cb = $self->_prepare_data_cb( $response, $args );
            $handle->read_body( $data_cb, $response );
        }

        $handle->close;
        $response->{success} = substr( $response->{status}, 0, 1 ) eq '2';
        return $response;
    }

    sub _prepare_headers_and_cb {
        my ( $self, $request, $args ) = @_;

        for ( $self->{default_headers}, $args->{headers} ) {
            next unless defined;
            while ( my ( $k, $v ) = each %$_ ) {
                $request->{headers}{ lc $k } = $v;
            }
        }
        $request->{headers}{'host'}       = $request->{host_port};
        $request->{headers}{'connection'} = "close";
        $request->{headers}{'user-agent'} ||= $self->{agent};

        if ( defined $args->{content} ) {
            $request->{headers}{'content-type'} ||= "application/octet-stream";
            if ( ref $args->{content} eq 'CODE' ) {
                $request->{headers}{'transfer-encoding'} = 'chunked'
                    unless $request->{headers}{'content-length'}
                        || $request->{headers}{'transfer-encoding'};
                $request->{cb} = $args->{content};
            }
            else {
                my $content = $args->{content};
                if ( $] ge '5.008' ) {
                    utf8::downgrade( $content, 1 )
                        or die(qq/Wide character in request message body\n/);
                }
                $request->{headers}{'content-length'} = length $content
                    unless $request->{headers}{'content-length'}
                        || $request->{headers}{'transfer-encoding'};
                $request->{cb}
                    = sub { substr $content, 0, length $content, '' };
            }
            $request->{trailer_cb} = $args->{trailer_callback}
                if ref $args->{trailer_callback} eq 'CODE';
        }
        return;
    }

    sub _prepare_data_cb {
        my ( $self, $response, $args ) = @_;
        my $data_cb = $args->{data_callback};
        $response->{content} = '';

        if ( !$data_cb || $response->{status} !~ /^2/ ) {
            if ( defined $self->{max_size} ) {
                $data_cb = sub {
                    $_[1]->{content} .= $_[0];
                    die(qq/Size of response body exceeds the maximum allowed of $self->{max_size}\n/
                    ) if length $_[1]->{content} > $self->{max_size};
                };
            }
            else {
                $data_cb = sub { $_[1]->{content} .= $_[0] };
            }
        }
        return $data_cb;
    }

    sub _maybe_redirect {
        my ( $self, $request, $response, $args ) = @_;
        my $headers = $response->{headers};
        my ( $status, $method ) = ( $response->{status}, $request->{method} );
        if ((   $status eq '303'
                or ( $status =~ /^30[127]/ && $method =~ /^GET|HEAD$/ )
            )
            and $headers->{location}
            and ++$args->{redirects} <= $self->{max_redirect}
            )
        {
            my $location
                = ( $headers->{location} =~ /^\// )
                ? "$request->{scheme}://$request->{host_port}$headers->{location}"
                : $headers->{location};
            return ( ( $status eq '303' ? 'GET' : $method ), $location );
        }
        return;
    }

    sub _split_url {
        my $url = pop;

        # URI regex adapted from the URI module
        my ( $scheme, $authority, $path_query )
            = $url =~ m<\A([^:/?#]+)://([^/?#]*)([^#]*)>
            or die(qq/Cannot parse URL: '$url'\n/);

        $scheme = lc $scheme;
        $path_query = "/$path_query" unless $path_query =~ m<\A/>;

        my $host = ( length($authority) ) ? lc $authority : 'localhost';
        $host =~ s/\A[^@]*@//;    # userinfo
        my $port = do {
            $host =~ s/:([0-9]*)\z// && length $1
                ? $1
                : ( $scheme eq 'http' ? 80 : $scheme eq 'https' ? 443 : undef );
        };

        return ( $scheme, $host, $port, $path_query );
    }

    # Date conversions adapted from HTTP::Date
    my $DoW = "Sun|Mon|Tue|Wed|Thu|Fri|Sat";
    my $MoY = "Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec";

    sub _http_date {
        my ( $sec, $min, $hour, $mday, $mon, $year, $wday ) = gmtime( $_[1] );
        return sprintf(
            "%s, %02d %s %04d %02d:%02d:%02d GMT",
            substr( $DoW, $wday * 4, 3 ),
            $mday,
            substr( $MoY, $mon * 4, 3 ),
            $year + 1900,
            $hour, $min, $sec
        );
    }

    sub _parse_http_date {
        my ( $self, $str ) = @_;
        require Time::Local;
        my @tl_parts;
        if ( $str
            =~ /^[SMTWF][a-z]+, +(\d{1,2}) ($MoY) +(\d\d\d\d) +(\d\d):(\d\d):(\d\d) +GMT$/
            )
        {
            @tl_parts = ( $6, $5, $4, $1, ( index( $MoY, $2 ) / 4 ), $3 );
        }
        elsif ( $str
            =~ /^[SMTWF][a-z]+, +(\d\d)-($MoY)-(\d{2,4}) +(\d\d):(\d\d):(\d\d) +GMT$/
            )
        {
            @tl_parts = ( $6, $5, $4, $1, ( index( $MoY, $2 ) / 4 ), $3 );
        }
        elsif ( $str
            =~ /^[SMTWF][a-z]+ +($MoY) +(\d{1,2}) +(\d\d):(\d\d):(\d\d) +(?:[^0-9]+ +)?(\d\d\d\d)$/
            )
        {
            @tl_parts = ( $5, $4, $3, $2, ( index( $MoY, $1 ) / 4 ), $6 );
        }
        return eval {
            my $t = @tl_parts ? Time::Local::timegm(@tl_parts) : -1;
            $t < 0 ? undef : $t;
        };
    }

    package HTTP::Tiny::Handle;    # hide from PAUSE/indexers
    use strict;
    use warnings;

    use Errno qw[EINTR EPIPE];
    use IO::Socket qw[SOCK_STREAM];

    sub BUFSIZE () {32768}

    my $Printable = sub {
        local $_ = shift;
        s/\r/\\r/g;
        s/\n/\\n/g;
        s/\t/\\t/g;
        s/([^\x20-\x7E])/sprintf('\\x%.2X', ord($1))/ge;
        $_;
    };

    my $Token
        = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E]/;

    sub new {
        my ( $class, %args ) = @_;
        return bless {
            rbuf             => '',
            timeout          => 60,
            max_line_size    => 16384,
            max_header_lines => 64,
            %args
        }, $class;
    }

    my $ssl_verify_args = {
        check_cn         => "when_only",
        wildcards_in_alt => "anywhere",
        wildcards_in_cn  => "anywhere"
    };

    sub connect {
        @_ == 4 || die( q/Usage: $handle->connect(scheme, host, port)/ . "\n" );
        my ( $self, $scheme, $host, $port ) = @_;

        if ( $scheme eq 'https' ) {
            eval "require IO::Socket::SSL"
                unless exists $INC{'IO/Socket/SSL.pm'};
            die(qq/IO::Socket::SSL must be installed for https support\n/)
                unless $INC{'IO/Socket/SSL.pm'};
        }
        elsif ( $scheme ne 'http' ) {
            die(qq/Unsupported URL scheme '$scheme'\n/);
        }

        $self->{fh} = 'IO::Socket::INET'->new(
            PeerHost => $host,
            PeerPort => $port,
            Proto    => 'tcp',
            Type     => SOCK_STREAM,
            Timeout  => $self->{timeout}
        ) or die(qq/Could not connect to '$host:$port': $@\n/);

        binmode( $self->{fh} )
            or die(qq/Could not binmode() socket: '$!'\n/);

        if ( $scheme eq 'https' ) {
            IO::Socket::SSL->start_SSL( $self->{fh} );
            ref( $self->{fh} ) eq 'IO::Socket::SSL'
                or die(qq/SSL connection failed for $host\n/);
            $self->{fh}->verify_hostname( $host, $ssl_verify_args )
                or die(qq/SSL certificate not valid for $host\n/);
        }

        $self->{host} = $host;
        $self->{port} = $port;

        return $self;
    }

    sub close {
        @_ == 1 || die( q/Usage: $handle->close()/ . "\n" );
        my ($self) = @_;
        CORE::close( $self->{fh} )
            or die(qq/Could not close socket: '$!'\n/);
    }

    sub write {
        @_ == 2 || die( q/Usage: $handle->write(buf)/ . "\n" );
        my ( $self, $buf ) = @_;

        if ( $] ge '5.008' ) {
            utf8::downgrade( $buf, 1 )
                or die(qq/Wide character in write()\n/);
        }

        my $len = length $buf;
        my $off = 0;

        local $SIG{PIPE} = 'IGNORE';

        while () {
            $self->can_write
                or die(
                qq/Timed out while waiting for socket to become ready for writing\n/
                );
            my $r = syswrite( $self->{fh}, $buf, $len, $off );
            if ( defined $r ) {
                $len -= $r;
                $off += $r;
                last unless $len > 0;
            }
            elsif ( $! == EPIPE ) {
                die(qq/Socket closed by remote server: $!\n/);
            }
            elsif ( $! != EINTR ) {
                die(qq/Could not write to socket: '$!'\n/);
            }
        }
        return $off;
    }

    sub read {
        @_ == 2
            || @_ == 3
            || die( q/Usage: $handle->read(len [, allow_partial])/ . "\n" );
        my ( $self, $len, $allow_partial ) = @_;

        my $buf = '';
        my $got = length $self->{rbuf};

        if ($got) {
            my $take = ( $got < $len ) ? $got : $len;
            $buf = substr( $self->{rbuf}, 0, $take, '' );
            $len -= $take;
        }

        while ( $len > 0 ) {
            $self->can_read
                or die(
                q/Timed out while waiting for socket to become ready for reading/
                    . "\n" );
            my $r = sysread( $self->{fh}, $buf, $len, length $buf );
            if ( defined $r ) {
                last unless $r;
                $len -= $r;
            }
            elsif ( $! != EINTR ) {
                die(qq/Could not read from socket: '$!'\n/);
            }
        }
        if ( $len && !$allow_partial ) {
            die(qq/Unexpected end of stream\n/);
        }
        return $buf;
    }

    sub readline {
        @_ == 1 || die( q/Usage: $handle->readline()/ . "\n" );
        my ($self) = @_;

        while () {
            if ( $self->{rbuf} =~ s/\A ([^\x0D\x0A]* \x0D?\x0A)//x ) {
                return $1;
            }
            if ( length $self->{rbuf} >= $self->{max_line_size} ) {
                die(qq/Line size exceeds the maximum allowed size of $self->{max_line_size}\n/
                );
            }
            $self->can_read
                or die(
                qq/Timed out while waiting for socket to become ready for reading\n/
                );
            my $r = sysread( $self->{fh}, $self->{rbuf}, BUFSIZE,
                length $self->{rbuf} );
            if ( defined $r ) {
                last unless $r;
            }
            elsif ( $! != EINTR ) {
                die(qq/Could not read from socket: '$!'\n/);
            }
        }
        die(qq/Unexpected end of stream while looking for line\n/);
    }

    sub read_header_lines {
        @_ == 1
            || @_ == 2
            || die( q/Usage: $handle->read_header_lines([headers])/ . "\n" );
        my ( $self, $headers ) = @_;
        $headers ||= {};
        my $lines = 0;
        my $val;

        while () {
            my $line = $self->readline;

            if ( ++$lines >= $self->{max_header_lines} ) {
                die(qq/Header lines exceeds maximum number allowed of $self->{max_header_lines}\n/
                );
            }
            elsif ( $line
                =~ /\A ([^\x00-\x1F\x7F:]+) : [\x09\x20]* ([^\x0D\x0A]*)/x )
            {
                my ($field_name) = lc $1;
                if ( exists $headers->{$field_name} ) {
                    for ( $headers->{$field_name} ) {
                        $_ = [$_] unless ref $_ eq "ARRAY";
                        push @$_, $2;
                        $val = \$_->[-1];
                    }
                }
                else {
                    $val = \( $headers->{$field_name} = $2 );
                }
            }
            elsif ( $line =~ /\A [\x09\x20]+ ([^\x0D\x0A]*)/x ) {
                $val
                    or die(qq/Unexpected header continuation line\n/);
                next unless length $1;
                $$val .= ' ' if length $$val;
                $$val .= $1;
            }
            elsif ( $line =~ /\A \x0D?\x0A \z/x ) {
                last;
            }
            else {
                die( q/Malformed header line: / . $Printable->($line) . "\n" );
            }
        }
        return $headers;
    }

    sub write_request {
        @_ == 2 || die( q/Usage: $handle->write_request(request)/ . "\n" );
        my ( $self, $request ) = @_;
        $self->write_request_header( @{$request}{qw/method uri headers/} );
        $self->write_body($request) if $request->{cb};
        return;
    }

    my %HeaderCase = (
        'content-md5'      => 'Content-MD5',
        'etag'             => 'ETag',
        'te'               => 'TE',
        'www-authenticate' => 'WWW-Authenticate',
        'x-xss-protection' => 'X-XSS-Protection',
    );

    sub write_header_lines {
        ( @_ == 2 && ref $_[1] eq 'HASH' )
            || die( q/Usage: $handle->write_header_lines(headers)/ . "\n" );
        my ( $self, $headers ) = @_;

        my $buf = '';
        while ( my ( $k, $v ) = each %$headers ) {
            my $field_name = lc $k;
            if ( exists $HeaderCase{$field_name} ) {
                $field_name = $HeaderCase{$field_name};
            }
            else {
                $field_name =~ /\A $Token+ \z/xo
                    or die( q/Invalid HTTP header field name: /
                        . $Printable->($field_name)
                        . "\n" );
                $field_name =~ s/\b(\w)/\u$1/g;
                $HeaderCase{ lc $field_name } = $field_name;
            }
            for ( ref $v eq 'ARRAY' ? @$v : $v ) {
                /[^\x0D\x0A]/
                    or die( qq/Invalid HTTP header field value ($field_name): /
                        . $Printable->($_)
                        . "\n" );
                $buf .= "$field_name: $_\x0D\x0A";
            }
        }
        $buf .= "\x0D\x0A";
        return $self->write($buf);
    }

    sub read_body {
        @_ == 3
            || die( q/Usage: $handle->read_body(callback, response)/ . "\n" );
        my ( $self, $cb, $response ) = @_;
        my $te = $response->{headers}{'transfer-encoding'} || '';
        if ( grep {/chunked/i} ( ref $te eq 'ARRAY' ? @$te : $te ) ) {
            $self->read_chunked_body( $cb, $response );
        }
        else {
            $self->read_content_body( $cb, $response );
        }
        return;
    }

    sub write_body {
        @_ == 2 || die( q/Usage: $handle->write_body(request)/ . "\n" );
        my ( $self, $request ) = @_;
        if ( $request->{headers}{'content-length'} ) {
            return $self->write_content_body($request);
        }
        else {
            return $self->write_chunked_body($request);
        }
    }

    sub read_content_body {
        @_ == 3
            || @_ == 4
            || die(
            q/Usage: $handle->read_content_body(callback, response, [read_length])/
                . "\n" );
        my ( $self, $cb, $response, $content_length ) = @_;
        $content_length ||= $response->{headers}{'content-length'};

        if ($content_length) {
            my $len = $content_length;
            while ( $len > 0 ) {
                my $read = ( $len > BUFSIZE ) ? BUFSIZE : $len;
                $cb->( $self->read( $read, 0 ), $response );
                $len -= $read;
            }
        }
        else {
            my $chunk;
            $cb->( $chunk, $response )
                while length( $chunk = $self->read( BUFSIZE, 1 ) );
        }

        return;
    }

    sub write_content_body {
        @_ == 2 || die( q/Usage: $handle->write_content_body(request)/ . "\n" );
        my ( $self, $request ) = @_;

        my ( $len, $content_length )
            = ( 0, $request->{headers}{'content-length'} );
        while () {
            my $data = $request->{cb}->();

            defined $data && length $data
                or last;

            if ( $] ge '5.008' ) {
                utf8::downgrade( $data, 1 )
                    or die(qq/Wide character in write_content()\n/);
            }

            $len += $self->write($data);
        }

        $len == $content_length
            or die(
            qq/Content-Length missmatch (got: $len expected: $content_length)\n/
            );

        return $len;
    }

    sub read_chunked_body {
        @_ == 3
            || die(
            q/Usage: $handle->read_chunked_body(callback, $response)/ . "\n" );
        my ( $self, $cb, $response ) = @_;

        while () {
            my $head = $self->readline;

            $head =~ /\A ([A-Fa-f0-9]+)/x
                or
                die( q/Malformed chunk head: / . $Printable->($head) . "\n" );

            my $len = hex($1)
                or last;

            $self->read_content_body( $cb, $response, $len );

            $self->read(2) eq "\x0D\x0A"
                or die(qq/Malformed chunk: missing CRLF after chunk data\n/);
        }
        $self->read_header_lines( $response->{headers} );
        return;
    }

    sub write_chunked_body {
        @_ == 2 || die( q/Usage: $handle->write_chunked_body(request)/ . "\n" );
        my ( $self, $request ) = @_;

        my $len = 0;
        while () {
            my $data = $request->{cb}->();

            defined $data && length $data
                or last;

            if ( $] ge '5.008' ) {
                utf8::downgrade( $data, 1 )
                    or die(qq/Wide character in write_chunked_body()\n/);
            }

            $len += length $data;

            my $chunk = sprintf '%X', length $data;
            $chunk .= "\x0D\x0A";
            $chunk .= $data;
            $chunk .= "\x0D\x0A";

            $self->write($chunk);
        }
        $self->write("0\x0D\x0A");
        $self->write_header_lines( $request->{trailer_cb}->() )
            if ref $request->{trailer_cb} eq 'CODE';
        return $len;
    }

    sub read_response_header {
        @_ == 1 || die( q/Usage: $handle->read_response_header()/ . "\n" );
        my ($self) = @_;

        my $line = $self->readline;

        $line
            =~ /\A (HTTP\/(0*\d+\.0*\d+)) [\x09\x20]+ ([0-9]{3}) [\x09\x20]+ ([^\x0D\x0A]*) \x0D?\x0A/x
            or die( q/Malformed Status-Line: / . $Printable->($line) . "\n" );

        my ( $protocol, $version, $status, $reason ) = ( $1, $2, $3, $4 );

        die(qq/Unsupported HTTP protocol: $protocol\n/)
            unless $version =~ /0*1\.0*[01]/;

        return {
            status   => $status,
            reason   => $reason,
            headers  => $self->read_header_lines,
            protocol => $protocol,
        };
    }

    sub write_request_header {
        @_ == 4
            || die(
            q/Usage: $handle->write_request_header(method, request_uri, headers)/
                . "\n" );
        my ( $self, $method, $request_uri, $headers ) = @_;

        return $self->write("$method $request_uri HTTP/1.1\x0D\x0A")
            + $self->write_header_lines($headers);
    }

    sub _do_timeout {
        my ( $self, $type, $timeout ) = @_;
        $timeout = $self->{timeout}
            unless defined $timeout && $timeout >= 0;

        my $fd = fileno $self->{fh};
        defined $fd && $fd >= 0
            or die(qq/select(2): 'Bad file descriptor'\n/);

        my $initial = time;
        my $pending = $timeout;
        my $nfound;

        vec( my $fdset = '', $fd, 1 ) = 1;

        while () {
            $nfound
                = ( $type eq 'read' )
                ? select( $fdset, undef,  undef, $pending )
                : select( undef,  $fdset, undef, $pending );
            if ( $nfound == -1 ) {
                $! == EINTR
                    or die(qq/select(2): '$!'\n/);
                redo
                    if !$timeout
                        || ( $pending = $timeout - ( time - $initial ) ) > 0;
                $nfound = 0;
            }
            last;
        }
        $! = 0;
        return $nfound;
    }

    sub can_read {
        @_ == 1
            || @_ == 2
            || die( q/Usage: $handle->can_read([timeout])/ . "\n" );
        my $self = shift;
        return $self->_do_timeout( 'read', @_ );
    }

    sub can_write {
        @_ == 1
            || @_ == 2
            || die( q/Usage: $handle->can_write([timeout])/ . "\n" );
        my $self = shift;
        return $self->_do_timeout( 'write', @_ );
    }

    1;
}

### function _andgrep() ############################################################

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
Getopt::Long::Configure("bundling");

my $red      = "\x1b[38;5;124m";
my $no_color = "\x1b[33;0m";

my $opts = {
    "f|file=s" => \my $file,
    "p|prefix-file-name" => \my $prefix,
};
GetOptions(%$opts) or die "Usage:\n$0 " . join( "\n", sort keys %$opts ) . "\n";

my @patterns = @ARGV;
@patterns || die "Specify patterns to search for.";

my $h = *STDIN;
if ($file) {
    open( $h, $file ) || die $!;
}

LINE: while (<$h>) {

    foreach my $pattern (@patterns) {
        if ( !s/$pattern/$red${pattern}$no_color/gi ) {
            next LINE;
        }
    }

    if($prefix) {
        print "$file:$.:$_";
    } else {
        print;
    }
}

### END ########################################################################
