Steel - Rebol Open Development Tools
====

This is a repository to share and collaborate on Rebol integrated development tools.

The repository currently has a few IDE tools plus a dis-organised set of odds and ends
to build, test and demonstrate Rebol itself and a few of the libraries I have in other repositories.

The project content and organisation will most definitely change in time (maybe even its name).
For now its mainly a question of sharing useful code in a centralized spot.

Note that it's entirely possible that some code here, may be extracted to its own repository
if it proves easier to manage and the user base asks for it.

Eventually I'll integrate some of the tools together within a unified application framework I am designing.


slim libraries
====

In order to run the stuff in this repository, you need to get the slim library manager and the module packages
from Github.

The apps and scripts here are setup to use the libraries within a subfolder or from an external source.  

There is a very simple way to get and update all the libs.  You just need to run the get-github-slim-libs.r
Rebol script.  It is setup for SSH access by default (using Git protocol), but you can change it so that it
uses an https connection.



.gitignore file
====

The .gitignore file includes a few entries for temporary files, but it also includes one for the slim-library
sub-folder if it's created by the get-github-slim-libs.r script.  This way the files within libs will never be
part of the parent Git repo and won't cause any side-effects.


