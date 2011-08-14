### for all shells #############################################################

if [[ ! $_first_invoke ]] ; then
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

if [[ ! $_first_invoke && $REMOTE_HOME != $HOME ]] ; then
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

### input config ###############################################################

export INPUTRC=$REMOTE_HOME/.inputrc

# set vi edit mode
bind 'set editing-mode vi'

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

# add slash to symlinks to directoryies on tab completion
bind 'set mark-symlinked-directories on'

# skip directories starting with a dot from tab completion
bind 'set match-hidden-files off'

# keep original version of edited history entries
bind 'set revert-all-at-newline on'

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

# edit shell commands in vi with Ctrl-x Ctrl-e
export VISUAL=$EDITOR

alias cp="cp -i"
alias mv="mv -i"
alias less="less -in"
alias crontab="crontab -i"

alias ls='ls --color=auto --time-style=+"%F %H:%M" '
alias  l='ls -lh'
alias lr='ls -rtlh'
alias lc='ls -rtlhc'

alias cdh='cd $REMOTE_HOME'
alias cdt='cd $REMOTE_HOME/tmp'

# search history for an existing directory containing string and go there
function cdl() {
    local dir=$(h d a | perl -ne 's/\n//g; print "$_\n" if /'$1'/i && -d' | head -1)

    if [[ ! "$dir" ]] ; then
        return 1
    fi

    cd "$dir"
}

alias greppath="compgen -c | grep -i "

alias xargs="xargs -I {}"

alias apts="apt-cache search"
alias aptw="apt-cache show"
alias apti="sudo apt-get install"
alias aptp="sudo dpkg -P"
alias aptc="sudo apt-get autoremove"
alias  t=simpletree
alias td="simpletree -d"

# make less more friendly for non-text input files, see lesspipe(1)
if [[ $(type -p lesspipe ) ]] ; then
    eval "$(lesspipe)"
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

