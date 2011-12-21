
= RPC
UNO supports Remote Process Connection through named pipe or TPC. 

It should be the office started with optional parameters. 

== Environmental variables
Loading runo.so extension of Ruby needs the libraries of the office 
which are there somewhere else. And the library needs bootstrap 
settings to load something from the office components.
These variables should be set before to load the extension module.

--- URE_BOOTSTRAP
    Specifies fundamental(rc|.ini) file with vnd.sun.star.pathname protocol.
    e.g. vnd.sun.star.pathname:/opt/openoffice.org3/program/fundamentalrc

--- LD_LIBRARY_PATH
--- PATH
    To find libraries of UNO (or OpenOffice.org).
    For example, "/opt/openoffice.org3/program/../basis-link/program:/opt/openoffice.org3/program/../basis-link/ure-link/lib"

== Parameters
The office which is connected by the RUNO needs started with 
accept option.

    soffice '-accept=socket,host=localhost,port=2083;urp;StarOffice.ServiceManager'

There is the complete description about the accept option can be 
found in the reference below.

== Connection
There is helper function to connecto to the office in Uno module. 
Use Uno::Connector.connect function to get connection to the 
instance of the living office.

There are several functions on Connector module.

--- connect(url, resolver=nil) -> object | nil
    Returns remote component context when the connection being 
    succeed. url is the one to suite the parameters passed to 
    the office with the accept option.

--- url_construct(type="socket", host="localhost", port=2083, pipe_name=nil, nodelay=false) -> String
    This function helps to make an url to connect to the office.

--- bootstrap(office="soffice", type="socket", host="localhost", port=2083, pipe_name=nil, nodelay=false)
    Returns remote component context when the office is 
    successfully started and connected to it. Otherwise 
    Uno::Connector::NoConnectionError error is raised. 
    

== Local context and remote context
Do not confuse the local context and the remote context. They 
are not the same. 

== Reference
* ((<URL:http://wiki.services.openoffice.org/wiki/Documentation/DevGuide/ProUNO/UNO_Interprocess_Connections>))

