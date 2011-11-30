**Version 0.1**

Clone the repository and set an enviroment variable to the directory

	export MASTERBRANCH_HOME=/path/Jolly-Roger

make the script executable

	chmod +x $MASTERBRANCH_HOME/git/masterbranch.sh

Git hook setup

    
* Git global configuration.

Your private token is under Settings -> Account admin
![Token section](http://mb-misc.s3.amazonaws.com/token.png)

	git config --global --add masterbranch.token TOKEN
	git config --global --add masterbranch.email EMAIL

	
*Project configuration.

For each project yo would like to  push to masterbranch you need to activate your post-commit hook.
		

	mv post-commit.sample post-commit
	echo $MASTERBRANCH_HOME/git/masterbranch.sh >> post-commit



Commit formating and further hooks 

The payload parameter is a url safe base64 encoed string to avoid issues sending the data.  
As you could see in log2json.pl the data sent is a json list with a map for each commit.
e.g:

	[
    	{"revision":"5c5afa47cf7cd15d5366aca5c0fb40607e5288f2",
     	"author":"Juan Luis Belmonte <jlbelmonte@gmail.com>",
    	"timestamp":"1322532384",
    	"message":"removed bashisms",
   	 	"added":[],
    	"modified":["git/masterbranch.sh"],
     	"deleted":[],
     	"other":[]},
    	{"revision":"d6d2b3258cb0e38b900a593b6a176d8907ce1ccd",
     	"author":"Juan Luis Belmonte <jlbelmonte@gmail.com>",
     	"timestamp":"1322102399",
     	"message":"testing issues with with escape characters  / ",
     	"added":[],
     	"modified":["git/masterbranch.sh"],
     	"deleted":[],
     	"other":[]}
    ]

The hook just clears the backslashes present in the string but other problematic characters like double quotes are handled in the server.

regarding to this format and the safe url base64 encoding you can write your own hook or fork this one.

 




