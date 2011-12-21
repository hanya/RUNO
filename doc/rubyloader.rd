
= UNO components written in Ruby
The component loader for Ruby allows to write an UNO component 
in Ruby. 

== Ruby instance
When the loader is requested, the instance of Ruby is created 
in the instance of the office. And the instance is never die 
until the office is shutting down. Only an instance is 
created for an office instance.

== Loading process of the components
The script file which implements UNO components is loaded 
as a string and evaluated in an un-named module as follows:
  path = get_path(ctx, url)
  mod = Module.new
  mod.module_eval(IO.read(path), path)
After the evaluation, the loader try to find classes which include 
Uno::UnoComponentBase module. It provides nothing but it is 
used as an indicator of UNO components.

And components should be defined two constants which are provides 
information about the component itself.
--- IMPLE_NAME
      The implementation name of the component in String.

--- SERVICE_NAMES
      The service names which are supported by the component in Array.


= UNO component example
Here is a simple UNO component written in Ruby.

 module MyJobModule
   class MyJob
     # provides type information based on included modules of 
     # UNO interfaces.
     include Uno::UnoBase
     
     # tells this class should be detected as an UNO component
     # to the loader.
     include Uno::UnoComponentBase
     
     # provides execution of the task.
     include Uno::Com::Sun::Star::Task::XJobExecutor
     
     # provides information about this component.
     # The XServiceInfo module is extended in the loader 
     # module and it provides three methods based on 
     # the following two constants.
     include Uno::Com::Sun::Star::Lang::XServiceInfo
     
     IMPLE_NAME = "mytools.job.MyJob"
     SERVICE_NAMES = ["mytools.job.MyJob"]
     
     # new(ctx, args)
     # The component context is passed as first argument and 
     # additional arguments might be passed in the second 
     # argument when the component instantiated by 
     # createInstanceWithArgumentsAndContext method.
     def initialize(ctx, args)
       @ctx = ctx
     end
     
     # XJobExecutor
     # 
     def trigger(args)
       puts args
     end
   end
 end


== How to register
When you make your own UNO component in Ruby, you have to pack 
into an OXT extension. Recent version of the office supports 
passive registration of the components through the extension 
manager. 

The script provider for Ruby is implemented as an UNO component 
written in Ruby and you can refere it as an example.

Briefly, you have to prepare your extension package as follows:
 /
 |- META-INF/
 |          |- manifest.xml
 |- description.xml
 |- lib/
 |     |- comp.rb
 |     |- comp.components
These files have to be packed into a zip archive and name it 
with oxt file extension. 

manifest.xml file defines which files should be processed 
during the installation of your extension package.
  <?xml version="1.0" encoding="UTF-8"?>
    <manifest:manifest>
    <manifest:file-entry manifest:full-path="lib/comp.components" 
     manifest:media-type="application/vnd.sun.star.uno-components"/>
  </manifest:manifest>
The media-type application/vnd.sun.star.uno-components specifies 
the passive registration and its information is stored in 
lib/comp.components file.

comp.components file provides informations of your components.
 <?xml version="1.0" encoding="UTF-8"?>
  <components xmlns="http://openoffice.org/2010/uno-components">
   <component loader="com.sun.star.loader.Ruby" uri="rubyscriptprovider.rb">
    <implementation name="mytools.script.provider.ScriptProviderForRuby">
      <service name="com.sun.star.script.provider.ScriptProviderForRuby"/>
      <service name="com.sun.star.script.provider.LanguageScriptProvider"/>
    </implementation>
  </component>
 </components>
You component is written in Ruby and it should be loaded by 
com.sun.star.loader.Ruby and its file is stored in the location 
specified by uri attribute. It have to be have implementation name 
and it supports two services.

References:
* ((<URL:http://wiki.services.openoffice.org/wiki/Documentation/DevGuide/Extensions/Extensions>))


