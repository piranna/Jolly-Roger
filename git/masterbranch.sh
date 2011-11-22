#/bin/bash
VERSION='0.1'
LISTENERURL='http://localhooks.masterbranch.com/local-hook'

get_last_revision_pushed_to_mb (){
	revision=`git config --local --get masterbranch.lastrevision`
	echo $revision
}

get_user_name () {
	git_name=`git config --global --get user.name`
	if [[ -z $git_name ]]; then
		$git_name=`id | perl -ne 'm/uid=\d+\((\w+)\).*/; print "$1\n" '`
	fi
	echo "$git_name"
}

test_connection(){
	ping -c 2 google.com
	if [[ 0 != $? ]]; then
		exit 42
	fi	
}

print_error () {
	echo Please config your client as follows
	echo git config --global --add masterbranch.token TOKEN
	echo git config --global --add masterbranch.email EMAIL
	exit 255
}

get_token () {
	masterbranch_token=`git config  --global --get masterbranch.token`
	if [[ -z $masterbranch_token ]]; then
		print_error
	fi	
	echo "$masterbranch_token"	
}

get_email () {
	masterbranch_email=`git config  --global --get masterbranch.email`
	if [[ -z $masterbranch_email ]]; then
		print_error
	fi	
	echo "$masterbranch_email"		
}

get_repository () {
	uri=`git config --local --get remote.origin.url`
	if [[ -z $uri ]]; then
		uri=${PWD##*/}
	fi
	echo "$uri"
}

do_log () {
	# Notice than the commit parser just parses this format
	echo `git log --author="$(get_user_name)" --pretty=format:'COMMITLINEMARK%n{ \"revision\": \"%H\",  \"author\": \"%an <%ae>\",  \"timestamp\": \"%ct\",  \"message\": \"%s\"}' --raw  $last_rev..HEAD`
}

set_last_revision () {
	last_rev=$(get_last_revision_pushed_to_mb)
	if [[ -z $last_rev ]]; then
		rev_array=(`git log -n2 --format=%H`)
		last_rev=${rev_array[1]}
	fi
	echo "$last_rev"
}

test_connection

token=$(get_token)
email=$(get_email)
repository_url=$(get_repository) 
last_rev=$(set_last_revision)

raw_data=$(do_log) 
if [[ -z $raw_data ]]; then
	exit 0
fi

#Regular Base64 uses + and / for code point 62 and 63. URL-Safe Base64 uses - and _ instead. Also, URL-Safe base64 omits the == padding to help preserve space.
#http://en.wikipedia.org/wiki/Base64#URL_applications
encoded_data=`echo -n $raw_data | openssl enc -base64 | tr -d "\n" | tr "+" "-" | tr "/" "_" |tr -d "="` 

url_params="email=$email&vcs=git&repository=${repository_url}&token=${token}&payload=${encoded_data}&version=${VERSION}"  
curl -d $url_params ${LISTENERURL} 

#keeping track of revisions already pushed to masterbranch.com
if [[ $? == 0 ]]; then
	actual=`git log -n 1 --format=%H`
	if [[ ! -z $(get_last_revision_pushed_to_mb) ]]; then
		git config --local --unset masterbranch.lastrevision
	fi
	git config --local --add masterbranch.lastrevision $actual
fi

