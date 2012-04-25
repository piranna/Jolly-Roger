get_last_revision_pushed_to_mb (){
    revision=`git config --local --get masterbranch.lastrevision`
}

set_last_revision_pushed_to_mb (){
    # Get just pushed commit
    actual=`git log -n 1 --format=%H`

    # Remove last revision pushed to Masterbranch (if any)
    get_last_revision_pushed_to_mb
    if [ -n "$revision" ]
    then
        git config --local --unset-all masterbranch.lastrevision
    fi

    # Set actual pushed revision as the last one pushed to Masterbranch
    git config --local --add masterbranch.lastrevision $actual
}

get_user_name () {
	git_name=`git config --global --get user.name`
	if [ -z "$git_name" ]
	then
		git_name=`id | perl -ne 'm/uid=\d+\((\w+)\).*/; print "$1\n" '`
	fi
}

test_connection(){
	ping -c 2 google.com > /dev/null
	if [ 0 != $? ]
	then
		exit 42
	fi	
}

print_error () {
	printf Please config your client as follows
	printf git config --global --add masterbranch.token TOKEN
	printf git config --global --add masterbranch.email EMAIL
	exit 255
}

get_token () {
	masterbranch_token=`git config  --global --get masterbranch.token`
	if [ -z $masterbranch_token ]
	then
		print_error
	fi	
}

get_email () {
	masterbranch_email=`git config  --global --get masterbranch.email`
	if [ -z $masterbranch_email ]
	then
		print_error
	fi			
}

get_repository () {
	uri=`git config --local --get remote.origin.url`
	if [ -z $uri ]
	then
		uri=${PWD##*/}
	fi
}

do_log () {
	get_user_name
	# Notice than the commit parser just parses this format
	log_output=`git log --author="$git_name" --pretty=format:'COMMITLINEMARK%n{ "revision": "%H",  "author": "%an <%ae>",  "timestamp": "%ct",  "message": "%s%b"}' --raw  $last_revision..HEAD`
	raw_data=`$MASTERBRANCH_HOME/git/log2json.pl "$log_output" | tr -d "\n"`
}

set_last_revision () {
	get_last_revision_pushed_to_mb
	last_revision=$revision
	if [ -z $last_revision ]
	then
		last_revision=`git log -n2 --format=%H | tr "\n" ":" | perl -ne '@revs=split(/:/, $_); print @revs[1]'`
	fi
}
