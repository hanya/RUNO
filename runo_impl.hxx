
#ifndef _RUNO_IMPL_HXX_
#define _RUNO_IMPL_HXX_ 1

#include "ruby.h"

#include <stl/hash_map>

#include <rtl/ustring.hxx>

#include <cppuhelper/implbase2.hxx>
#include <cppuhelper/weakref.hxx>

#include <com/sun/star/beans/UnknownPropertyException.hpp>
#include <com/sun/star/beans/XIntrospection.hpp>
#include <com/sun/star/container/XHierarchicalNameAccess.hpp>
#include <com/sun/star/lang/IllegalArgumentException.hpp>
#include <com/sun/star/lang/XSingleServiceFactory.hpp>
#include <com/sun/star/lang/XUnoTunnel.hpp>
#include <com/sun/star/reflection/InvocationTargetException.hpp>
#include <com/sun/star/reflection/XIdlReflection.hpp>
#include <com/sun/star/script/CannotConvertException.hpp>
#include <com/sun/star/script/XInvocation2.hpp>
#include <com/sun/star/script/XTypeConverter.hpp>
#include <com/sun/star/uno/Any.hxx>
#include <com/sun/star/uno/RuntimeException.hpp>
#include <com/sun/star/uno/XComponentContext.hpp>
#include <com/sun/star/reflection/XTypeDescription.hpp>
#include <com/sun/star/script/XInvocationAdapterFactory2.hpp>


namespace runo
{

/*
 * Wrapping enum, any, types and so on.
 */
typedef struct
{
	com::sun::star::uno::Any value;
} RunoValue;

/*
 * Wrappes UNO interface.
 */
typedef struct
{
	com::sun::star::uno::Reference < com::sun::star::script::XInvocation2 > invocation;
	com::sun::star::uno::Any wrapped;
} RunoInternal;


/* OUString <-> VALUE (String) conversion */
VALUE ustring2RString(const ::rtl::OUString &str);
::rtl::OUString rbString2OUString(VALUE str);

::rtl::OUString asciiVALUE2OUString(VALUE str);
VALUE asciiOUString2VALUE(const ::rtl::OUString &str);

VALUE bytes2VALUE(const com::sun::star::uno::Sequence< sal_Int8 > &bytes);

void init_external_encoding();
void set_external_encoding();

/* Get class from Ruby runtime. */
VALUE get_module_class(void);
VALUE get_proxy_class(void);
VALUE get_enum_class(void);
VALUE get_type_class(void);
VALUE get_char_class(void);
VALUE get_struct_class(void);
VALUE get_exception_class(void);
VALUE get_any_class(void);
VALUE get_bytes_class(void);
VALUE get_interface_class(void);

/* define module according to UNO module name. */
VALUE create_module(rtl::OUString name);
VALUE find_interface(com::sun::star::uno::Reference< com::sun::star::reflection::XTypeDescription > &xTd);
/* find struct or exception class, class is created if not found */
VALUE find_class(rtl::OUString name, typelib_TypeClass typeClass);
/* raise exception as Ruby exception with original exception */
void raise_rb_exception(const com::sun::star::uno::Any &a);


/* create new instance of RunoProxy for interface type. */
VALUE new_runo_object(const com::sun::star::uno::Any &a, const com::sun::star::uno::Reference < com::sun::star::lang::XSingleServiceFactory > &xFactory);
/* for general type like interface, struct and exception. */
VALUE new_runo_proxy(const com::sun::star::uno::Any &a, const com::sun::star::uno::Reference < com::sun::star::lang::XSingleServiceFactory > &xFactory, VALUE klass);
/* put and wrap the UNO struct to RunoInternal struct. */
void set_runo_struct(const com::sun::star::uno::Any &object, const com::sun::star::uno::Reference< com::sun::star::lang::XSingleServiceFactory > &xFactory, VALUE &self);


struct VALUE_hash {
	/* size_t operator()(const VALUE &v) const {
		return static_cast< size_t >;
	}
	*/
	sal_IntPtr operator()(const VALUE &v) const
	{
		return sal_IntPtr(v);
	}
};

typedef ::std::hash_map
<
	VALUE, 
	com::sun::star::uno::WeakReference< com::sun::star::script::XInvocation >, 
	VALUE_hash, 
	std::equal_to< VALUE >
> AdapterMap;

/* keeps runtime environment. */
typedef struct RuntimeImpl
{
	com::sun::star::uno::Reference < com::sun::star::uno::XComponentContext > xComponentContext;
	com::sun::star::uno::Reference < com::sun::star::lang::XSingleServiceFactory>  xInvocation;
	com::sun::star::uno::Reference < com::sun::star::script::XTypeConverter > xTypeConverter;
	com::sun::star::uno::Reference < com::sun::star::reflection::XIdlReflection > xCoreReflection;
	com::sun::star::uno::Reference < com::sun::star::container::XHierarchicalNameAccess > xTypeDescription;
	com::sun::star::uno::Reference < com::sun::star::script::XInvocationAdapterFactory2 > xAdapterFactory;
	com::sun::star::uno::Reference < com::sun::star::beans::XIntrospection > xIntrospection;
	bool valid;
	AdapterMap adapterMap;
} RuntimeImpl;


class Runtime
{
	RuntimeImpl *impl;
public:
	
