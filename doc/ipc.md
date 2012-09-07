
# IPC

UNO supports interprocess connection through TCP/IP or named pipe.

It should be started with specific parameters.


## Contents

* [Environmental Variables](#environmental-variables)
* [Parameters](#parameters)
* [Connection](#connection)
* [Local Context and Remote Context](#local-context-and-remote-context)
* [Reference](#reference)


## Environment Variables

Loading the extension requires libraries of the office. And variables for bootstrapping 
is required. They can be specified by environmental variables as follows.


### URE_BOOTSTRAP

This variable should specify fundamental(rc|.ini) file containing type informations. 
It have to starting with `vnd.sun.star.pathname` protocol. Here is an example: 

    export URE_BOOTSTRAP=vnd.sun.star.pathname:file:///opt/openoffice.org3/program/fundamentalrc

It might be as follows on Windows environment:

    set URE_BOOTSTRAP=vnd.sun.star.pathname:file://C:/Program%2FFiles/OpenOffice.org/program/fundamental.ini


### `LD_LIBRARY_PATH` or PATH

Libraries of the office should be found at loading the extension. Depending of 
your environment, set `LD_LIBRARY_PATH` or PATH variable. Here is an example: 

    "/opt/openoffice.org3/program/../basis-link/program:/opt/openoffice.org3/program/../basis-link/ure-link/lib"

It might be as follows on Windows environment:

    set PATH=%PATH%;C:\Program Files\OpenOffice.org\URE\bin;C:\Program Files\OpenOffice.org\program


## Parameters

The office have to be started with `accept` option with specific arguments 
to allow to connect to your office instance through TCP or named pipe.

    # socket connection
    soffice '-accept=socket,host=localhost,port=2083;urp;'
    # named pipe
    soffice '-accept=pipe,name=rubypipe;urp;'

See the reference for valid arguments.


## Connection

See `Uno::Connector` module.

When the office started with the default parameters defined in the `connect` 
function, it can be connected like the following: 

    require 'uno'
    
    ctx = Uno::Connector.connect

Pass parameters in string notation or hash if required:

    url = "uno:pipe,name=rubypipe;urp;StarOffice.ComponentContext"
    ctx = Uno::Connector.connect(url)
    # or in hash. If some parameters are not specified, 
    # default value is used for lacked value.
    data = {'type' => 'socket', 'host' => 'localhost', 
            'port' => 2082, 'protocol' => 'urp'}
    ctx = Uno::Connector.connect(data)


## Local Context and Remote Context

The `get_component_context` method returns initialized context of the extension. When 
it is done in out of the office, it is initialized with local context. 
This is the different things from remote context which can be taken 
through com.sun.star.bridge.UnoUrlResolver service or other bridge. 
They are not compatible each other to instantiate service.


## Reference

* [IPC](http://wiki.services.openoffice.org/wiki/Documentation/DevGuide/ProUNO/UNO_Interprocess_Connections)
