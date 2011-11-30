#!/bin/sh
VERSION='0.1'
LISTENERURL='http://localhooks.masterbranch.com/local-hook'

get_last_revision_pushed_to_mb (){
	revision=`git config --local --get masterbranch.lastrevision`
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
	if [ $masterbranch_token = "" ]
	then
		print_error
	fi	
}

get_email () {
	masterbranch_email=`git config  --global --get masterbranch.email`
	if [ $masterbranch_email = "" ]
	then
		print_error
	fi			
}

get_repository () {
	uri=`git config --local --get remote.origin.url`
	if [ $uri = "" ]
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

test_connection

get_token
token=$masterbranch_token 
get_email
email=$masterbranch_email
get_repository
repository_url=$uri 

set_last_revision
do_log 


if [ -z "$raw_data" ]
then
	exit 0
fi


#purge backslashes from the content, that may cause unexpected character escaping in the Json parser. Unexpected double quotes are managed by masterbranch parser


#Regular Base64 uses + and / for code point 62 and 63. URL-Safe Base64 uses - and _ instead. Also, URL-Safe base64 omits the == padding to help preserve space.
#http://en.wikipedia.org/wiki/Base64#URL_applications

encoded_data=`echo "$raw_data" | openssl enc -base64 | tr -d "\n" | tr "+" "-" | tr "/" "_" |tr -d "="` 

url_params="email=$email&vcs=git&repository=${repository_url}&token=${token}&payload=${encoded_data}&version=${VERSION}"  

curl -d $url_params ${LISTENERURL}  > /dev/null 2>&1
#keeping track of revisions already pushed to masterbranch.com
if [ $? -eq "0" ]
then
	actual=`git log -n 1 --format=%H`
	get_last_revision_pushed_to_mb
	if [ -n "$revision" ]
	then
		git config --local --unset-all masterbranch.lastrevision
	fi
	git config --local --add masterbranch.lastrevision $actual
fi

