

= Modules and Classes


== module Runo

Runo module is a top level module of runo. Runo module defines a few 
classes and other class based on UNO is dynamically defined. Or 
import from UNO with Runo.#uno_require method.

--- get_component_context -> RunoProxy|nil

Get local component context and initialize the bride. Call first 
to do something. Return value is Runo::RunoProxy instance if 
successfully initialized (normally unfailed). If failed, nil is returned. 
If you do not set URE_BOOTSTRAP environment variable correctly, 
UNO is runnnig with very restricted state.
    

--- system_path_to_file_url(path) -> String

Convert system path to URL indicats the same file. UNO uses URL as 
its address to find IO resource. Multi-byte characters are escaped by 
the URL encode. 
@param path  System path to convert to file URL.
@return      File URL.
@raise       ArgumentError
             Illegal file path is passed.
If you need system path from the file URL, use 
Runo.#file_url_to_system_path method.
  p Runo.system_path_to_file_url("/home/ruby/runo")
  #=> "file:///home/ruby/runo"

--- file_url_to_system_path(url) -> String

Convert from file URL to system path.
@param url  File URL to convert to system path.
@return      System path.
@raise       ArgumentError
             Illegal file url is passed.
  p Runo.file_url_to_system_path("file:///home/ruby/")
  #=> "/home/ruby/"
    
--- absolutize(path, relative) -> String

Make path absolute.
@param path      File or directory url.
@param relative  Relative path to the file or directory.
@return          URL.
@raise           ArgumentError
                 In-correct url is passed.
  p Runo.absolutize("file:///home/ruby/Desktop", "../")
  #=> "file:///home/ruby/"

--- uno_require(type_name [, ..]) -> values

Imports UNO structs, exceptions, interfaces, enum, enums, constant, 
and constants groups. Structs, exceptions, interfaces are defined 
as class under the Runo module and 
@param type_name  Type name for an UNO value or values.
@return           UNO value. If more than one arguments are passed, 
                  values are returned as an array.
@raise            ArgumentError
                  Unknown type name is passed.
  # struct
  Point = Runo.uno_require("com.sun.star.awt.Point")
  point = Point.new
  point.X = 100
  point.Y = 200
or
  point = Point.new(100, 200)

  # enum. constants group and a constant are almost similar
  FS_ITALIC = Runo.uno_require("com.sun.star.awt.FontSlant.ITALIC")
  # also allowed
  FontSlant = Runo.uno_require("com.sun.star.awt.FontSlant")
  p FontSlant.ITALIC

--- uuid -> Array

Returns UUID.

--- invoke(runo_object, method_name, arguments) -> (depends on the method that is called)

Call method of the UNO object wrapped by the instance of the RunoProxy class.
The method like named "inspect" does not allow to call directory because of 
name confliction.
  introspection = smgr.createInstanceWithContext(
      "com.sun.star.beans.Introspection", ctx)
  Runo.invoke(introspection, "inspect", [ctx])

=== class Runo::Enum

--- new(type_name, value) -> Enum

Create enum from type name and value name. Immutable.
@param type_name Type name of UNO enum. 
@param value     Value name of an UNO enum.
@return          An enum.
  Runo::Enum.new("com.sun.star.awt.FontSlant", "ITALIC")

--- type_name -> String

Type name of the enum.

--- value -> String

Value name of the enum.

--- self == other -> bool

Check is the same with other enum value.
@param other  other object
@return       true if other descrive the same enum, false for other.

=== class Runo::Type
Runo::Type describes UNO type.

--- new(type_name, type_class) -> Type
--- new(type_name) -> Type
--- new(type_class) -> Type
Create type from type name and type class. Immutable.
TC_LONG = Runo::Enum.new("com.sun.star.uno.TypeClass", "LONG")
Runo::Type.new("long", TC_LONG)
--- type_name -> String
Type name of the type.
--- type_class -> Enum
Type class of the type described by enum of com.sun.star.uno.TypeClass.

=== class Runo::Char
Describes a character.
--- new(value) -> Char
Create char type of UNO from a string having only one character.
      Runo::Char.new("c")
--- value -> String
Value that is kept by the instance.

=== class Runo::Any
Runo::Any keeps a value and its type. Use this class to pass a value that is 
not recognized its type of the value by the bridge.
--- new(type_class, value) -> Any
--- new(type_class_name, value) -> Any
Specify the type of value as type_class in one of the enum value of
com.sun.star.uno.TypeClass. Or pass the name of the type in String.
  Runo::Any.new(Runo::Enum.new("com.sun.star.awt.uno.TypeClass.LONG"), 100)
  Runo::Any.new("long", 100)
  Runo::Any.new("[]com.sun.star.beans.PropertyValue", props)

=== class Runo::ByteSequence
    

=== class Runo::RunoStruct
Do not instanciate this class. This class is inherited as parent by 
structs defined dynamically.

=== class Runo::Com::Sun::Star::Uno::Exception
Runo::Com::Sun::Star::Uno::Exception < StandardError < ...

Base class of UNO exceptions. This class inherits StandardError 
class.

=== class Runo::RunoProxy
Runo::RunoProxy < Object < ...

Base class of UNO objects. All UNO methods are called through 
method_missing method. 
    
  ctx = Runo.get_component_context
  smgr = ctx.get_service_manager

--- has_interface?(interface_name) -> bool
Check the object has specific UNO interface.
@param interface_name   The name of an interface.
@return                 True if the object supports the interface.
  p ctx.has_interface?('com.sun.star.uno.XInterface') "=> true

--- self == other -> bool
Check two objects are the same object. This method checks internal value 
of wrapped UNO object.

=== module Runo::Com::Sun::Star::Uno::XInterface
This is defined as module because of you can include interface 
of UNO in your class implements UNO component. Do not define interface 
your self, use Runo.#uno_require.

=== Other Classes and Modules
Other classes may defined at runtime by the RUNO. They are defined under 
Runo module and they have the same hierarchy with UNO IDL. But all UNO 
module is named with small case characters and Ruby does not allow to 
start the name of class with lower case letter, so that RUNO defines 
their name starting with upper case character. 
For example, com.sun.star.awt.Point struct is defined 
as Runo::Com::Sun::Star::Awt::Pont.
If you call Runo.#uno_require method to get the value of UNO, classes are 
defined also.
  Point = Runo.uno_require('com.sun.star.awt.Point')
  # Runo::Com::Sun::Star::Awt::Pont is defined.
When you get module of enum of UNO, its defined as module under Runo module.
  Border = Runo.uno_require('com.sun.star.sheet.Border')
  # Runo::Com::Sun::Star::Sheet::Border module is defined
  # you can access its members as constants of the module
      