function showenv() {

    while read v ; do
        SHOW $v ${!v}
    done<<EOF
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

    local CMD_FILE=~/.run_command

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

function filltemplate {

    perl - $@ <<'EOF'

        use strict;
        use warnings;
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
EOF

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
        use Cwd 'abs_path';

        my $file = $ARGV[0] || ".";

        $file = abs_path($file);

        $file .= "/" if -d $file;
        $file =~ s/(["`\\\$ ])/\\$1/g;

        print "$file\n";
EOF

}

function find_older_than_days() {
    find . -type f -ctime +$@
}

alias find_last_changes='find -type f -printf "%CF %CH:%CM %h/%f\n" | sort'

function find_largest_files() {
    find . -mount -type f -printf "%k %p\n" \
        | sort -rg \
        | cut -d \  -f 2- \
        | xargs -I {} du -sh {} \
        | less
}

export GREP_OPTIONS="--color=auto"
alias listgrep="grep -xFf"

# a simple grep without the need for quoting or excluding dot files
alias g="set -f && _g"
function _g() { (

    if [[ ! $@ ]] ; then
        DIE "usage: g [search term]"
    fi

    trap "exit 1" SIGINT

    grep -rsin --exclude-dir=.[a-zA-Z0-9]* --exclude=.* "$@" .
)

    local exit_code=$?
    set +f
    return $exit_code
}

# a simple grep files matching pattern without the need for quoting or
# excluding dot files
alias gi="set -f && _gi"
function _gi() { (

    if [[ $# < 2 ]] ; then
        DIE "usage: gi [filename pattern] [search term]"
    fi

    trap "exit 1" SIGINT

    grep -rsin --exclude-dir=.[a-zA-Z0-9]* --exclude=.* --include="$@" .
)

    local exit_code=$?
    set +f
    return $exit_code
}

# quick find a file matching a pattern
function f() { (

    if [[ ! $@ ]] ; then
        DIE "usage: f [filename pattern]"
    fi

    find . \! -regex ".*\/\..*" -iname "*$@*" | grep -i "$@"
) }

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

function p() {

    local args

    if [[ $@ ]] ; then
        args=" +/$@"
    fi

    pstree -aphl \
        | perl -ne '$x = "# xxSKIPme"; print if $_ !~ /\{|less.+\+\/'$1'|$x/' \
        | less -R $args
}

function pswatch() { watch -n1 "ps -A | grep -i $@ | grep -v grep"; }

function j() {

export _bashrc_jobs=$(jobs)
export _bashrc_columns=$COLUMNS

perl <<'EOF'

use strict;
use warnings;
no warnings 'uninitialized';

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
EOF
}

### functions for lookups ######################################################

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

function cmdfu() {
    curl "http://www.commandlinefu.com/commands/matching/$@/$(echo -n $@ | openssl base64)/plaintext" \
        | less -F
}

# query wikipedia via dns
function wp() {
    dig +short txt "$*".wp.dg.cx | perl -0777 -pe 'exit 1 if ! $_ ; s/\\//g'
}

# quick command help lookup
function m() {

    local cmd=$1
    local arg=$2

    if [[ $arg =~ ^- ]] ; then
       arg="   "$arg
    elif [[ ! $arg ]] ; then
        arg='^$'
    fi

    (
        help -m $cmd && return
        MAN_KEEP_FORMATTING=1 man -a $cmd && return

        if [[ $(type -p $cmd) ]] ; then
            $cmd --help 2>&1 \
                | perl -0777 -pe 'exit 1 if /^$/' && return
            $cmd -h 2>&1 \
                | perl -0777 -pe 'exit 1 if /^$/' && return
        fi


        links -dump http://man.cx/$cmd \
            | perl -0777 -pe 's/^.*\n(?=\s*NAME\s*$)|\n\s*COMMENTS.*$//smg' \
            | perl -0777 -pe 'exit 1 if /Sorry, I don.t have this manpage/' \
            && return

        aptw $cmd

    ) 2>/dev/null | less -F +/"$arg"
}

# translate a word
function tl() {
    links -dump "http://dict.leo.org/ende?lang=de&search=$@" \
        | perl -ne 'print "$1\n" if /^\s*\|(.+)\|\s*$/' \
        | tac;
}

### network functions ##########################################################

function publicip() {
    caturl http://checkip.dyndns.org \
        | perl -ne '/Address\: (.+?)</i || die; print $1'
}

function freeport() {

    local port=$1
    local ports="32768..61000";

    if [[ $port ]] ; then
        ports="$port,$ports";
    fi

    netstat  -atn \
        | perl -0777 -ne '@ports = /tcp.*?\:(\d+)\s+/imsg ; for $port ('$ports') {if(!grep(/^$port$/, @ports)) { print $port; last } }'
}

# fetch a page - in case no other tool is available
function caturl() {

    local IFS=$'\n';

    perl - $@ <<'EOF'

    use LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    $ua->add_handler( response_done =>
        sub { my ( $response, $ua, $h ) = @_; die if $response->is_error } );

    my $url = $ARGV[0];
    $url = "http://" . $url if $url !~ /^.+\:\/\//;
    my $req = HTTP::Request->new( GET => $url );
    print $ua->request($req)->content;
EOF

}

### conf files handling ########################################################

# cp dotfile from github
function _cphub() {
    local tmp=$(basename $1).$$
    (
        set -e
        wget -q --no-check-certificate \
            -O $tmp http://github.com/evenless/etc/raw/master/$1
    )
    mv -f $tmp $1
}

function bashrc_clean_environment() {

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

    echo "$note"                   > $file
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

function bashrc_setup_multiuser_account() {

    local remote_user=$REMOTE_USER
    local server=${1?specify server}

    ssh $server "test -d $remote_user/.ssh || mkdir -p $remote_user/.ssh"

    ssh-add -L | ssh $server "cat > $remote_user/.ssh/authorized_keys"
    scp $REMOTE_BASHRC $server:$remote_user/
    scp $REMOTE_HOME/.vimrc $server:$remote_user/
    scp $REMOTE_HOME/.screenrc $server:$remote_user/

    local funct=bashrc_setup_multiuser_environment

    bashrc_export_function $funct \
        | perl -0777 -pe 's/^.*?\n{|\n}.*//smg' \
        | ssh $server "cat > ~/.$funct"

    echo 'source ~/.'$funct \
        | ssh $server "grep -q $funct ~/.bashrc || cat >> ~/.bashrc"
}

function bashrc_setup_multiuser_environment() {

    [[ $SSH_CONNECTION ]] || return

    export REMOTE_HOST=${SSH_CLIENT%% *}

    type -p ssh-add 1>/dev/null || return

    shopt -s nullglob
    auth_files=(*/.ssh/authorized_keys)
    shopt -u nullglob

    [[ $auth_files ]] || return

    while read agent_key ; do

        agent_key=${agent_key%%=*}

        [[ $agent_key ]] || continue;

        for auth_file in ${auth_files[@]} ; do

            if grep -q "${agent_key}" $auth_file ; then
                export REMOTE_USER=${auth_file%%/.ssh/authorized_keys}
                break 2
            fi

        done

    done<<<$(ssh-add -L 2>/dev/null)

    [[ $REMOTE_USER ]] || return

    export REMOTE_HOME="$HOME/$REMOTE_USER"
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

function grabssh () {
    local SSHVARS="SSH_CLIENT SSH_TTY SSH_AUTH_SOCK SSH_CONNECTION DISPLAY"

    for x in ${SSHVARS} ; do
        (eval echo $x=\$$x) | sed  's/=/="/
                                    s/$/"/
                                    s/^/export /'
    done 1>$REMOTE_HOME/.ssh_agent_env
}

alias fixssh="source $REMOTE_HOME/.ssh_agent_env"
alias nosshagent="grabssh && unset SSH_AUTH_SOCK SSH_CLIENT SSH_CONNECTION SSH_TTY"

# ssh url of a file or directory
function url() {
    echo $USER@$HOSTNAME:$(abs "$@")
}

function _ssh_alias() {

    local IFS=$'\n'

    local cmd=$(perl - $@ <<'EOF'

        use strict;
        use warnings;
        use Cwd 'abs_path';

        my($host, $port, @files) = @ARGV;

        my $cmd = "ssh -p $port $host";

        my @tmp = ();
        my $is_get = 0;

        foreach(@files) {
            if($_ eq "-g") {
                $is_get = 1;
            } else {
                push(@tmp, $_);
            }
        }

        @files = @tmp;

        if(@files) {

            my $dst = "";

            if(@files > 1) {
                $dst = pop(@files) . "/";
            }

            my $src = join(",", @files);

            if($is_get) {
                $cmd = "scp -P $port $host:{$src} $dst";
            } else {
                $cmd = "scp -P $port {$src} $host:$dst";
            }
        }

        print "$cmd";
EOF
)

    eval "$cmd"
}

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

### SCREEN #####################################################################

alias screen="xtitle screen@$HOSTNAME ; export DISPLAY=; screen -c $REMOTE_HOME/.screenrc"
alias   tmux="xtitle   tmux@$HOSTNAME ; export DISPLAY= ; tmux"

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
        command mysql --show-warnings --pager="less -niSFX" "$@"
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

# setup local::lib and cpanm
function setupcpanm() { (

    set -e

    if [ -e ~/.cpan ] ; then
        DIE "remove ~/.cpan first" >&2
    fi

    WD=$(mktemp -d)
    cd $WD

    INFO "setting up local::lib..."
    wget -q \
    http://search.cpan.org/CPAN/authors/id/G/GE/GETTY/local-lib-1.006007.tar.gz

    tar xfz local-lib*tar.gz

    cd local-lib*/

    perl Makefile.PL --bootstrap 1>/dev/null
    make install 1>/dev/null

    cd /tmp
    rm $WD -rf

    INFO "setting up cpanm..."
    cd ~/bin

    if [ -e cpanm ] ; then
        rm cpanm
    fi

    wget -q http://cpansearch.perl.org/src/MIYAGAWA/App-cpanminus-1.1001/bin/cpanm
    perl -p -i -e 's/^#\!perl$/#\!\/usr\/bin\/perl/g' cpanm
    chmod +x cpanm

    INFO "Now set your lib path like: PERL5LIB=$HOME/perl5/lib/perl5:$HOME/perldev/lib"
    INFO "You may now install modules with: cpanm -nq [module name]"
) }

function cpanm() {
    perl -e 'map { s/\//\:\:/g ; s/\.pm$//g } @ARGV; system("cpanm", "-nq" , @ARGV) && exit 1;' \
         -- "$@"
}

### java #######################################################################

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

### xmv ########################################################################

function xmv() {

    local IFS=$'\n'

    perl - $@ <<'EOF'

use strict;
use warnings FATAL => 'all';
use File::Basename;

use Getopt::Long;
Getopt::Long::Configure('bundling');

my ($op, $include_directories, $dry, $normalize);
$dry = 1;

GetOptions(
    'x|execute' => sub { $dry = 0 },
    'd|include-directories' => \$include_directories,
    'n|normalize'           => \$normalize,
    'e|execute-perl=s'      => \$op,
);

if (!@ARGV) {
    @ARGV = <STDIN>;
    chop(@ARGV);
}

if (!@ARGV) {
    die "Usage: xmv [-x] [-d] [-n] [-e perlexpr] [filenames]\n";
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

    s/[^\w\.]+/_/g;

    s/[\._]+/_/g;

    s/^[\._]+//g;
    s/[\._]+$//g;

    $_ ||= "_empty_file_name";

    return $_ . lc($ext);
}
EOF
}

function normalize_file_names() {
    xmv -ndx "$@"
}

### simpletree() ###############################################################

function simpletree() {

    COLUMNS=$COLUMNS perl - $@ <<'EOF'

use strict;
use warnings;
no warnings 'uninitialized';
use File::Basename;

my $dirs_only = 1 if $ARGV[0] eq "-d";

my $depth = 0;
my $first = 1;
my $max   = $ENV{COLUMNS};

listdir(".");

sub listdir {
    my ($dir) = @_;

    my $prefix;

    if ( !$first ) {
        $prefix = "  " x $depth;
    }
    else {
        $first = 0;
    }

    $depth++;

    # $prefix .= " ";

    my @files = ();
    foreach my $file (<$dir/*>) {

        if ( -d $file ) {

            if ( -l $file ) {
                print shorten( $prefix . basename($file) . " -> " . readlink $file ) . "\n";
                next;
            }

            print shorten( $prefix . basename($file) ) . "\n";

            listdir($file);
            next;
        }

        next if $dirs_only;

        if ( -l $file ) {
            $file .= " -> " . readlink $file;
        }

        push( @files, $file );
    }

    foreach my $file (@files) {
        print shorten( $prefix . basename($file) ) . "\n";
    }

    $depth--;
}

sub shorten {
    my ($s) = @_;

    return $s if length($s) <= $max;

    my $left = substr( $s, 0, $max - 4 - 3 );
    my $right = substr( $s, length($s) - 4, length($s) );

    return $left . "..." . $right;
}
EOF
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

# NOTES ON cron
# * make cron scripts use bashrc (now path can use ~ too)
#    SHELL=/bin/bash
#    BASH_ENV=~/.bashrc
#    PATH=~/bin:/usr/bin/:/bin

# NOTES ON files
# * replace in files: replace
# * truncate a file without removing its inode: > file

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

# NOTES ON csv
# * join

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
# * disown - remove jobs from current shell

# NOTES ON networking
# * list all open ports and their associated apps: netstat -tapn
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

    # prevent historizing last command of last session on new shells
    if [ $_first_invoke != 0 ] ; then
        _first_invoke=0
        return
    fi

    # remove history position (by splitting)
    local history=$(history 1)

    [[ $_last_history = $history ]] && return;

    read -r pos cmd <<< $history

    if [[ $cmd == "rm "* ]] ; then
        history -d $pos
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

# search in eternal history
function h() {

    if [ "$*" = "" ] ; then
        tail -100 $HISTFILE_ETERNAL
        return
    fi

    if [[ $1 == d ]] ; then
        if [[ $2 == a ]] ; then
           tac $HISTFILE_ETERNAL \
                | cut -d \  -f 5 \
                | uniqunsorted \
                | perl -pe ' s/"//g;'
        else
           tac $HISTFILE_ETERNAL \
                | cut -d \  -f 5 \
                | uniqunsorted \
                | perl -pe 's/"//g'  \
                | head -100 \
                | tac
        fi
    elif [[ $1 == l ]] ; then
       tac $HISTFILE_ETERNAL \
            | perl -nae 'print if $F[4] eq "\"" . $ENV{PWD} . "\""' \
            | head -100 \
            | tac
    else
        tac $HISTFILE_ETERNAL \
            | grep -i "$*" \
            | head -100 \
            | tac \
            | grep -i "$*"
    fi
}

function uniqunsorted() {
    perl -ne 'print $_ if ! exists $seen{$_} ; $seen{$_} = 1'
}

### PROMPT #####################################################################

function _set_colors() {

    # disable any colors
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

function godark() {
    BASHRC_NO_HISTORY=1
    unset HISTFILE
    BASHRC_BG_COLOR=$GREEN
}

### STARTUP ####################################################################

_set_colors
unset _set_colors

unset PS1
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

_first_invoke=1

_OLDPWD=$(h d | tail -2 | head -1)
LAST_SESSION_PWD=$(h d | tail -1)

if [[ $LAST_SESSION_PWD ]] ; then

    if [[ -d "$LAST_SESSION_PWD" ]] ; then
        cd "$LAST_SESSION_PWD"
    fi

elif [[ -d "$REMOTE_HOME" ]] ; then
        cdh
fi

if [ -r $REMOTE_HOME/.bashrc_local ] ; then
    source $REMOTE_HOME/.bashrc_local
fi

OLDPWD=$_OLDPWD

true

### END ########################################################################
