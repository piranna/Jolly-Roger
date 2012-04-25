#!/bin/sh
VERSION='0.1'
LISTENERURL='http://localhooks.masterbranch.com/local-hook'

REPO_PROTO='git'

# Include all the repository protocol specialiced functions
. ./${REPO_PROTO}/funcs.sh

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

url_params="email=$email&vcs=${REPO_PROTO}&repository=${repository_url}&token=${token}&payload=${encoded_data}&version=${VERSION}"  

curl -d $url_params ${LISTENERURL}  > /dev/null 2>&1
#keeping track of revisions already pushed to masterbranch.com
if [ $? -eq "0" ]
then
	set_last_revision_pushed_to_mb
fi

