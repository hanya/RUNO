
#include "runo.hxx"

#include <cppuhelper/typeprovider.hxx>
#include <rtl/ustrbuf.hxx>

#include <com/sun/star/beans/MethodConcept.hpp>
#include <com/sun/star/reflection/ParamMode.hpp>
#include <com/sun/star/uno/TypeClass.hpp>
#include <com/sun/star/beans/XMaterialHolder.hpp>
#include <com/sun/star/beans/XIntrospectionAccess.hpp>

using com::sun::star::beans::UnknownPropertyException;
using com::sun::star::beans::XIntrospectionAccess;
using com::sun::star::beans::XMaterialHolder;
using com::sun::star::lang::IllegalArgumentException;
using com::sun::star::reflection::InvocationTargetException;
using com::sun::star::script::CannotConvertException;
using com::sun::star::uno::Any;
using com::sun::star::uno::RuntimeException;
using com::sun::star::uno::Sequence;
using com::sun::star::uno::Type;

using rtl::OUString;
using rtl::OUStringBuffer;
using namespace com::sun::star::uno;
using namespace com::sun::star::reflection;

namespace runo
{

ID
oustring2ID(const OUString &aName)
{
	return rb_intern(OUStringToOString(aName, RTL_TEXTENCODING_ASCII_US).getStr());
}

Adapter::Adapter(const VALUE &obj, const Sequence< Type > &types)
	: m_wrapped(obj), 
	m_types(types)
{
}

VALUE
Adapter::getWrapped()
{
	return m_wrapped;
}

Sequence< Type >
Adapter::getWrappedTypes()
{
	return m_types;
}

Adapter::~Adapter()
{
	Runtime runtime;
    Adapter *adapter = NULL;
    st_delete(runtime.getImpl()->map, &m_wrapped, (st_data_t *)adapter);
    adapter = NULL;
    VALUE a = get_class(ADAPTED_OBJECTS);
    rb_ary_delete(a, m_wrapped);
}


void
raiseUnoException(VALUE arg)
	throw (InvocationTargetException)
{
	VALUE exc = rb_gv_get("$!");
	
	if (rb_obj_is_kind_of(exc, get_exception_class()))
	{
		Any a;
		RunoInternal *runo;
		Data_Get_Struct(exc, RunoInternal, runo);
		Reference < XMaterialHolder > xHolder(runo->invocation, UNO_QUERY);
		if (xHolder.is())
			throw xHolder->getMaterial().getValue();
	}
}

VALUE
call_apply(VALUE argv)
{
	return rb_apply(rb_ary_entry(argv, 0), rb_intern_str(rb_ary_entry(argv, 1)), rb_ary_entry(argv, 2));
}


Sequence< sal_Int16 >
Adapter::getOutParamIndexes(const OUString &methodName)
{
	Sequence< sal_Int16 > ret;
	
	Runtime runtime;
	Reference< XInterface > adapter = runtime.getImpl()->xAdapterFactory->createAdapter(this, m_types);
	Reference< XIntrospectionAccess > introspection = runtime.getImpl()->xIntrospection->inspect(makeAny(adapter));
	
	if (! introspection.is())
	{
		throw RuntimeException(OUString(RTL_CONSTASCII_USTRINGPARAM("runo: failed to create adapter.")), Reference< XInterface >());
	}
	Reference< XIdlMethod > method = introspection->getMethod(methodName, com::sun::star::beans::MethodConcept::ALL);
	if (! method.is())
	{
		throw RuntimeException(OUString(RTL_CONSTASCII_USTRINGPARAM("runo: Failed to get reflection for ")) + methodName, Reference< XInterface >());
	}
	Sequence< ParamInfo > info = method->getParameterInfos();
	
	int out = 0;
	int i = 0;
	for (i = 0; i < info.getLength(); i++)
	{
		if (info[i].aMode == ParamMode_OUT || 
			info[i].aMode == ParamMode_INOUT)
			out++;
	}
	if (out)
	{
		sal_Int16 j = 0;
		ret.realloc(out);
		for (i = 0; i < info.getLength(); i++)
		{
			if (info[i].aMode == ParamMode_OUT || 
				info[i].aMode == ParamMode_INOUT)
			{
				ret[j] = i;
				j++;
			}
		}
	}
	return ret;
}


Reference< XIntrospectionAccess >
Adapter::getIntrospection()
	throw (RuntimeException)
{
	return Reference< XIntrospectionAccess >();
}


Any
Adapter::invoke(const OUString &  aFunctionName, const Sequence < Any > &aParams, Sequence < sal_Int16 > &aOutParamIndex, Sequence < Any > &aOutParam)
	throw (IllegalArgumentException, CannotConvertException, 
			InvocationTargetException, 	RuntimeException)
{
	if (aParams.getLength() == 1 && aFunctionName.compareToAscii("getSomething") == 0)
	{
		Sequence < sal_Int8 > id;
		if (aParams[0] >>= id)
			return makeAny(getSomething(id));
	}
	
	Any retAny;
	try
	{
		Runtime runtime;
		VALUE args = rb_ary_new2(aParams.getLength());
		for (int i = 0; i < aParams.getLength(); i++)
		{
			rb_ary_push(args, runtime.any_to_VALUE(aParams[i]));
		}
	
		VALUE argv = rb_ary_new2(3);
		rb_ary_push(argv, m_wrapped);
		rb_ary_push(argv, ustring2RString(aFunctionName));
		rb_ary_push(argv, args);
		VALUE ret = rb_rescue((VALUE(*)(...))call_apply, argv, (VALUE(*)(...))raiseUnoException, 0);
		
		//ID id = oustring2ID(aFunctionName);
		//VALUE ret = rb_apply(m_wrapped, id, args);
		Any retAny = runtime.value_to_any(ret);
		
		if (retAny.getValueTypeClass() == com::sun::star::uno::TypeClass_SEQUENCE && 
			aFunctionName.compareToAscii("getTypes") != 0 && 
			aFunctionName.compareToAscii("getImplementationId"))
		{
			aOutParamIndex = getOutParamIndexes(aFunctionName);
			if (aOutParamIndex.getLength())
			{
				Sequence< Any > seq;
				if (! (retAny >>= seq))
				{
					throw RuntimeException(OUString(RTL_CONSTASCII_USTRINGPARAM("runo: failed to extract out values for method ")) + aFunctionName, Reference< XInterface >());
				}
			
				if (! (seq.getLength() == aOutParamIndex.getLength() + 1))
				{
					throw RuntimeException(OUString( RTL_CONSTASCII_USTRINGPARAM("runo: illegal number of out values for method ")) + aFunctionName, Reference< XInterface >());
				}
			
				aOutParam.realloc(aOutParamIndex.getLength());
				retAny = seq[0];
				for (int i = 0; i < aOutParamIndex.getLength(); i++)
				{
					aOutParam[i] = seq[i + 1];
				}
			}
		}
	}
	catch (RuntimeException &e)
	{
		printf("%s\n", OUStringToOString(e.Message, RTL_TEXTENCODING_ASCII_US).getStr());
	}
	return retAny;
}

void
Adapter::setValue(const OUString &aPropertyName, const Any &aValue) 
	throw (UnknownPropertyException, CannotConvertException, 
			InvocationTargetException, RuntimeException)
{
	Runtime runtime;
	OUStringBuffer buf(aPropertyName);
	buf.appendAscii("=");
	rb_funcall(m_wrapped, oustring2ID(buf.makeStringAndClear()), 1, runtime.any_to_VALUE(aValue));
}

Any
Adapter::getValue(const OUString &aPropertyName)
	throw (UnknownPropertyException, RuntimeException)
{
	Runtime runtime;
	return runtime.value_to_any(rb_funcall(m_wrapped, oustring2ID(aPropertyName), 0));
}

sal_Bool
Adapter::hasMethod(const OUString &aName)
	throw (RuntimeException)
{
	if (rb_respond_to(m_wrapped, oustring2ID(aName)))
		return sal_True;
	return sal_False;
}
	
sal_Bool
Adapter::hasProperty(const OUString &aName)
	throw (RuntimeException)
{
	if (rb_respond_to(m_wrapped, oustring2ID(aName)))
		return sal_True;
	else
	{
		OUStringBuffer buf(aName);
		buf.appendAscii("=");
		if (rb_respond_to(m_wrapped, oustring2ID(buf.makeStringAndClear())))
			return sal_True;
	}
	return sal_False;
}

static cppu::OImplementationId g_Id(sal_False);

Sequence < sal_Int8 >
Adapter::getTunnelImpleId()
{
	return g_Id.getImplementationId();
}

sal_Int64
Adapter::getSomething(const Sequence < sal_Int8 > &aIdentifier)
		throw (RuntimeException)
{
	if (aIdentifier == g_Id.getImplementationId())
		return reinterpret_cast< sal_Int64 >(this);
	return 0;
}

}

