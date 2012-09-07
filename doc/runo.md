
# Basics

This article describes about basics to use the extension. 
The knowledge of UNO basic required to understand well.


## Contents

* [Import](#import)
* [Type Mappings](#type-mappings)
* [module `Uno`](#module-uno)
    * [`get_component_context`](#get_component_context)
    * [`system_path_to_file_url`](#system_path_to_file_url)
    * [`file_url_to_system_path`](#file_url_to_system_path)
    * [`absolutize`](#absolutize)
    * [`uuid`](#uuid)
    * [`require_uno`](#require_uno)
    * [`invoke`](#invoke)
* [class `RunoProxy`](#class-runoproxy)
* [class `RunoStruct`](#class-runostruct)
* [class `Uno::Com::Sun::Star::Uno::Exception`](#class-uno::com::sun::star::uno::exception)
* [class `Enum`](#class-enum)
* [class `Type`](#class-type)
* [class `Char`](#class-char)
* [class `Any`](#class-any)
* [class `ByteSequence`](#class-bytesequence)
* [module `Uno::Com::Sun::Star::Uno::XInterface`](#module-uno::com::sun::star::uno:xinterface)
* [module `Uno::UnoBase`](#module-uno::base)


## Import

Introduce `Uno` module as follows: 

    require 'uno'

This extension is separated into C extension and Ruby part, 
both use the same module as their namespace.

`Uno` module is used to keep some UNO values like module, interface and structs. 
Modules defined by UNO have name starting with lower case letter, but 
by the restriction of Ruby's constants, name of modules defined in `Uno` module that 
represents module of UNO, starting with upper letter case.

## Type Mappings

Here is value conversion mappings between UNO and Ruby: 

    UNO               Ruby Class
    --------------------------------------------------------
    void              NilClass
    boolean           TrueClass/FalseClass
    byte              Fixnum
    short             Fixnum
    unsigned short    Fixnum
    long              Fixnum/Bignum
    unsigned long     Fixnum/Bignum
    hyper             Fixnum/Bignum
    unsigned hyper    Fixnum/Bignum
    float             Float
    double            Float
    string            String 
    char              Uno::Char
    type              Uno::Type
    enum              Uno::Enum
    struct            Uno::RunoStruct (1)
    exception         Uno::Com::Sun::Star::Uno::Exception (1)
    interface         Uno::RunoProxy/object (2)
    sequence          Array
    []byte            Uno::ByteSequence

    - 1: New class is defined for each struct or exception at runtime, indicated class is used its base class.
    - 2: Interfaces coming from UNO is wrapped by `Uno::RunoProxy` class. Ruby objects having specific functions can be passed to UNO as object that implements UNO component.


## Uno `Module`

This top level module defines these module functions and some classes.


### `get_component_context`

    Uno.get_component_context  ->  Uno::RunoProxy

On IPC, call this function first before to do something with the extension. 
This function initialize the internal state and returns 
com.sun.star.lang.XComponentContext interface.


### `system_path_to_file_url`

    Uno.system_path_to_file_url(syspath)  ->  String

UNO uses URL as file specifire even the file is there on the local place. 
Use this function to convert system path to URL.

ArgumentError raises when passed value is not valid system path.


### `file_url_to_system_path`  ->  String

    Uno.file_url_to_system_path(url)  -> String

URL coming from UNO can be converted into system path if it starts 
`file` protocol. See RFC 1738 and other specification for valid URL.

ArgumentError raises when passed value is not valid URL.


### `absolutize`

    Uno.absolutize(base, relativepath)  ->  String

Make relative path absolute from base URL.

ArgumentError raises when any passed value is invalid.


### `uuid`

    Uno.uuid  ->  Array

Generates random UUID category 4. This result is used to generate 
implementation identifier for user defined components.


### `require_uno`

    Uno.require_uno(name1 [, name2, ...])  ->  Object | Array
    Uno.uno_require(name1 [, name2, ...])  ->  Object | Array

`uno_require` function would be removed, use `require_uno`.

Imports UNO value or generates dependent class for complicated value of UNO. 

Here is list of valid names and results:

* Struct  ->  Class
* Exception  ->  Class
* Interface  ->  Module
* Constants group  ->  Module
* Constant  ->  Float | Fixnum | Bignum
* Enum module  ->  Module
* Enum value  ->  Uno::Enum

Constants group and enum module is defined as `Module` instance and its fields are 
defined as its constants with their name.

See: [RunoStruct](#class-runostruct) and [XInterface](#xinterface).


### `invoke`

    Uno.invoke(proxy, name, args)  ->  Object | Array

Call `name` method on `proxy` with `args` as method arguments. This call does not 
call the method through `method_missing` function. Method like `inspect` conflict 
with instance method of Object class can be called.


## class `RunoProxy`

Instance of this class can not be initialized by the user, 
initialized internally and passed.

This class wrapps UNO interface. UNO method can be called on 
the instance by `method_missing` method.

By name conflictions between Ruby method and UNO method, 
some methods can not be called, use `invoke` function instead 
to call them.


### `==`

    self == other  ->  TrueClass/FalseClass

Compare self with other value.


### `inspect`

    inspect  ->  String

Returns string representation of the proxy.


### `uno_methods`

    uno_methods  ->  Array

Returns list of method names. Property, attribute, and generated pseud 
properties are converted to method. Assigning to the field is 
defined with `=` sign like an accessor of Ruby.

When called method has out parameters, return value of the method 
is being array of real return value and values for out parameters. 
Use multiple assignment to extract these values. Here is an example: 

    # IDL definition of the method: 
    # void methodFoo( [in] long a, [out] long b, [inout] long c )
    ret, b, c = obj.methodFoo(100, nil, 300)
    # ret is nil for void return value


### `has_interface?`

    has_interface?(name)  ->  TrueClass/FalseClass

Checks the object can react with specific set of methods, interface.


## class `RunoStruct`

This class represents base class for any struct and exception defined by UNO. 
This base class is unusable except for type checking purpose.

Call `require_uno` function to define required struct or exception first. 
After that, the class for requested struct is defined under `Uno` module. 
The module defined the class can be specified by its full qualified name. 
For example, com.sun.star.awt.Size struct is defined in 
`Uno::Com::Sun::Star::Awt` module with `Size` name after the request.

It can be initialized with initial values or without arguments. 
The order of arguments of the constructor depends on its definition in IDL. 
Specify fields for base class first.

    require_uno "com.sun.star.awt.Position"
    position = Uno::Com::Sun::Star::Awt::Position.new(100, 200)


### `==`

Compare with other. This does not check each fields.


### `method_missing`

Fields of the struct or exception can be get or set through this method. 


## class `Uno::Com::Sun::Star::Uno::Exception`

This class is base class for all UNO exceptions. Exceptions are the same structure 
with the structs, see [`RunoStruct`](#class-runostruct) too.


## class `Enum`

Represents individual enum value.

    new(typename, valuename)  ->  self

    italic = Uno::Enum.new("com.sun.star.awt.FontSlant", "ITALIC")


### `type_name`

Returns type name of the enum.


### `value`

Returns value name of the enum.


### `inspect`

Returns string representation of this instance.


## class `Type`

Represents type value of UNO.

    new(typename [, typeclass])  ->  self

Instantiate new instance of the class with its name specified by 
`typename`, it should be valid UNO type name.

Valid type names are name of primitive, struct, exception, 
interface, enum value, and these sequence.

The sequence of other value can be specified with `[]`. 
`[]long` is one dimensional sequence of `long`. 
`[][]com.sun.star.beans.PropertyValue` is two dimensional sequence.

    type = Uno::Type.new("[][]double")


### `type_name`

Returns type name represented by this instance.


### `type_class`

Returns type class represented by this instance.


### `inspect`

Returns string representation of this instance.


## class `Char`

Represents char value of UNO.

    new(char)  ->  self

`char` should be string with a character.

    c = Uno::Char.new("a")


### `==`

Compare with other.


### `value`

Returns wrapped character.


### `inspect`

Returns string representation of this instance.


## class `Any`

This class is used to tell direction of value conversion.

    new(type, value)  ->  self

When the instance is passed to UNO, `value` is tried to convert to 
`type`. `type` should be the name of type in `String` or 
`Uno::Type` instance. 
The conversion failes when the value can not be converted 
into specified type.

This is useful only on rare case failes value conversion. For example, 
a method defined to take `any` but it should be well typed. 
Well known situation is happen with 
`[]com.sun.star.beans.PropertyValue`.

    a = Uno::Any.new("[]com.sun.star.beans.PropertyValue", [])


### `==`

Compare with other.


### `type`

Returns type to convert.


### `value`

Returns wrapped value.


## class `ByteSequence`

This class is used to tell the value is converted as `[]byte` value. 
This class inherits `String` class.

No methods are added comparing the parent class.


## module `Uno::Com::Sun::Star::Uno::XInterface`

This module is used as parent module to define UNO interfaces as module. 
The module represents UNO interface can be used to mix-in to tell 
the class supports specific interface. 

Use this with `Uno::UnoBase` module.


## module `Uno::UnoBase`

This module helps to generate type information for user defined class 
to behave UNO component. This module provides methods defined in 
com.sun.star.lang.XTypeProvider and generates type information 
for the class according to its class and module inheritances.

    require_uno "com.sun.star.awt.XActionListener"
    
    class ActionListener
      include Uno::UnoBase
      include Uno::Com::Sun::Star::Awt::XActionListener
      
      def initialize
      end
      
      # method for parent interface of XActionListener
      # com.sun.star.lang.XEventListener
      def disposing(ev)
      end
      
      # com.sun.star.awt.XActionListener
      def actionPerformed(ev)
        # do something
      end
    end

When the method implemented has out or inout parameter, 
return array contains real return value and values for out/inout 
parameters. The real return value should be placed first position 
in the array.

