### for all shells #############################################################

if [[ ! $_is_reload ]] ; then

    PATH=~/bin:~/opt/bin:$PATH
    PERL5LIB=~/perldev/lib

    if [[ -e ~/perl5/perlbrew/etc/bashrc ]] ; then
        source ~/perl5/perlbrew/etc/bashrc
    else
        PATH=$PATH:~/perl5/bin
        PERL5LIB=$PERL5LIB:~/perl5/lib/perl5
    fi

    export PERL5LIB
    export PATH
fi

if [[ ! $JAVA_HOME ]] ; then
    export JAVA_HOME=/usr/lib/jvm/java-6-sun
fi

## helper functions ############################################################

function _LOG() {

    local level=$1 ; shift

    local crap
    read log_level_prio crap <<<$(_calc_prio $LOG_LEVEL)
    if [[ ! $LOG_LEVEL ]] ; then
        if [[ -t 1 ]] ; then
            log_level_prio=3
        else
            log_level_prio=6
        fi
    fi

    local message_prio
    local prio
    local location
    local color

    read message_prio show_location color <<<$(_calc_prio $level)

    if [[ $message_prio < $log_level_prio ]] ; then
        return
    fi

    if [[ $show_location ]] ; then

        read line function file <<<$(caller 1)
        local location=$line

        if [[ $file ]] ; then
            location=$(basename $file)":"$location
        fi

        if [[ $location ]] ; then
            location=" "$location
        fi
    fi

    if [ -t 1 ] ; then
        echo "$color${level}$location> $@${NO_COLOR}" >&1
    else
        echo "$(date +'%F %T') ${level}$location> $@" >&1
    fi
}

function _calc_prio() {
    local level=$1

    case $level in
        TRACE) prio=1 ; show_location=1 ; color=$GRAY ;;
        DEBUG) prio=2 ; show_location=0 ; color=$GRAY ;;
        INFO)  prio=3 ; show_location=0 ; color=$GREEN ;;
        WARN)  prio=4 ; show_location=0 ; color=$ORANGE ;;
        ERROR) prio=5 ; show_location=1 ; color=$RED ;;
        FATAL) prio=6 ; show_location=1 ; color=$RED ;;
    esac

    echo $prio $show_location $color
}

function TRACE() { _LOG "TRACE" "$@" ; }
function DEBUG() { _LOG "DEBUG" "$@" ; }
function INFO()  { _LOG "INFO " "$@" ; }
function WARN()  { _LOG "WARN " "$@" ; }
function ERROR() { _LOG "ERROR" "$@" ; }
function DIE()   { _LOG "FATAL" "$@" ; exit 1 ; }

function usefatal() {
    trap DIE err
}

# does not work :(
function nousefatal() {
    trap '' err
}

[ -z "$PS1" ] && return

################################################################################
### for interactive shells only ################################################
################################################################################

[[ $REMOTE_USER   ]] || export REMOTE_USER=$USER
[[ $REMOTE_HOME   ]] || export REMOTE_HOME=$HOME
[[ $REMOTE_BASHRC ]] || export REMOTE_BASHRC="$REMOTE_HOME/.bashrc"
[[ $REMOTE_HOST   ]] || export REMOTE_HOST=${SSH_CLIENT%% *}

if [[ ! $_is_reload && $REMOTE_HOME != $HOME ]] ; then
    export PATH=$REMOTE_HOME/bin:$PATH
fi

### setup functions from scripts at the end of this file #######################

function _dump_perl_app() {(
    local function=${1?Specify function}
    shift

    perl -0777 -ne \
        'print $1 . "exit 0;" if /(^### function '$function'\(\).*?)\n### /igsm' \
        $REMOTE_BASHRC
)}

# run a perl app located at the end of this file
function _run_perl_app() {(
    local function=${1?Specify function}
    shift

    code=$(_dump_perl_app $function)

    export code
    perl -we 'eval $ENV{code} || die $@;' -- "$@"
)}

# setup aliases for all the perl apps at the end of this file
function _setup_perl_apps() {

    while read funct ; do
        eval "function $funct() { ( set +e ; _run_perl_app $funct \"\$@\" ; ) }"
    done<<EOF
        $(perl -ne 'foreach (/^### function (.+?)\(/) {print "$_\n" }' \
            $REMOTE_BASHRC)
EOF
}

