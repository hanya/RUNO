
= Macro
The script provider for Ruby allows someone to write macros 
for OpenOffice.org in Ruby. 

== Ruby script provider
The script provider is written as an UNO component in Ruby. 
And it is loaded by the ruby loader. So the script provider 
and the loader are working on the same instance of Ruby.

== Macro directory
Your Ruby script have to be stored under: 
  USER_PROFILE/Scripts/ruby 
with "rb" file extension. You can store your scripts in 
the sub directories.

== Execution of Macros
Macros stored in the directory described above are executed 
through Tools - Macros - Run Macros entry 
or Tools - Macros - Organize Macros - Ruby entry in main menu 
of your office. 

There is no IDE or edit function provided.

You can call public methods as macros which is defined in your 
Ruby script when your script is loaded by the script provider. 
What is public method, see following part.

The script file of Ruby is loaded as string and evaluated 
in an un-named class with class_eval method as follows: 
    klass = Class.new
    klass.const_set(:XSCRIPTCONTEXT, script_context)
    text = storage.file_content(file_name)
    klass.class_eval(text, Uno.to_system_path(file_name))
    capsule = klass.new
Before evaluation of your script, XSCRIPTCONTEXT constant 
is set to the class which provides css.script.provider.XScriptContext 
interface and it is the contact point to the office in macros.

The script provider expose only public methods of instance of 
the class which evaluates your script. 

Ruby scripts provided as macros are parsed by ripper module 
because of the security reason. Therefore parse error in your 
script might not be reported before execution.

=== XSCRIPTCONTEXT constant
This XSCRIPTCONTEXT constant provides you to access to your office 
including the current document and the component context. It 
provides com.sun.star.script.provider.XScriptContext interface 
and the interface export these methods: 

--- ScriptContext#getComponentContext -> Uno::RunoProxy
     Returns the component context which provides 
     com.sun.star.uno.XComponentContext interface. 
       def path_substitution(*)
         ctx = XSCRIPTCONTEXT.getComponentContext
         smgr = ctx.getServiceManager
         ps = smgr.createInstanceWithContext(
           "com.sun.star.util.PathSubstitution", ctx)
         url = ps.substituteVariables("$(user)", true)
         p url
       end

--- ScriptContext#getDocument -> Uno::RunoProxy
     Returns the desktop which is the instance of 
     com.sun.star.frame.Desktop service.
       def hello(*)
         doc = XSCRIPTCONTEXT.getDocument
         doc.getText.setString("Hello world.")
       end

--- ScriptContext#getDesktop -> Uno::RunoProxy
     Returns the document object.
       def create_new_doc(*)
         desktop = XSCRIPTCONTEXT.getDesktop
         doc = desktop.loadComponentFromURL("private:factory/scalc", 
           "_blank", 0, [])
         cell = doc.getSheets.getByIndex(0).getCellByPosition(0, 0)
         cell.setString("foo")
       end

--- ScriptContext#getInvocationContext -> Uno::RunoProxy
     Returns the invocation context.

=== Return value
All Ruby's method have their return value. The return value of the 
method executed as the macro, which is converted to value of UNO. 
If your method returns a value which can not be converted to one 
of a value of UNO, an error is shown.


== Macro name and description
When the script provider find the YAML file which has the same 
name with your script file, macro names and their descriptions 
are loaded from it and shown in the UI.

Here is an example to specify the name of your macro.
  # method name: {name: name of macro, description: short description}
  writer_hello: { name: Hello Writer!, description: Say Hello!}

== Macro example