	Runtime() throw(com::sun::star::uno::RuntimeException);
	
	~Runtime();
	
	static void initialize(const com::sun::star::uno::Reference < com::sun::star::uno::XComponentContext > & ctx) throw (com::sun::star::uno::RuntimeException);
	static bool isInitialized() throw (com::sun::star::uno::RuntimeException);
	RuntimeImpl *getImpl() const {return impl;}
	
	VALUE any_to_VALUE(const com::sun::star::uno::Any &a) const throw (com::sun::star::uno::RuntimeException);
	com::sun::star::uno::Any value_to_any(VALUE value) const;
};


class Adapter : public cppu::WeakImplHelper2 < com::sun::star::script::XInvocation, com::sun::star::lang::XUnoTunnel >
{
	VALUE m_wrapped;
	com::sun::star::uno::Sequence< com::sun::star::uno::Type > m_types;
	
	com::sun::star::uno::Sequence< sal_Int16 > getOutParamIndexes(const rtl::OUString &methodName);
	
public:
	Adapter(const VALUE &obj, const com::sun::star::uno::Sequence< com::sun::star::uno::Type > &types);
	
	virtual ~Adapter();
	
	static com::sun::star::uno::Sequence< sal_Int8 > getTunnelImplId();
	VALUE getWrapped();
	com::sun::star::uno::Sequence< com::sun::star::uno::Type > getWrappedTypes();
	
	virtual com::sun::star::uno::Reference < com::sun::star::beans::XIntrospectionAccess > SAL_CALL getIntrospection() throw (com::sun::star::uno::RuntimeException);
	
	virtual com::sun::star::uno::Any SAL_CALL invoke(
		const rtl::OUString &  aFunctionName, 
		const com::sun::star::uno::Sequence < com::sun::star::uno::Any > &aParams, 
		com::sun::star::uno::Sequence < sal_Int16 > &aOutParamIndex, 
		com::sun::star::uno::Sequence < com::sun::star::uno::Any > &aOutParam)
		throw (
			com::sun::star::lang::IllegalArgumentException, 
			com::sun::star::script::CannotConvertException, 
			com::sun::star::reflection::InvocationTargetException, 
			com::sun::star::uno::RuntimeException);
	
	virtual void SAL_CALL setValue(
		const rtl::OUString &aPropertyName, 
		const com::sun::star::uno::Any &aValue) 
		throw (
			com::sun::star::beans::UnknownPropertyException, 
			com::sun::star::script::CannotConvertException, 
			com::sun::star::reflection::InvocationTargetException, 
			com::sun::star::uno::RuntimeException);
	
	virtual com::sun::star::uno::Any SAL_CALL getValue(
		const rtl::OUString &aPropertyName)
		throw (
			com::sun::star::beans::UnknownPropertyException, 
			com::sun::star::uno::RuntimeException);
		
	virtual sal_Bool SAL_CALL hasMethod(
		const rtl::OUString &aName)
		throw (
			com::sun::star::uno::RuntimeException);
	
	virtual sal_Bool SAL_CALL hasProperty(
		const rtl::OUString &aName)
		throw (
			com::sun::star::uno::RuntimeException);
	
	virtual sal_Int64 SAL_CALL getSomething(
		const com::sun::star::uno::Sequence < sal_Int8 > &aIdentifier)
		throw (
			com::sun::star::uno::RuntimeException);

};


}

#endif

