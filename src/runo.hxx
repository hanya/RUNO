/**************************************************************
 * Copyright 2011 Tsutomu Uchino
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 * 
 *************************************************************/

#ifndef _RUNO_HXX_
#define _RUNO_HXX_

#include "ruby.h"
#include <ruby/st.h>

#include <rtl/ustring.hxx>

#include <cppuhelper/implbase2.hxx>
#include <cppuhelper/weakref.hxx>

#include <com/sun/star/beans/XIntrospection.hpp>
#include <com/sun/star/container/XHierarchicalNameAccess.hpp>
#include <com/sun/star/lang/XSingleServiceFactory.hpp>
#include <com/sun/star/lang/XUnoTunnel.hpp>
#include <com/sun/star/reflection/InvocationTargetException.hpp>
#include <com/sun/star/reflection/XIdlReflection.hpp>
#include <com/sun/star/reflection/XTypeDescription.hpp>
#include <com/sun/star/script/XInvocation2.hpp>
#include <com/sun/star/script/XInvocationAdapterFactory2.hpp>
#include <com/sun/star/script/XTypeConverter.hpp>
#include <com/sun/star/uno/XComponentContext.hpp>

#ifdef WIN32
#  define RUNO_DLLEXPORT __declspec(dllexport)
#else
#  define RUNO_DLLEXPORT
#endif

#define UNO_TYPE_NAME "UNO_TYPE_NAME"
#define ADAPTED_OBJECTS "ADAPTED_OBJECTS"
#define UNO_PROXY "UnoProxy"
#define UNO_STRUCT "UnoStruct"
#define UNO_EXCEPTION "UnoException"
#define UNO_ERRROR "UnoError"
#define UNO_TYPES "UNO_TYPES"

#define UNO_MODULE "Uno"
#define ENUM_CLASS "Enum"
#define CHAR_CLASS "Char"
#define ANY_CLASS "Any"
#define TYPE_CLASS "Type"
#define BYTES_CLASS "Bytes"
#define CSS_MODULE "CSS"

#define OUSTRING_TO_ASCII(str)\
    OUStringToOString(str, RTL_TEXTENCODING_ASCII_US).getStr()

#define OUSTRING_CONST(str)\
    OUString(RTL_CONSTASCII_USTRINGPARAM(str))

namespace runo
{

/*
 * Wrappes UNO interface.
 */
typedef struct
{
    com::sun::star::uno::Reference < com::sun::star::script::XInvocation2 > invocation;
    com::sun::star::uno::Any wrapped;
} RunoInternal;

typedef struct
{
    com::sun::star::uno::Any value;
} RunoValue;


/* string.cxx */
::rtl::OUString asciiVALUE2OUString(VALUE str);
VALUE asciiOUString2VALUE(const ::rtl::OUString &str);

VALUE ustring2RString(const ::rtl::OUString &str);
::rtl::OUString rbString2OUString(VALUE rbstr);

VALUE bytes2VALUE(const com::sun::star::uno::Sequence< sal_Int8 > &bytes);

void init_external_encoding(void);
//void set_external_encoding(void);

/* types.cxx */
/* Get class from Ruby runtime. */
VALUE get_class(const char *name);
VALUE get_uno_module(void);
VALUE get_proxy_class(void);
VALUE get_enum_class(void);
VALUE get_type_class(void);
VALUE get_char_class(void);
VALUE get_struct_class(void);
VALUE get_exception_class(void);
VALUE get_any_class(void);
VALUE get_bytes_class(void);
VALUE get_interface_class(void);
VALUE get_css_uno_exception_class(void);
VALUE get_uno_error_class(void);

VALUE find_interface(const com::sun::star::uno::Reference< com::sun::star::reflection::XTypeDescription > &xTd);

VALUE new_runo_proxy(const com::sun::star::uno::Any &object, const com::sun::star::uno::Reference< com::sun::star::lang::XSingleServiceFactory > &xFactory, VALUE klass);
VALUE new_runo_object(const com::sun::star::uno::Any &a, const com::sun::star::uno::Reference< com::sun::star::lang::XSingleServiceFactory > &xFactory);

void set_runo_struct(const com::sun::star::uno::Any &object, const com::sun::star::uno::Reference< com::sun::star::lang::XSingleServiceFactory > &xFactory, VALUE &self);


/* define module according to UNO module name. */
VALUE create_module(const ::rtl::OUString &name);
/* find struct or exception class, class is created if not found */
VALUE find_class(const ::rtl::OUString &name, typelib_TypeClass typeClass);

VALUE runo_new_type(const rtl::OUString &typeName, const VALUE &type_class);
VALUE runo_new_enum(const rtl::OUString &typeName, const rtl::OUString &value);

void raise_rb_exception(const com::sun::star::uno::Any &a);

rtl::OUString valueToOUString(const void *pVal, typelib_TypeDescriptionReference *pTypeRef);


/*
 * Keeps runtime environment.
 */
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
    st_table *map;
    ID getTypesID;
} RuntimeImpl;


class RUNO_DLLEXPORT Runtime
{
    RuntimeImpl *imple;
public:
    
    Runtime() throw(com::sun::star::uno::RuntimeException);
    
    ~Runtime();
    
    static void initialize(const com::sun::star::uno::Reference < com::sun::star::uno::XComponentContext > &ctx) throw (com::sun::star::uno::RuntimeException);
    static bool isInitialized() throw (com::sun::star::uno::RuntimeException);
    RuntimeImpl * getImpl() const {return imple;}
    
    VALUE any_to_VALUE(const com::sun::star::uno::Any &a) const throw (com::sun::star::uno::RuntimeException);
    com::sun::star::uno::Any value_to_any(VALUE value) const throw (com::sun::star::uno::RuntimeException);
    //com::sun::star::uno::Sequence< com::sun::star::uno::Type > getTypes(VALUE &value) const;
};


class RUNO_DLLEXPORT Adapter : public cppu::WeakImplHelper2 < com::sun::star::script::XInvocation, com::sun::star::lang::XUnoTunnel >
{
    VALUE m_wrapped;
    com::sun::star::uno::Sequence< com::sun::star::uno::Type > m_types;
    
    com::sun::star::uno::Sequence< sal_Int16 > getOutParamIndexes(const rtl::OUString &methodName);
    
public:
    Adapter(const VALUE &obj, const com::sun::star::uno::Sequence< com::sun::star::uno::Type > &types);
    
    virtual ~Adapter();
    
    static com::sun::star::uno::Sequence< sal_Int8 > getTunnelImpleId();
    VALUE getWrapped() const { return m_wrapped; };
    com::sun::star::uno::Sequence< com::sun::star::uno::Type > getWrappedTypes() const { return m_types; };
    
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