_setup_perl_apps

################################################################################

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

### keyboard shortcuts #########################################################

# ctrl-l clear screen but stay in current row
bind -x '"\C-l":printf "\33[2J"'

if [[ $DISPLAY ]] ; then
    # swap caps lock with escape
    xmodmap -e 'clear Lock' -e 'keycode 0x42 = Escape'
fi

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
export LESS="-j.5 -inRgS"
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

alias lsop='netstat -tapnu | less -S'

function df() {

    if [[ $@ ]] ; then
        command df "$@"
        return
    fi

    command df -h | perl -0777 -pe 's/^(\S+)\n/$1/gm' | csvview
}

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

# recursively find a file and open it in vim
function vif() {

    local search=$(perl -e '$_ = "'"$@"'" ; s#\:\:#/#g; print')

    local entry=$(f "$search" | head -1)

    if [[ ! "$entry" ]] ; then
        return 1
    fi

    command vi "$entry"
}

# edit perl modul that is located within perls module path
function vip() {
    perl -M$1 -e \
        '$_ = "'$1'"; eval "use $_"; s/::/\//g; s/$/.pm/g; print $INC{$_};'
}

alias greppath="compgen -c | grep -i"

alias xargs='xargs -I {} -d \\n'

alias apts="apt-cache search"
alias aptw="apt-cache show"
alias apti="sudo apt-get install"
alias aptp="sudo dpkg -P"
alias aptc="sudo apt-get autoremove"

function  t() { simpletree "$@" | less ; }
function td() { simpletree -d "$@" | less ; }
function ts() { simpletree -sc "$@" | less ; }
function diffdir() {
    diff <(cd "$1" && find | sort) <(cd "$2" && find | sort)
}

# make less more friendly for non-text input files, see lesspipe(1)
if [[ $(type -p lesspipe ) ]] ; then
    eval "$(lesspipe)"
fi

# setup remote desktop access via ssh and vnc right
# from the login screen of lightdm
function vnc-server-setup-upstart-script {(

    set -e

    sudo apt-get install x11vnc

    sudo tee /etc/init/lightdm-vnc.conf >/dev/null <<'EOF'
# to reload: sudo initctl emit login-session-start
start on login-session-start
script
set +e
killall -9 x11vnc
set -e
/usr/bin/x11vnc \
    -norc \
    -localhost \
    -forever \
    -solid \
    -nopw \
    -nocursor \
    -wireframe \
    -wirecopyrect \
    -xkb \
    -auth /var/run/lightdm/root/:0 \
    -noxrecord \
    -noxfixes \
    -noxdamage \
    -rfbport 5900 \
    -scale 3/4:nb \
    -o /var/log/lightdm-vnc.log \
    -bg
end script
EOF

    sudo tee -a /etc/lightdm/lightdm.conf >/dev/null <<-'EOF'

[VNCServer]
enabled=true
EOF

    sudo initctl reload-configuration
    sudo initctl emit login-session-start

    echo "check if vino is running!"
)}

function vncviewer() {
    local host=$1
    export VNC_VIA_CMD="/usr/bin/ssh -C -f -L %L:%H:%R %G sleep 20"
    $(type -pf vncviewer) -encoding tight \
        -compresslevel 9 -quality 5 -x11cursor -via $host localhost:0
}

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

### functions ##################################################################

function SHOW()  {
    local var=$1
    shift
    echo "$GREEN$var$NO_COLOR: $@"
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

# get parent process id
function parent() {
    echo $(ps -p $PPID -o comm=)
}

## file handling functions #####################################################

# absolute path
function abs() {

    perl - "$@" <<''
        use Cwd;
        my $file = $ARGV[0] || ".";
        my $abs = Cwd::abs_path($file);
        $abs .= "/" if -d $file;
        $abs = "'$abs'" if $abs =~ /\s/;
        $abs =~ s/;/\\;/g;
        print "$abs\n";

}

# relative path
function rel() {
    abs "$@" | perl -pe "s#^('|)($HOME/)#\$1#g"
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
        ff | while read i; do _andgrep -pf "$i" "$@" ; done
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

    local search=${@-$PPID}

    pstree -apl \
        | perl -ne '$x = "xxSKIPme"; print if $_ !~ /[\|`]\-\{[\w-_]+},\d+$|less.+\+\/'$1'|$x/' \
        | less "+/$search"
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
    wcat http://github.com/evenless/etc/raw/master/$1 -fr
)}

