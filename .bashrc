### stuff also needed non-interactively ########################################

### init perl lib path #########################################################

unset PERL5LIB
for dir in ~/{perllib,perl}/* ; do

    if [ ! -d $dir ] ; then
        continue;
    fi

    if [ -d $dir/lib ] ; then
        dir=$dir/lib
    fi

    if [[ $PERL5LIB = "" ]] ; then
        PERL5LIB=$dir
    else
        PERL5LIB=$PERL5LIB:$dir
    fi
done

export PERL5LIB

################################################################################

function normalize_file_names() {

    local IFS=$'\n'

    perl - $@ <<'EOF'
        use strict;
        use warnings;
        no warnings 'uninitialized';
        use File::Copy;
        use File::Basename;

        my $for_real = 0;

        FOR_REAL:

        my %dsts = ();
        foreach my $src_abs (@ARGV) {

            my $dir = dirname($src_abs) . "/";
            my $dst = basename($src_abs);

            $dst =~ s/\n//g;

            my $type;
            if ( !-d $src_abs ) {
                if ( $dst =~ /^(.+)\.(.+?)$/ ) {
                    $dst  = $1;
                    if($2) {
                        $type = "." . lc($2);
                    }
                }
            }

            $dst =~ s/www\.[^\.]+\.[^\.]+//g;

            $dst =~ s/[^\w\.]+/_/g;
            $dst =~ s/^_+//g;

            $dst =~ s/[\._]+$//g;

            $dst =~ s/[\._]{2,}/_/g;
            $dst =~ s/[\.]+/\./g;
            $dst =~ s/^\.+//g;

            die "file empty for '$src_abs'" if !$dst;

            if ( $type && !-d $src_abs ) {
                $dst = $dst . $type;
            }

            my $dst_abs = $dir . $dst;

            next if $dst eq basename($src_abs);

            die "file already exists: $dst_abs" if -e $dst_abs;

            die "2 files normalized to: $dst_abs:\n   "
                . $dsts{$dst_abs} . "\n   " . $src_abs . "\n"
                if exists $dsts{$dst_abs};

            $dsts{$dst_abs} = $src_abs;

            if ($for_real) {
                print("mv $src_abs -> $dst_abs\n");
                move( $src_abs, $dst_abs ) || die($!);
            }
        }

        if ( !$for_real ) {
            $for_real = 1;
            goto FOR_REAL;
        }
EOF
}
export -f normalize_file_names

function replace() {

    local search=$1
    local replace=$2
    local files=$3

    if [[ $search = "" || $replace = "" || $files = "" ]] ; then
        echo 'usage: replace "search" "replace" "file pattern"'
        return 1
    fi

    find -iname "$files" -exec perl -p -i -e 's/'$search'/'$replace'/g' {} \;
}
export -f replace

function DEBUG() {
    if [ -t 1 ] ; then
        local _COLOR=$GRAY2
        local _NO_COLOR=$NO_COLOR2
    fi
    echo -e "${_COLOR}$(date +'%F %T') DEBUG> $@${_NO_COLOR}" ;
}

function INFO()  { echo -e "$(date +'%F %T') INFO > $@" ; }

function WARN() {
    if [ -t 2 ] ; then
        local _COLOR=$ORANGE2
        local _NO_COLOR=$NO_COLOR2
    fi
    echo -e "${_COLOR}$(date +'%F %T') WARN > $@${_NO_COLOR}" >&2 ;
}

function ERROR() {
    if [ -t 2 ] ; then
        local _COLOR=$RED2
        local _NO_COLOR=$NO_COLOR2
    fi
    echo -e "${_COLOR}$(date +'%F %T') ERROR> $@${_NO_COLOR}" >&2 ;
}

function DIE() {
    if [ -t 2 ] ; then
        local _COLOR=$RED2
        local _NO_COLOR=$NO_COLOR2
    fi
    echo -e "${_COLOR}$(date +'%F %T') FATAL> $@${_NO_COLOR}" >&2 ;

    exit 1;
}

### for interactive shells only ################################################

[ -z "$PS1" ] && return

export PATH=~/bin:$PATH

export LANG="de_DE.UTF-8"
# export LC_ALL="de_DE.UTF-8"
# export LC_CTYPE="de_DE.UTF-8"

# use english messages on the command line
export LC_MESSAGES=C

function switch_to_iso() { export LANG=de_DE@euro ; }

export EDITOR=vi
alias vi="DISPLAY= vi"

# only load users vimrc
export MYVIMRC=~/.vimrc

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# case insensitive tab completion
bind 'set completion-ignore-case on'

# case insensitive pathname expansion
shopt -s nocaseglob

# turn off beeping
bind 'set bell-style none'
# xset b off

# remove domain from hostname if necessary
HOSTNAME=${HOSTNAME%%.*}

if [[ $OSTYPE =~ linux ]] ; then
    alias ls='ls --time-style=+"%F %H:%M" --color=auto'
fi

alias cp="cp -i"
alias mv="mv -i"
alias less="less -i"
alias crontab="crontab -i"

alias j="jobs"
alias l="ls -lh"
alias lr="ls -rtlh"
alias lc="ls -rtlhc"
alias xargs="xargs -I {}"

if [[ $(type -p tree) ]] ; then
    alias t="tree --noreport --dirsfirst"
else
    alias t="find | sort"
fi

alias remove_comments="perl -ne 'print if ! /^#/ && ! /^$/'"

# make less more friendly for non-text input files, see lesspipe(1)
if [ -x /usr/bin/lesspipe ] ; then
    eval "$(lesspipe)"
fi

if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# nice calculator
function calc(){
    echo "$@"|bc -l;
}

# absolute path
function abs() {
    if [ ! "$@" ] ; then
        echo $(readlink -m .)/
        return
    fi

    if [ -d "$@" ] ; then
        echo $(readlink -m "$@")/
    else
        readlink -m "$@"
    fi
}

# ssh url of a file or directory
function url() {
    echo $USER@$HOSTNAME:$(abs $1)
}

# clear screen also create distance to last command for easy viewing
function v() {

    local i=0
    while [ $i -le 80 ] ; do
        i=$(($i + 1))
        echo
    done 

    clear

    i=1
    while [ $i -le 8 ] ; do
        i=$(($i + 1))
        echo -n "----------"
    done 
    echo
}

if [[ $(type -p pstree) ]] ; then
    alias pstree="pstree -A"
    alias p="pstree -ap | grep -v "{" | less -S"
else
    alias pstree="ps axjf"
fi

# translate a word
function tl() {
    links -dump "http://dict.leo.org/ende?lang=de&search=$@" \
        | perl -ne 'print "$1\n" if /^\s*\|(.+)\|\s*$/' \
        | tac;
}

function find_older_than_days() {
    find . -type f -ctime +$@
}

alias find_last_changes='find -type f -printf "%CF %CH:%CM %h/%f\n" | sort'
alias find_largest_files='find -type f -mount -printf "%k %p\n" | sort -rg | cut -d \  -f 2- | xargs -I {} du -sh {} | less'

# toplike output for a search in ps
function running() { watch -n1 "ps -A | grep -i $@ | grep -v grep"; } 

# disable XON/XOFF flow control (^s/^q)
# stty -ixon

export GREP_OPTIONS="--color=auto"
alias listgrep="grep -xFf"

if [ -r ~/.bashrc_local ] ; then
    source ~/.bashrc_local
fi

if [[ ! $JAVA_HOME ]] ; then
    export JAVA_HOME=/usr/lib/jvm/java-6-sun
fi

function _check_env() {
    echo "SHELL" $(echo $SHELL)
    echo "PATH"  $(echo $PATH)
    echo "PERL5LIB"  $(echo $PERL5LIB)
    cat /proc/version
    uname -a
    cat /etc/issue.net
}

function updatebashrc() {
    wget -qO ~/.bashrc http://github.com/evenless/bashrc/raw/master/.bashrc
    reloadbashrc
}

function reloadbashrc() {

    # remove aliases
    unalias -a

    # remove functions
    while read funct ; do
        unset $funct
    done<<EOF
        $(perl -ne 'foreach (/^function (.+?)\(/) {print "$_\n" }' ~/.bashrc)
EOF

    . ~/.bashrc
}

# alias quote="fmt -s | perl -pe 's/^/> /g'"

function timestamp2date() {
    local timestamp=$1
    perl -MPOSIX -e 'print strftime("%F %T", localtime('$timestamp')) . "\n"'
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

    if [[ $(type -p xmodmap) ]] ; then

        # disable caps lock
        xmodmap -e "remove lock = Caps_Lock"

        # let caps lock behave like shift
        xmodmap -e "add shift = Caps_Lock"
    fi

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
fi

### mysql ######################################################################

# unset mysql function
unset mysql

# mysql prompt
export MYSQL_PS1="\\u@\\h:\\d db> "

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

# for cpan
export FTP_PASSIVE=1

# less questions from cpan
export PERL_MM_USE_DEFAULT=1

# testing
alias prove="prove -lv --merge"

# find a lib via PERL5LIB
function pmpath() {

     perl - $@ <<'EOF'
        use strict;
        use warnings;
        my $module = $ARGV[0] or die q{specify module.};
        eval qq{require $module};
        $module =~ s{::}{/}g;
        $module =~ s/$/.pm/g;
        print $INC{$module} || exit 1;
EOF
}

# edit a lib via PERL5LIB
function vii() {
    if ! [ `pmpath $1` ] ; then
        echo "not found: $1"
        return 1
    fi

    local file=$(pmpath $1)

    vi $file
}

### history ####################################################################

# ignore commands  for history that start  with a space
HISTCONTROL=ignorespace:ignoredups
HISTIGNORE="truecrypt*"
# HISTIGNORE="truecrypt*:blubb*"
# HISTTIMEFORMAT="[ %Y-%m-%d %H:%M:%S ] "

# Make Bash append rather than overwrite the history on disk
shopt -s histappend

# prevent history truncation
unset HISTFILESIZE

### eternal history

_bashrc_eternal_history_file=~/.bash_eternal_history

if [ "$REMOTE_USER" != "" ] ; then
    _bashrc_eternal_history_file=~/.bash_eternal_history_$REMOTE_USER
fi

if [ ! -e $_bashrc_eternal_history_file ] ; then
    touch $_bashrc_eternal_history_file
    chmod 0600 $_bashrc_eternal_history_file
fi

function _add_to_history() {

    # prevent historizing last command of last session on new shells
    if [ $_first_invoke != 0 ] ; then
        _first_invoke=0
        return
    fi

    # remove history position (by splitting)
    local history=$(history 1)

    [[ $_last_history = $history ]] && return;

    read -r pos cmd <<< $history

    local quoted_pwd=${PWD//\"/\\\"}

    # update cleanup_eternal_history if changed:
    local line="$USER"
    line="$line $(date +'%F %T')"
    line="$line $BASHPID"
    line="$line \"$quoted_pwd\""
    line="$line \"$last_return_values\""
    line="$line $cmd"
    echo "$line" >> $_bashrc_eternal_history_file

    _last_history=$history

    history -a
}

function h() {

    if [ "$*" = "" ] ; then
        tail -100 $_bashrc_eternal_history_file
        return
    fi

    grep -i "$*" $_bashrc_eternal_history_file | tail -100
}

### network ####################################################################

function get_natted_ip() {
    wget http://checkip.dyndns.org/ -q -O - \
        | grep -Eo '\<[[:digit:]]{1,3}(\.[[:digit:]]{1,3}){3}\>'
}

function _set_remote_host() {

    if [[ $_checked_for_remote_host != "" ]] ; then
        return
    fi

    local ip_line

    ip_line=$(who am i)

    REMOTE_HOST=$(echo $ip_line | perl -ne '$_ =~ /\(([^\:]+)\)/ && print $1')

    _checked_for_remote_host=1
}

### .bashrc_identify_user_stuff

function set_remote_user_from_ssh_key() {

    if [[ $SSH_CONNECTION = "" ]] ; then
        return
    fi

    if [[ $(type -p ssh-add) = "" ]] ; then
        return
    fi

    local agent_key auth_key user_name auth_files

    if [[ -r ~/.ssh/authorized_keys ]] ; then
        auth_files="$HOME/.ssh/authorized_keys"
    fi

    if [[ -r ~/.ssh/authorized_keys2 ]] ; then
        auth_files="$auth_files $HOME/.ssh/authorized_keys2"
    fi

    if [[ $auth_files = "" ]] ; then
        echo "no authorizedkeys-files"
        return
    fi

    while read agent_key ; do

        agent_key=${agent_key%%=*}

        if [[ $agent_key = "" ]] ; then
            # echo "no agent key found"
            continue
        fi

        # echo ="grep -i \"${agent_key}\" $auth_files | tail -1"
        auth_key=$(grep -i "${agent_key}" $auth_files | tail -1)

        if [[ $auth_key != "" ]] ; then
            break
        fi

    done<<EOF
        $(ssh-add -L 2>/dev/null)
EOF

    if [[ $auth_key = "" ]] ; then
        return
    fi

    user_name=${auth_key#*= }
    user_name=${user_name%% *}

    if [[ $user_name = "" ]] ; then
        return
    fi

    if [ "$user_name" != $USER ] ; then
        export REMOTE_USER=$user_name
        export REMOTE_HOME=$HOME/$user_name
    fi
}

function load_remote_host_bash_rc() {

    if [[ $REMOTE_USER != "" ]] ; then
        return
    fi

    local remote_bash_rc

    set_remote_user_from_ssh_key

    if [[ $REMOTE_USER = "" ]] ; then
        return
    fi

    remote_bash_rc="$HOME/.bashrc_$REMOTE_USER"

    if [[ -e $remote_bash_rc ]] ; then
        source $remote_bash_rc
    fi
}

### END .bashrc_identify_user_stuff

function _export_identify_user_stuff() {

    perl -0777 -ne '/### \.bashrc_identify_user_stuff(.*?)###.*bashrc_identify_user_stuff/msg && print "$1\n"' $BASH_SOURCE \
    > $HOME/.bashrc_identify_user_stuff

    cat >> $HOME/.bashrc_identify_user_stuff <<EOF
load_remote_host_bash_rc 
unset set_remote_user_from_ssh_key
unset load_remote_host_bash_rc
EOF

    grep .bashrc_identify_user_stuff $HOME/.bashrc 2>&1 1>/dev/null \
        && return

    echo 'source ~/.bashrc_identify_user_stuff' \
        >> $HOME/.bashrc
}

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

function grabssh () {
    local SSHVARS="SSH_CLIENT SSH_TTY SSH_AUTH_SOCK SSH_CONNECTION DISPLAY"

    for x in ${SSHVARS} ; do
        (eval echo $x=\$$x) | sed  's/=/="/
                                    s/$/"/
                                    s/^/export /'
    done 1>$HOME/.ssh_agent_env
}

alias fixssh="source ~/.ssh_agent_env"
alias nosshagent="grabssh && unset SSH_AUTH_SOCK SSH_CLIENT SSH_CONNECTION SSH_TTY"

function _ssh_alias() {
    
    local IFS=$'\n'
    
    local cmd=$(perl - $@ <<'EOF'
        
        use strict;
        use warnings;
        
        my($host, $port, @files) = @ARGV;
        
        my $cmd = "ssh -p $port $host";
        
        if(@files == 1) {
            push(@files, "tmp/");
        }
        
        if(@files) {
            my $dst = pop(@files);
            my $src = join(" ", @files);
            $cmd = "scp -P $port $src $host:$dst";
        }

        print "$cmd";
EOF
)

    eval "$cmd"
}

# diff local file with remote file via ssh
svimdiff() {
    local file=$(abs $1)
    local host=$2

    if [ ! $file ] ; then
        echo specify file >&2
        return
    fi

    if [ ! $host ] ; then
        echo specify host >&2
        return
    fi

    vimdiff $file scp://$USER@$host/$file
}

function _sshputget() {
    local host=$1
    local file=$2
    local direction=$3

    if [ ! $host ] ; then
        echo specify host >&2
        return 1
    fi

    if [ ! $file ] ; then
        echo specify file >&2
        return 1
    fi

    file=$(abs $file)
    host=$USER@$host:$(abs $file)

    local src=$host
    local dst=$file

    if [ "$direction" = "put" ] ; then
        src=$file
        dst=$host
    fi

    # echo scp $src $dst
    scp $src $dst
}

function sshget() {
    _sshputget $1 $2 get
}

function sshput() {
    _sshputget $1 $2 put
}

### SCREEN #####################################################################

alias screen="xtitle screen@$HOSTNAME ; export DISPLAY=; screen"

function srd() {
    grabssh
    screen -rd $1 && clear
}

### PROMPT #####################################################################

function _set_colors() {

    # tput is supposed to be more platform independent
    # but is it always included?

    #disable any colors
    NO_COLOR="\[\033[0m\]"
    NO_COLOR2="\033[0m"

    BLACK="\[\033[0;30m\]"

    RED="\[\033[1;31m\]"
    RED2="\033[1;31m"

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

    if [ $length -gt $max_length ] ; then

        # local left_split=$(($max_length/2))
        # local right_split=$left_split

        local left_split=$(($max_length-4))
        local right_split=4

        local right_start=$(($length-$right_split))

        local left=${_pwd:0:$left_split}
        local right=${_pwd:$right_start:$length}

        # echo "$length - $split -> $max_length $left$right"

        # _xtitle_pwd=${_pwd:0:$max_length}"..."
        _pwd=$left${RED}"*"${NO_COLOR}$right
        _xtitle_pwd=$left"..."$right

        # _pwd=${_pwd:0:7}
        # _pwd=${_pwd:0:14}$RED">"$NO_COLOR

    else
        _xtitle_pwd=$_pwd
    fi
}

function _color_hostname () {
    echo $GREEN$HOSTNAME$NO_COLOR
}

function _track_time() {
    _track_now=$SECONDS

    if [ "$_track_then" = "" ] ; then
        _track_then=$_track_now
    fi

    echo $(($_track_now-$_track_then))
    # _then=$now # useless here!?!
}

function _humanize_secs() {

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

function _set_bg_jobs_count() {

    local job
    _bg_jobs_count=0
    _bg_jobs_running_count=0

    local IFS

    while read job ; do

        [ -z "$job" ] && continue

        _bg_jobs_count=$(($_bg_jobs_count+1))

    done<<EOF
        $(jobs)
EOF

    while read job ; do

        [ -z "$job" ] && continue

        _bg_jobs_running_count=$(($_bg_jobs_running_count+1))

    done<<EOF
        $(jobs -r)
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
    local _user=$USER
    if [[ $USER == "root" ]] ; then
        _user=${RED}$USER${NO_COLOR}
    fi
    echo $_user
}

function _print_on_error() {

    local last_return_values=${PIPESTATUS[*]}

    for item in ${last_return_values[*]} ; do

        if [ $item != 0 ] ; then
            echo -e ${RED2}exit: $last_return_values$NO_COLOR2 >&2
            break
        fi

    done
}

function _prompt_command() {

    _print_on_error
    local secs=$(_track_time)
    local time=$(_humanize_secs $secs)
    local hostname=$(_color_hostname)
    _fix_pwd
    _set_bg_jobs_count
    local user=$(_color_user)

    # $NO_COLOR first to reset color setting from other programs
   PS1=$GRAY"$time$NO_COLOR $user@$hostname:$_pwd${_bg_jobs_count}""$NO_COLOR> "
    xtitle $USER@$HOSTNAME:$_xtitle_pwd

    _add_to_history

    # has to be done here!?!
    _track_then=$SECONDS

    # TODO
    # $_PROMPT_WMCTRL
}

function _simple_prompt_command() {

    _print_on_error
    local secs=$(_track_time)
    local time=$(_humanize_secs $secs)
    _fix_pwd
    _set_bg_jobs_count

    PS1=$NO_COLOR"$GRAY$time$NO_COLOR $_pwd${_bg_jobs_count}""$NO_COLOR> "
    xtitle $USER@$HOSTNAME:$_xtitle_pwd

    _add_to_history

    # has to be done here!?!
    _track_then=$SECONDS
}

function _spare_prompt_command() {

    _print_on_error
    _fix_pwd
    _set_bg_jobs_count

    PS1=$NO_COLOR"$_pwd${_bg_jobs_count}""$NO_COLOR> "
    xtitle  $USER@$HOSTNAME:$_xtitle_pwd

    _add_to_history
}

function _prompt() {
    PROMPT_COMMAND=_prompt_command
}

function _simple_prompt() {
    PROMPT_COMMAND=_simple_prompt_command
}

function _spare_prompt() {
    PROMPT_COMMAND=_spare_prompt_command
}

unset PS1

case $(ps -p $PPID -o comm=) in
    sshd)
        _prompt
    ;;
    *)
        _original_user=$USER
        _simple_prompt
    ;;
esac

### STARTUP ####################################################################

function _init_bash() {
    _set_colors
    unset _set_colors

    set_remote_user_from_ssh_key
    load_remote_host_bash_rc

    if [[ "$REMOTE_USER" != "" ]] ; then

        if [[ -r $REMOTE_HOME/.vimrc ]] ; then
            export MYVIMRC=$REMOTE_HOME/.vimrc
        fi

        if [[ -r $REMOTE_HOME/.screenrc ]] ; then
            alias screen="screen -c $REMOTE_HOME/.screenrc"
        fi
    fi
}

_init_bash
unset _init_bash
unset _init_perl5lib

_first_invoke=1

### MISC #######################################################################

function _send_configs() {
    # $MYHOME/.bashrc
    # $MYHOME/.vimrc
    # $MYHOME/.vim/...
    # $MYHOME/.screenrc
    # $MYHOME/.id_rsa.pub
    # $MYHOME/.cpan_template_MyConfig.pm
echo
}

# run a previous command independent of the history
function r() {

    local CMD_FILE=~/.run_command

    local cmd=$@

    if [ "$cmd" = "" ] ; then
        if [ ! -e $CMD_FILE ] ; then
            echo "got no command to run" >&2
            return 1
        fi
    else
        cmd=$(echo $cmd | perl -pe 's#./#cd $ENV{PWD} && \./#g')
        echo "$cmd" > $CMD_FILE
    fi

    v

    bash -i $CMD_FILE
}

function parent() {
    echo $(ps -p $PPID -o comm=) "($PPID)"
}

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

# NOTES ON files
# * replace in files: replace

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
#    sudo checkinstall

# NOTES ON console
# * switch console: chvty
# * turn off console-blanking: echo -ne "\033[9;0]" > /dev/tty0
# * lock: ctrl+s / unlock: ctrl+q

# NOTES ON csv
# * join

# NOTES ON encoding
# * recode UTF-8..ISO-8859-1 file_name
# * convmv: filename encoding conversion tool
# * luit - Locale and ISO 2022 support for Unicode terminals
#      luit -encoding 'ISO 8859-15' ssh legacy_machine

# NOTES ON man and the like
# * apropos - search the manual page names and descriptions

# NOTES ON kill
# * to kill a long running job
#    ps -eafl |\
#       grep -i "dot \-Tsvg" |\ 
#       perl -ane '($h,$m,$s) = split /:/,$F[13];
#          if ($m > 30) { print "killing: " . $_; kill(9, $F[3]) };'

# NOTES ON networking
# * netstat -tapn
# * netstat -tulpn | grep 25
# * fuser
# * lsof -i -n

# NOTES ON recovery
# * recover removed but still open file
#   lsof | grep -i "$file"
#   cp /proc/$pid/fd/$fd $new_file
#   (fd = file descriptor)
# * recover partition: ddrescue
# * recover deleted files: foremost jpg -o out_dir -i image_file

# NOTES ON sort
# * sort by numeric column: sort -u -t, -k 1 -n file.csv > sort
# * comm - compare two sorted files line by line with 3 column output

# NOTES ON sql / mysql
# * INSERT
#    * REPLACE INTO x ( f1, f2 ) SELECT ... - replaces on duplicate key
#    * INSERT IGNORE INTO ... - skips insert on duplicate key
# * default-storage-engine = innodb
# * mysql full join: left join union right join
# * split: SUBSTRING_INDEX(realaccount,'@',-1)

# NOTES ON sftp
# * use specifc key file
#     sftp -o IdentityFile=~/.ssh/$keyfile $user@$host

# NOTES ON user management
# * newgrp - log in to a new group
# * sg - execute command as different group ID

# NOTES ON vnc
# ssh -v -L 5900:localhost:59[display] -p sshport sshgateway
# export VNC_VIA_CMD='/usr/bin/ssh -x -p port -l user -f -L %L:%H:%R %G sleep 20'
# xtightvncviewer -via ssh-host -encodings tight -fullscreen localhost:0

# NOTES ON ubuntu
# * Releases:
#      4.10       Warty Warthog     2004-10-20
#      5.04       Hoary Hedgehog    2005-04-08
#      5.10       Breezy Badger     2005-10-13
#      6.06 LTS   Dapper Drake      2006-06-01
#      6.10       Edgy Eft          2006-10-26
#      7.04       Feisty Fawn       2007-04-19
#      7.10       Gutsy Gibbon      2007-10-18
#      8.04 LTS   Hardy Heron       2008-04-24
#      8.10       Intrepid Ibex     2008-10-30
#      9.04       Jaunty Jackalope  2009-04-23
#      9.10       Karmic Koala      2009-10-29
#     10.04 LTS   Lucid Lynx        2010-04-29
#     10.10       Maverick Meerkat  2010-10-28

# NOTES ON vim
# * :help quickref
# * :help quickfix

# NOTES ON x
# * ssh -X host x2x -west -to :4.0

# NOTES ON init
# * sudo update-rc.d vncserver defaults 
# * sudo update-rc.d -f vncserver remove

### NOTE #######################################################################

# display notes defined inside the bashrc
function note() {

    local search=$1

    if [[ ! $search ]] ; then
        perl -ne 'print " * $1\n" if /^# NOTES ON (.*)/' \
            $BASH_SOURCE | sort
        return
    fi
    
    perl -0777 -ne \
      'foreach(/^(# NOTES ON '$search'.*?\n\n)/imsg){ s/# //g; print "\n$_" }' \
        $BASH_SOURCE
}

### THEN END ###################################################################
