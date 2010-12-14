### stuff also needed non-interactively ########################################

function xmv() {

    local IFS=$'\n'

    perl - $@ <<'EOF'
use strict;
use warnings;
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

    $abs = "$dir/$file";
    my $was = $file;
    $_ = $file;

    $_ = normalize($abs) if $normalize;

    # vars to use in perlexpr
    $COUNT++;
    $COUNT = sprintf("%08d", $COUNT);

    if ($op) {
        eval $op;
        die $@ if $@;
    }

    my $will = "$dir/$_";

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

    s/www\.[^\.]+\.[^\.]+//g;

    s/[^\w\.]+/_/g;

    s/[\.]+/\./g;
    s/[_]+/_/g;
    s/[\._]{2,}/\./g;

warn "normalizing: " . $_;

    s/^[\._]+//g;
    s/[\._]+$//g;

    $_ ||= "_empty_file_name";

    return $_ . lc($ext);
}
EOF
}
export -f xmv

function normalize_file_names() {
    xmv -ndx "$@"
}
export -f normalize_file_names

function replace() { (

    local search=$1
    local replace=$2
    local files=$3

    if [[ $search = "" || $replace = "" || $files = "" ]] ; then
        DIE 'usage: replace "search" "replace" "file pattern"'
    fi

    find -iname "$files" -exec perl -p -i -e 's/'$search'/'$replace'/g' {} \;
) }
export -f replace

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

export MODULEBUILDRC=~/perl5/.modulebuildrc
export PERL_MM_OPT=INSTALL_BASE=~/perl5
export PATH=~/perl5/bin:$PATH

export PERL5LIB=~/perl5/lib/perl5:~/perldev/lib

### for interactive shells only ################################################

[ -z "$PS1" ] && return

export REMOTE_HOME=$HOME
export PATH=~/bin:$PATH

export LANG="de_DE.UTF-8"
# export LC_ALL="de_DE.UTF-8"
# export LC_CTYPE="de_DE.UTF-8"

# use english messages on the command line
export LC_MESSAGES=C

function switch_to_iso() { export LANG=de_DE@euro ; }

export EDITOR=vi
alias vi="DISPLAY= vi"

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

# remove domain from hostname if necessary
HOSTNAME=${HOSTNAME%%.*}

if [[ $OSTYPE =~ linux ]] ; then
    alias ls='ls --time-style=+"%F %H:%M" --color=auto'
fi

alias cp="cp -i"
alias mv="mv -i"
alias less="less -i"
alias crontab="crontab -i"

alias j="jobs -l"
alias l="ls -lh"
alias lr="ls -rtlh"
alias lc="ls -rtlhc"
alias xargs="xargs -I {}"

alias apts="apt-cache search"
alias aptw="apt-cache show"
alias apti="sudo apt-get install"
alias aptp="sudo dpkg -P"
alias aptc="sudo apt-get autoremove"

if [[ $(type -p tree) ]] ; then
    alias t="tree --noreport --dirsfirst"
    alias td="tree --noreport -d"
else
    alias t="find | sort"
    alias td="find -type d | sort"
fi

alias filter_remove_comments="perl -ne 'print if ! /^#/ && ! /^$/'"

# make less more friendly for non-text input files, see lesspipe(1)
if [ -x /usr/bin/lesspipe ] ; then
    eval "$(lesspipe)"
fi

if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

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

function parent() {
    echo $(ps -p $PPID -o comm=) "($PPID)"
}

if [[ $(type -p pstree) ]] ; then
    alias pstree="pstree -A"
else
    alias pstree="ps axjf"
fi

function p() {

    local args

    if [[ $@ ]] ; then
        args=" +/$@"
    fi

    pstree -aphl | grep -v "{" | less -R $args
}

function pswatch() { watch -n1 "ps -A | grep -i $@ | grep -v grep"; }

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

export GREP_OPTIONS="--color=auto"
alias listgrep="grep -xFf"

# a simple grep without need for quoting or excluding dot files
alias g="set -f && _g"
function _g() { (

    if [[ ! $@ ]] ; then
        DIE "usage: g [search term]"
    fi

    grep -rsinP --exclude-dir=.[a-zA-Z0-9]* --exclude=.* "$@" .
    set +f
) }