function bashrc_clean_environment() {

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

function __dump_function() {

    local funct=${1?specify function name}

    echo "export LINES COLUMNS"
    echo
    echo -n "### "
    type $funct
    echo
}

function _dump_function() {
    local function=${1?specify function name}
    local file=$2

    local perl_app=$(_dump_perl_app $function)

    if [[ $perl_app ]] ; then
        echo 'REMOTE_BASHRC=$0'
        __dump_function _dump_perl_app
        __dump_function _run_perl_app
    fi

    __dump_function $function

    echo $function '"$@"'

    if [[ $perl_app ]] ; then
        echo
        echo "exit 0"
        echo
        _dump_perl_app $function
        echo "### end"
    fi
}

function _dump_function_to_file() {
    local function=${1?specify function name}
    local file=$function

    local note="# automatic bashrc export - do not edit"
    local is_export=

    if [ -e $function ] ; then
        grep -q "$note" $function && is_export=1

        if ! [ $is_export ] ; then
            WARN "skipping - file exists: $function"
            continue
        fi
    fi

    # bash interactive mode to export LINES and COLUMNS vars
    echo '#!/bin/bash -i'       > $file
    echo "$note"               >> $file
    _dump_function $function >> $file

    chmod +x $file
}

function _dump_functions_to_files() {

    while read function ; do

    _dump_function_to_file $function

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

    _dump_function $funct \
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
alias sshnocheck="ssh -q -o CheckHostIP=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

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

    HOSTNAME=$HOSTNAME perl - "$(rel $@)" <<''
        my $rel = "@ARGV";
        $rel = "\"$rel\"" if $rel =~ /\s|;/;
        print "$ENV{USER}\@$ENV{HOSTNAME}:$rel\n"

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

    local h=$(perl -e '"'"$*"'" =~ /[-]+h(?:ost)*\ ([^ \\.]+)/ && print $1')

    if [[ ! $h || $h = localhost ]] ; then
        h=$HOSTNAME
    fi

    xtitle "mysql@$h" && MYSQL_PS1="\\u@${GREEN}$h${NO_COLOR}:${RED}\\d db${NO_COLOR}> " \
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

function perl-module-version() {(
    set -e
    perl-is-module-installed
    perl -M"$@" -e 'print $ARGV[0]->VERSION' "$@"
)}

function perl-is-module-installed() {
    perl -M"$@" -e "1;" 2>/dev/null
}

function proxyserver() {(
    set -e
    local mod="HTTP::Proxy"

    if ! perl-is-module-installed $mod ; then
        echo "Installing $mod..."
        cpanm $mod
    fi

    local PORT=${1:-8080}
    echo "Starting proxy server on port $PORT..."
    PORT=$PORT \
    perl -MHTTP::Proxy -e 'HTTP::Proxy->new(port => $ENV{PORT})->start'
)}

function proxy-setup-environment() {
    local PORT=${1:-8080}

    for proto in http https ftp ; do
        export ${proto}_proxy=$proto://localhost:$PORT/
    done
}

function cpanm-reinstall-local-modules() {(
    set -e
    cpanm -nq App::cpanoutdated
    cpan-outdated | cpanm -nq --reinstall
)}

function cpan-list-changes() {(
    set -e
    type -f cpan-listchanges 2>&1>/dev/null || (
        cpanm -nq cpan-listchanges
    )

    command cpan-listchanges "$@"
)}

function perl-one-liners() {
    wcat http://www.catonmat.net/download/perl1line.txt | less +/"$@"
}

# search for a perl module or script
function pm() {
    find $(perl -e 'print join (" ", @INC)') -iname '*.p[ml]' 2>/dev/null \
        | grep -v thread \
        | sort -u \
        | g "$@"
}

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

# setup local::lib and cpanm
function setupcpanm() { (

    set -e

    if [ -e ~/.cpan ] ; then
        mv -v ~/.cpan ~/.cpan.$(date +%Y%m%d_%H%M%S)
    fi

    cd ~/bin
    wcat http://xrl.us/cpanm -fr
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
#     11.10       Oneiric Ocelot    2011-10-13   2013-04
#     12.04       Precise Pangolin  2012-04-26   2017-04
#     12.10       Quantal Quetzal   2012-10-18   2014-04

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

alias h="historysearch -e -s"

# uniq replacement without the need of sorted input
function uniqunsorted() {
    perl -ne 'print $_ if ! exists $seen{$_} ; $seen{$_} = 1'
}

### PROMPT #####################################################################

# some default colors
function _set_colors() {
    NO_COLOR=$(echo -e "\x1b[33;0;m")
    GRAY=$(echo -e "\x1b[38;5;243m")
    GREEN=$(echo -e "\x1b[38;5;2m")
    ORANGE=$(echo -e "\x1b[38;5;3m")
    RED=$(echo -e "\x1b[38;5;9m")
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

        _pwd="$left\[${RED}\]"*"\[${NO_COLOR}\]$right"
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
            _bg_jobs_count="\[${RED}\]$_bg_jobs_count\[${NO_COLOR}\]"
        fi

        _bg_jobs_count=" "$_bg_jobs_count
    fi
}

function _color_user() {

    if [[ $USER == "root" ]] ; then
        echo "\[${RED}\]$USER\[${NO_COLOR}\]"
    else
        echo $USER
    fi
}

# print error code of last command on failure
function _print_on_error() {

    for item in ${bashrc_last_return_values[*]} ; do

        if [ $item != 0 ] ; then
            echo "${RED}exit: $bashrc_last_return_values$NO_COLOR" >&2
            break
        fi

    done
}

function _prompt_command_default() {

    bashrc_last_return_values=${PIPESTATUS[*]}

    _print_on_error
    local secs=$(_track_time)
    local time=$(humanize_secs $secs)
    local hostname=$(_color_user)"@\[$GREEN\]$HOSTNAME\[$NO_COLOR\]"
    _fix_pwd
    _set_bg_jobs_count

    PS1="\[$GRAY\]$time\[$NO_COLOR\] $hostname:$_pwd${_bg_jobs_count}>\[$BASHRC_BG_COLOR\] "
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
        if_root="\[$RED\]root\[$NO_COLOR\] "
    fi

    PS1="\[${GRAY}\]${time}\[$NO_COLOR\] ${if_root}${_pwd}${_bg_jobs_count}>\[$BASHRC_BG_COLOR\] "
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

    PS1="\[$NO_COLOR\]$_pwd${_bg_jobs_count}>\[$BASHRC_BG_COLOR\] "
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

if [ -d $REMOTE_HOME/.bashrc.d ] ; then
    for rc in $(ls $REMOTE_HOME/.bashrc.d/* 2>/dev/null) ; do
        source $rc
    done
fi

### perl functions #############################################################

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

use warnings;
no warnings qw{uninitialized};
use Data::Dumper;

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

    my @special_chars = $sample =~ /([^\w"])/g;
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

use strict;
use warnings;
no warnings 'uninitialized';
use Data::Dumper;

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

        $cmds{$jid}[1] = $arg || $org_arg;
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

use strict;
use warnings;
use Data::Dumper;

use File::Basename;
use File::Copy qw(mv);
use File::stat;

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

    # system("mv", $was, $will) && die $!;
    my $stat = stat($was) || die $!;
    mv($was, $will) || die $!;
    utime($stat->atime, $stat->mtime, $will) || die $!;
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

use strict;
use warnings;
use Data::Dumper;

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

### function _andgrep() ############################################################

use strict;
use warnings;
use Data::Dumper;

use Getopt::Long;
Getopt::Long::Configure("bundling");

my $red      = "\x1b[38;5;124m";
my $no_color = "\x1b[33;0m";

if (! -t STDOUT) {
    $red = $no_color = "";
}

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
        if ( !s/(\Q$pattern\E)/$red$1$no_color/gi ) {
            next LINE;
        }
    }

    if($prefix) {
        print "$file:$.:$_";
    } else {
        print;
    }
}

### function replace() #########################################################

use strict;
use warnings;
no warnings 'uninitialized';
use Data::Dumper;

use Getopt::Long;

my $red = "\x1b[38;5;124m";
my $dry = 1;

my $opts = {
    "e|eval=s"  => \my $op,
    "x|execute" => sub { $dry = 0 },
};
GetOptions(%$opts) || usage();
$op || usage();

sub usage { die "Usage:\n" . join( "\n", sort keys %$opts ) . "\n"; }

my $file_count;
my $files_changed = 0;
my $example_file;

while (<STDIN>) {

    $file_count++;

    local $/ = undef;

    chomp;
    my $file = $_;
    $file =~ s/\n//g;

    open(F, $file) || die $!;
    my $data = <F>;
    close(F);

    $_ = $data;

    eval $op;
    die $@ if $@;

    next if $_ eq $data;

    $files_changed++;
    $example_file = $file;

    next if $dry;

    $data = $_;

    open(F, ">", $file) || die $!;
    print F $data;
    close(F);
}

exit 1 if ! $files_changed;

print STDERR "$files_changed of $file_count files changed"
    . " (example: $example_file)"
    . ($dry? "$red - dry run." : "") . "\n";

### function wcat() ############################################################

use strict;
use warnings;
no warnings 'uninitialized';
use Data::Dumper;
use File::Copy;
use Getopt::Long;
Getopt::Long::Configure("bundling");

my $opts = {
    "h|only-show-response-headers" => \my $show_headers,
    "s|strip-tags"   => \my $strip_tags,
    "f|save-to-file" => \my $to_file,
    "r|replace"      => \my $overwrite,
    "o|out-file=s"   => \my $file,
};
GetOptions(%$opts) or die "Usage:\n" . join( "\n", sort keys %$opts ) . "\n";

my $url = $ARGV[0] || die "Specify URL.";

if ( $url !~ m#^(.+?)://# ) {
    $url = "http://$url";
}

if($to_file) {
    if(! $file) {
        ($file) = $url =~ m#^.+?://.*?/([^\/]+)$#
    }
    die "Error creating file name from url." if ! $file;
    die "File exists: $file" if -f $file && ! $overwrite;
}

my $options = "--no-check-certificate ";
if ($show_headers) {
    $options .= "-S ";
}

my $content = `wget $options -qqO- "$url"` || die "Request failed. $!";

exit 0 if $show_headers;

die "Empty response from $url." if ! $content;

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

if($to_file || $file) {
    my $tmp_file = "/tmp/wcat.$$.$file";
    open(F, ">", $tmp_file) || die "Cannot write to file: $tmp_file: $!";
    print F $content;
    close(F);
    move($tmp_file, $file) || die "Cannot move to file $file: $!";
} else {
    print $content;
}

### function historysearch() ###################################################

use strict;
use warnings;
no warnings 'uninitialized';
use Data::Dumper;
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

### function aptpop() ##########################################################
# search for a debian package, sort by ranking, add description

use strict;
use warnings;
no warnings 'uninitialized';
use Data::Dumper;
use autodie;

my %apps = ();
open( F, qq{apt-cache search "@{[ join(" ", @ARGV) ]}" |} );
while (<F>) {
    my ( $app, $desc ) = /^(.+?) - (.+)$/;
    next if $app =~ /^lib/;
    $apps{$app}{exists} = 1;
}

my %ranks = ();

open( F, qq{wget -qqO- http://popcon.debian.org/by_inst.gz | gunzip |} );
while (<F>) {
    my ( $rank, $app ) = /^(\d+)\s+(\S+)/;

    next if $app =~ /^lib/;

    next if !$app;
    next if !exists $apps{$app};

    $apps{$app}{ranked} = 1;
    $ranks{$rank} = { app => $app };
}

# add apps without a ranking
my $i = 0;
foreach my $app ( keys %apps ) {
    $i++;
    $ranks{"_$i"} = { app => $app }
        if !exists $apps{$app}{ranked};
}

print "\n";

foreach my $rank ( sort { $a <=> $b } keys %ranks ) {
    my $app = $ranks{$rank}{app};
    my ($desc) = `apt-cache show $app` =~ /^Description.*?\:(.+?)\n\S/igsm;
    my $header = "### $app " . ("#" x ($ENV{COLUMNS} - length($app) - 5));
    print "$header\n\n$desc\n\n";
}

### END ########################################################################
