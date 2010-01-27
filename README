
= RUNO

RUNO is a Ruby-UNO ['ju:nou] (Universal Network Object) bridge. UNO is used to 
construct OpenOffice.org so that you can play with the office. RUNO 
is implemented as Ruby extension library written in C++, but the bridge 
is not so fast because value conversion and multiple API call consume time. 
RUNO is not suite task like template creation, generating ODF (Open 
Document Format) is better for the task.


= How to Compile
You need following things to compile:
* OpenOffice.org and OpenOffice.org SDK (3.x?)
* Ruby (> 1.8.7?) and its header

Package version is not well checked.

Install OpenOffice.org and SDK. And then setup the SDK with configure.pl 
script equipped in the SDK. After that you can find shell script named 
"setsdkenv_ENV.EXT" to set environmet variables for compilation in the 
~/openoffice.orgVERSION_sdk/HOST.DOMAIN directory. The directory and file 
name is system dependent, please read SDK documentation.

For example, compilation procedure is like the following:
 > . ~/openoffice.org3.2_sdk/localhost/localdomain/setsdkenv_unix.sh
 > ruby extconf.rb
 > make
 > make site-install
compilation is successfully finished, runo.so file is created.


= Environment Variables

RUNO needs a few environmet variable settings befor to run work correctly. 

* LD_LIBRARY_PATH (for Linux or UNIX) or PATH (for Windows)
 To find libraries of UNO (or OpenOffice.org).
 
* URE_BOOTSTRAP
 Specifies fundamental(rc|.ini) file with vnd.sun.star.pathname protocol.
 e.g. vnd.sun.star.pathname:/opt/ooo-dev3/program/fundamentalrc