function gi() { (

    if [[ $# < 2 ]] ; then
        DIE "usage: gi [filename pattern] [search term]"
    fi

    grep -rsin --exclude-dir=.[a-zA-Z0-9]* --exclude=.* --include="$@" .
    set +f
) }

function f() { (

    if [[ ! $@ ]] ; then
        DIE "usage: f [filename pattern]"
    fi

    find . \! -regex ".*\/\..*" -iname "*$@*" | grep -i "$@"
) }

function bak() {
    cp $1{,_$(date +%Y%m%d_%H%M%S)};
}

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

    wget -q --no-check-certificate \
        -O /tmp/bashrc.$$ http://github.com/evenless/etc/raw/master/.bashrc \
        || return 1

    mv -f /tmp/bashrc.$$ ~/.bashrc

    bashrc_clean_environment

    . ~/.bashrc
}

function bashrc_clean_environment() {

    # remove aliases
    unalias -a

    # remove functions
    while read funct ; do
        unset $funct
    done<<EOF
        $(perl -ne 'foreach (/^function (.+?)\(/) {print "$_\n" }' ~/.bashrc)
EOF

}

function reloadbashrc() {

    bashrc_clean_environment

    . ~/.bashrc
}

function updatevimconfig() {

    for dir in ~/.vim/colors  ~/.vim/plugin ; do
        if [ ! -d $dir ] ; then
            mkdir -p $dir
        fi
    done

    wget -qO ~/.vimrc http://github.com/evenless/etc/raw/master/.vimrc
    wget -qO ~/.vim/colors/autumnleaf256.vim http://github.com/evenless/etc/raw/master/.vim/colors/autumnleaf256.vim
    wget -qO ~/.vim/plugin/taglist.vim http://github.com/evenless/etc/raw/master/.vim/plugin/taglist.vim
}

# alias quote="fmt -s | perl -pe 's/^/> /g'"

function timestamp2date() {
    local timestamp=$1
    perl -MPOSIX -e \
    'print strftime("%F %T", localtime(substr("'$timestamp'", 0, 10))) . "\n"'
}

function dos2unix() {
    perl -i -pe 's/\r//g' "$@"
}

function unix2dos() {
    perl -i -pe 's/\n/\r\n/' "$@"
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

alias mysql="mysql --show-warnings"

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

# for cpan
export FTP_PASSIVE=1

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
        print $INC{$module} || exit 1;
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

# edit a lib via PERL5LIB
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
    perl -e 'map { s/\//\:\:/g ; s/\.pm$//g } @ARGV; system("cpanm" , @ARGV);' \
         -- "$@"
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
    _bashrc_eternal_history_file=$REMOTE_HOME/.bash_eternal_history
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

# search in eternal history
function h() {

    if [ "$*" = "" ] ; then
        tail -100 $_bashrc_eternal_history_file
        return
    fi

    if [[ $1 == d ]] ; then
       tail -100 $_bashrc_eternal_history_file | \
            cut -d \  -f 5 | sort -u | perl -pe 's/"//g' 
    else
        grep -i "$*" $_bashrc_eternal_history_file | tail -100 \
            | grep -i "$*"
    fi
}

### network ####################################################################

function get_natted_ip() {
    wget http://checkip.dyndns.org/ -q -O - \
        | grep -Eo '\<[[:digit:]]{1,3}(\.[[:digit:]]{1,3}){3}\>'
}

function set_remote_host() {
    REMOTE_HOST=$(who -m --ips | perl -ne 'print "$1$2" if /(?:\ ([\d\.]+$)|\((.*?)[\:\)]+)/')
}

function freeport() {
    netstat  -atn \
        | perl -0777 -ne '@ports = /tcp.*?\:(\d+)\s+/imsg ; for $port (32768..61000) {if(!grep(/^$port$/, @ports)) { print $port; last } }'
}

### .bashrc_identify_user_stuff

function set_remote_user_from_ssh_key() {

    if [[ $SSH_CONNECTION = "" ]] ; then
        return
    fi

    if [[ $(type -p ssh-add) = "" ]] ; then
        return
    fi

    local agent_key auth_key auth_files

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
            continue
        fi

        auth_key=$(grep -i "${agent_key}" $auth_files | tail -1)

        if [[ $auth_key != "" ]] ; then
            break
        fi

    done<<EOF
        $(ssh-add -L 2>/dev/null)
EOF

    if [[ "$auth_key" =~ \[remote_user=(.+)\](.*)$ ]] ; then
        export REMOTE_USER=${BASH_REMATCH[1]}
        REMOTE_FULL_NAME=${BASH_REMATCH[2]}
    else
        return
    fi

    if [[ $REMOTE_FULL_NAME ]] ; then
        export REMOTE_FULL_NAME
    fi

    if [ "$REMOTE_USER" != $USER ] ; then

        export REMOTE_HOME="$HOME/$REMOTE_USER"

        if [ ! -d "$REMOTE_HOME" ] ; then
            echo "creating remote home: $REMOTE_HOME..." >&2
            mkdir "$REMOTE_HOME" || exit 1
        fi

    fi
}

function load_remote_host_bash_rc() {

    if [[ $REMOTE_USER != "" ]] ; then
        return
    fi

    set_remote_user_from_ssh_key

    if [[ $REMOTE_USER = "" ]] ; then
        return
    fi

    local remote_bashrc="$REMOTE_HOME/.bashrc"

    if [[ -e $remote_bashrc ]] ; then
        source $remote_bashrc
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

function sshtunnel() { (

    local  in=$1
    local  gw=$2
    local out=$3

    if [[ $@ < 3 ]] ; then
        DIE "usage: sshtunnel [in_host:]in_port user@gateway out_host:out_port"
    fi

    local cmd="ssh -v -N -L $in:$out $gw"
    INFO "running: $cmd"
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

alias screen="xtitle screen@$HOSTNAME ; export DISPLAY=; screen"

function srd() {

    grabssh

    local ok

    screen -rd $1 && ok=1

    if [[ ! $ok ]] ; then
        screen -rd main && ok=1
    fi

    if [[ $ok ]] ; then
        clear
    fi
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

    if [[ $USER == "root" ]] ; then
        echo ${RED}$USER${NO_COLOR}
    else
        echo $USER
    fi
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
    local hostname=$(_color_user)@$GREEN$HOSTNAME$NO_COLOR
    _fix_pwd
    _set_bg_jobs_count

    # $NO_COLOR first to reset color setting from other programs
    PS1=$GRAY"$time$NO_COLOR $hostname:$_pwd${_bg_jobs_count}""$NO_COLOR> "
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

    local if_root=""
    if [[ $USER == "root" ]] ; then
        if_root="${RED}root$NO_COLOR "
    fi

    PS1=$NO_COLOR"$GRAY$time$NO_COLOR $if_root$_pwd${_bg_jobs_count}"">$NO_COLOR "
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

### STARTUP ####################################################################

function _init_bash() {
    _set_colors
    unset _set_colors

    set_remote_host

    set_remote_user_from_ssh_key
    load_remote_host_bash_rc

    if [[ "$REMOTE_USER" != "" ]] ; then

        if [[ -r $REMOTE_HOME/.vimrc ]] ; then
            export MYVIMRC=$REMOTE_HOME/.vimrc
        fi

        if [[ -r $REMOTE_HOME/.screenrc ]] ; then
            alias screen="screen -c $REMOTE_HOME/.screenrc"
        fi

        if [[ -d "$REMOTE_HOME" ]] ; then
            cd "$REMOTE_HOME"
        fi
    fi

    case $(ps -p $PPID -o comm=) in
        screen|screen.real)
            _simple_prompt
        ;;
        *)
            if [[ $REMOTE_HOST ]] ; then
                _prompt
            else
                _original_user=$USER
                _simple_prompt
            fi
        ;;
    esac
}

_init_bash
unset _init_bash
unset _init_perl5lib

_first_invoke=1

### MISC #######################################################################

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

function notecmdfu() {
    curl "http://www.commandlinefu.com/commands/matching/$@/$(echo -n $@ | openssl base64)/plaintext";
}

# query wikipedia via dns
function wp() {
    dig +short txt "$*".wp.dg.cx | perl -pe 's/\\//g'
}

### THE END ####################################################################
