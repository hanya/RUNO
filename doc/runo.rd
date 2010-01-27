
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
* Ruby (> 1.8.7?, 1.9.1 is better) and its header

Package version is not well checked.

Install OpenOffice.org and SDK. And then setup the SDK with configure.pl 
script equipped in the SDK. After that you can find shell script named 
"setsdkenv_ENV.EXT" to set environmet variables for compilation in the 
~/openoffice.orgVERSION_sdk/HOST.DOMAIN directory. The directory and file 
name is system dependent, please read SDK documentation.

For example, compilation procedure is like the following:
 > . ~/openoffice.org3.2_sdk/localhost.localdomain/setsdkenv_unix.sh
 > ruby extconf.rb
 > make
 > make site-install
compilation is successfully finished, runo.so file is created.


= Environment Variables

RUNO needs a few environmet variable settings befor to run work correctly. 

* LD_LIBRARY_PATH (for Linux or UNIX) or PATH (for Windows)
 To find libraries of UNO (or OpenOffice.org).
 Add ure/lib on Linux environment. Add path to URE\bin on Windows.

* URE_BOOTSTRAP
 Specifies fundamental(rc|.ini) file with vnd.sun.star.pathname protocol.
 e.g. vnd.sun.star.pathname:/opt/ooo-dev3/program/fundamentalrc


= How to Use

In the Ruby script, require the runo library.
 require 'runo'

If you see the error message like the following, LD_LIBRARY_PATH is not
correct. Set the variable to libuno_cppuhelpergcc3.so.3 that is a 
part of URE (UNO Runtime Environment).
 LoadError: libuno_cppuhelpergcc3.so.3: cannot open shared object file: 
 No such file or directory - /home/asuka/Desktop/runo/runo.so


= API Documentation of UNO

UNO is described in the UNO IDL (Interface Definition Language) and 
these definitions are implemented as API of the OpenOffice.org. 
You can refere the IDL Reference from:
((<URL:http://api.openoffice.org/docs/common/ref/com/sun/star/module-ix.html>))
Some useful informations are described in the OpenOffice.org 
Developer's Guide:
((<URL:http://wiki.services.openoffice.org/wiki/Documentation/DevGuide/OpenOffice.org_Developers_Guide>))

UNO provides introspective api and reflection api and you can use 
a tool that uses these api to get informations about UNO objects:
((<URL:http://extensions.services.openoffice.org/project/MRI>))


= About RUNO and UNO

This section describes about the bridge briefly. Runo is a bridge connects 
between Ruby and UNO, provides Ruby to work with UNO component. 
The OpenOffice.org is working in the other process and you need to connect 
to it, the way to connect is provided by 
com.sun.star.bridge.UnoUrlResolver through local component context. 
Starting point is the local component context.

== Local Component Context

The local compoenent context works in limited environment withought 
connection to remote OpenOffice.org server.
Runo provides local component context like the following:
  require 'runo'
  local_ctx = Runo.get_component_context
If you meet LoadError at the loding time of the library, check the 
LD_LIBRARY_PATH environment variable.

== Remote Component Context

The component context of remote OpenOffice.org can be taken using 
com.sun.star.bridge.UnoUrlResolver service.
  uno_url = "uno:socket,host=localhost,port=2083;urp;StarOffice.ServiceManager"
  resolver = local_ctx.getServiceManager.createInstanceWithContext(
      "com.sun.star.bridge.UnoUrlResolver", local_ctx)
  ctx = resolver.resolve(uno_url)
This code works with OpenOffice.org started with an argument:
  $soffice '-accept=socket,host=localhost,port=2083;urp;StarOffice.ServiceManager'
The office starts listening at the port and UnoUrlResolver connect to it.

Deeply, read following description:
* ((<URL:http://wiki.services.openoffice.org/wiki/Documentation/DevGuide/ProUNO/UNO_Interprocess_Connections>))

Now you can play with full OpenOffice.org functions if your environment variables 
are collect. If URE_BOOTSTRAP environment variable is wrong, you may get 
an error like this:
  smgr = ctx.getServiceManager
  desktop = smgr.createInstanceWithContext("com.sun.star.frame.Desktop", ctx)
  doc = desktop.loadComponentFromURL("private:factory/swriter", "_blank", 0, [])
  #=> loadCompoenntFromURL method is not defined (NameError) for nil instance

== Service Manager
The service manager is the central service manager provides you to work 
with new instance of UNO components. Get the service manager from remote 
component context.
  smgr = ctx.getServiceManager


== Desktop
The desktop of the OpenOffice.org is used to treat documents. Openning existing 
document, creating new document or to access current opened document.
  desktop = smgr.createInstanceWithContext("com.sun.star.frame.Desktop", ctx)
  # create new document
  doc = desktop.loadComponentFromURL("private:factory/swriter", "_blank", 0, [])
  # open a document
  doc_path = "/home/ruby/Documents/doc1.ods"
  doc_url = Runo.file_url_to_system_path(doc_path)
  doc = desktop.loadComponentFromURL(doc_url, "_blank", 0, [])

About Desktop service and XComponentLoader interface:
* ((<URL:http://api.openoffice.org/docs/common/ref/com/sun/star/frame/Desktop.html>))
* ((<URL:http://api.openoffice.org/docs/common/ref/com/sun/star/frame/XComponentLoader.html>))


Keep in mind, UNO needs a file path in the URL notation, 
use Runo.#file_url_to_system_path and Runo.#system_path_to_file_url method 
to convert between file path and file url.
  # active document means current document
  doc = desktop.getCurrentComponent
  # find named document
  frame = nil
  frames = desktop.getFrames
  for i in 0..frames.getCount - 1
    if frames.getByIndex(i).getController.Title == "Untitled 1"
      frame = frames.getByIndex(i)
      break
    end
  end



