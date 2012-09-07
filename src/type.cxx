
#include "runo.hxx"

#include <osl/thread.h>
#include <rtl/ustrbuf.hxx>
#include <typelib/typedescription.hxx>

#include <com/sun/star/reflection/XInterfaceTypeDescription2.hpp>

using com::sun::star::lang::XSingleServiceFactory;
using com::sun::star::reflection::XInterfaceTypeDescription2;
using com::sun::star::reflection::XTypeDescription;
using com::sun::star::script::XInvocation2;
using com::sun::star::uno::Any;
using com::sun::star::uno::Reference;
using com::sun::star::uno::RuntimeException;
using com::sun::star::uno::Sequence;
using com::sun::star::uno::TypeDescription;
using com::sun::star::uno::UNO_QUERY;
using com::sun::star::uno::XInterface;

using rtl::OUString;
using rtl::OUStringToOString;
using rtl::OUStringBuffer;

namespace runo
{

VALUE
get_module_class()
{
	return rb_const_get(rb_cObject, rb_intern("Uno"));
	ID id;
	id = rb_intern("Uno");
	if (rb_const_defined(rb_cObject, id))
		return rb_const_get(rb_cObject, id);
	rb_raise(rb_eRuntimeError, "module undefined (Uno)");
}

VALUE
get_class(const char *name)
{
	VALUE module;
	ID id;
	id = rb_intern(name);
	
	module = get_module_class();
	if (rb_const_defined(module, id))
		return rb_const_get(module, id);
	rb_raise(rb_eRuntimeError, "class undefined (%s)", RSTRING_PTR(&name));
}


VALUE
get_proxy_class()
{
	return get_class("RunoProxy");
}

VALUE
get_enum_class()
{
	return get_class("Enum");
}

VALUE
get_type_class()
{
	return get_class("Type");
}

VALUE
get_char_class()
{
	return get_class("Char");
}

VALUE
get_any_class()
{
	return get_class("Any");
}

VALUE
get_bytes_class()
{
	return get_class("ByteSequence");
}

VALUE
get_interface_class()
{
	ID id;
	VALUE module = get_module_class();
	id = rb_intern("Com");
	if (!rb_const_defined(module, id))
		rb_raise(rb_eRuntimeError, "unknown error (Uno::Com)");
	VALUE com_module = rb_const_get(module, id);
	id = rb_intern("Sun");
	if (!rb_const_defined(com_module, id))
		rb_raise(rb_eRuntimeError, "unknown error (Uno::Com::Sun)");
	VALUE sun_module = rb_const_get(com_module, id);
	id = rb_intern("Star");
	if (!rb_const_defined(sun_module, id))
		rb_raise(rb_eRuntimeError, "unknown error (Uno::Com::Sun::Star)");
	VALUE star_module = rb_const_get(sun_module, id);
	id = rb_intern("Uno");
	if (!rb_const_defined(star_module, id))
		rb_raise(rb_eRuntimeError, "unknown error (Uno::Com::Sun::Star::Uno)");
	VALUE uno_module = rb_const_get(star_module, id);
	id = rb_intern("XInterface");
	if (!rb_const_defined(uno_module, id))
		rb_raise(rb_eRuntimeError, "unknown error (Uno::Com::Sun::Star::Uno::XInterface)");
	return rb_const_get(uno_module, id);
}

VALUE
get_struct_class()
{
	return get_class("RunoStruct");
}

VALUE
get_exception_class()
{
	ID id;
	VALUE module = get_module_class();
	id = rb_intern("Com");
	if (!rb_const_defined(module, id))
		rb_raise(rb_eRuntimeError, "unknown error (Uno::Com)");
	VALUE com_module = rb_const_get(module, id);
	id = rb_intern("Sun");
	if (!rb_const_defined(com_module, id))
		rb_raise(rb_eRuntimeError, "unknown error (Uno::Com::Sun)");
	VALUE sun_module = rb_const_get(com_module, id);
	id = rb_intern("Star");
	if (!rb_const_defined(sun_module, id))
		rb_raise(rb_eRuntimeError, "unknown error (Uno::Com::Sun::Star)");
	VALUE star_module = rb_const_get(sun_module, id);
	id = rb_intern("Uno");
	if (!rb_const_defined(star_module, id))
		rb_raise(rb_eRuntimeError, "unknown error (Uno::Com::Sun::Star::Uno)");
	VALUE uno_module = rb_const_get(star_module, id);
	id = rb_intern("Exception");
	if (!rb_const_defined(uno_module, id))
		rb_raise(rb_eRuntimeError, "unknown error (Uno::Com::Sun::Star::Uno::Exception)");
	return rb_const_get(uno_module, id);
}

VALUE
new_Type(VALUE type_name, VALUE type_class)
{
	return rb_funcall(get_enum_class(), rb_intern("new"), type_name, type_class);
}

VALUE
new_Char(VALUE character)
{
	VALUE char_class = get_char_class();
	return rb_funcall(char_class, rb_intern("new"), character);
}


VALUE
new_runo_object(const Any &a, const Reference< XSingleServiceFactory > &xFactory)
{
	Reference< XInterface > tmp_interface;
	a >>= tmp_interface;
	if (!tmp_interface.is())
		return Qnil;
	return new_runo_proxy(a, xFactory, get_proxy_class());
}

VALUE
new_runo_proxy(const Any &object, const Reference< XSingleServiceFactory > &xFactory, VALUE klass)
{
	Sequence< Any > arguments(1);
	arguments[0] <<= object;
	Reference< XInvocation2 > xinvocation(xFactory->createInstanceWithArguments(arguments), UNO_QUERY);
	
	VALUE obj;
	RunoInternal *runo;
	runo = new RunoInternal();
	obj = rb_obj_alloc(klass);
	DATA_PTR(obj) = runo;
	
	runo->wrapped = object;
	runo->invocation = xinvocation;
	return obj;
}

void
set_runo_struct(const Any &object, const Reference< XSingleServiceFactory > &xFactory, VALUE &self)
{
	Sequence< Any > arguments(1);
	arguments[0] <<= object;
	
	Reference< XInvocation2 > xinvocation(xFactory->createInstanceWithArguments(arguments), UNO_QUERY);
	
	RunoInternal *runo;
	Data_Get_Struct(self, RunoInternal, runo);
	
	runo->wrapped = object;
	runo->invocation = xinvocation;
}


/*
 * Create or get modules according to name.
 */
VALUE
create_module(const OUString &name)
{
	VALUE parent;
	parent = get_module_class();
	
	ID id;
	sal_Int32 ends, pos, tmp;
	char *s;
	OUStringBuffer buf;
	ends = name.lastIndexOfAsciiL(".", 1);
	if (!(ends > 1))
		rb_raise(rb_eArgError, "invalid name(%s)", 
		OUStringToOString(name, osl_getThreadTextEncoding()).getStr());
	tmp = 0;
	pos = name.indexOfAsciiL(".", 1, 0);
	OUString tmpName = name.copy(ends + 1);
	if (tmpName.getLength() < 1)
		rb_raise(rb_eRuntimeError, "invalid name (%s)", 
		OUStringToOString(tmpName, osl_getThreadTextEncoding()).getStr());
	
	while (pos < ends)
	{
		pos = name.indexOfAsciiL(".", 1, tmp);
		
		buf.append(name.copy(tmp, 1).toAsciiUpperCase()).append(name.copy(tmp +1, pos - tmp -1));
		s = (char*)(OUStringToOString(buf.makeStringAndClear(), RTL_TEXTENCODING_ASCII_US).getStr());
		
		id = rb_intern(s);
		if (rb_const_defined(parent, id))
			parent = rb_const_get(parent, id);
		else
			parent = rb_define_module_under(parent, s);
		
		tmp = pos + 1;
	}
	return parent;
}


/*
 * Find and define class (for structs and exceptions) or module (for interfaces).
 */
VALUE
find_class(const OUString &name, const typelib_TypeClass &typeClass)
{
	ID id;
	VALUE module;
	sal_Int32 ends;
	char *className;
	
	module = create_module(name);
	ends = name.lastIndexOfAsciiL(".", 1);
	className = (char*) OUStringToOString(
					name.copy(ends + 1), RTL_TEXTENCODING_ASCII_US).getStr();
	id = rb_intern(className);
	if (rb_const_defined(module, id))
	{
		return rb_const_get(module, id);
	}
	VALUE klass;
	
	if (typeClass == typelib_TypeClass_STRUCT)
	{
		klass = rb_define_class_under(module, className, get_struct_class());
	}
	else if (typeClass == typelib_TypeClass_EXCEPTION)
	{
		 klass = rb_define_class_under(module, className, get_exception_class());
	}
	else if (typeClass == typelib_TypeClass_INTERFACE)
	{
		klass = rb_define_module_under(module, className);
	}
	else
	{
		rb_raise(rb_eArgError, "unsupported type (%s)", className);
	}
	rb_define_const(klass, UNO_TYPE_NAME, asciiOUString2VALUE(name));
	return klass;
}


/*
 * Define interface module.
 */
VALUE
find_interface(const Reference< XTypeDescription > &xTd)
{
	OUString name = xTd->getName();
	
	VALUE module = find_class(name, (typelib_TypeClass)xTd->getTypeClass());
	
	Reference< XInterfaceTypeDescription2 > xInterfaceTd(xTd, UNO_QUERY);
	Sequence< Reference< XTypeDescription > > xBaseTypes = xInterfaceTd->getBaseTypes();
	Sequence< Reference< XTypeDescription>  > xOptionalTypes = xInterfaceTd->getOptionalBaseTypes();
	
	VALUE parent;
	for (int i = 0; i < xBaseTypes.getLength(); i++)
	{
		parent = find_interface(xBaseTypes[i]);
		if (! NIL_P(parent))
			rb_include_module(module, parent);
	}
	for (int i = 0; i < xOptionalTypes.getLength(); i++)
	{
		parent = find_interface(xBaseTypes[i]);
		if (! NIL_P(parent))
			rb_include_module(module, parent);
	}
	return module;
}

void
raise_rb_exception(const Any &a)
{
	try
	{
		com::sun::star::uno::Exception e;
		a >>= e;
		
		VALUE module, klass;
		Runtime runtime;
		
		OUString typeName = a.getValueTypeName();
		module = create_module(typeName);
		
		klass = find_class(typeName, (typelib_TypeClass)a.getValueTypeClass());
		
		rb_raise(klass, "%s", OUStringToOString(e.Message, RTL_TEXTENCODING_ASCII_US).getStr());
	}
	catch (com::sun::star::lang::IllegalArgumentException &e)
	{
		rb_raise(rb_eRuntimeError, "illegal argument exception at exception conversion.");
	}
	catch (com::sun::star::script::CannotConvertException &e)
	{
		rb_raise(rb_eRuntimeError, "error at exception conversion.");
	}
	catch (RuntimeException &e)
	{
		rb_raise(rb_eRuntimeError, "runtime exception at exception conversion.");
	}
}


}

