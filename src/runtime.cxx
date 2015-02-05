
#include "runo.hxx"

#include <osl/thread.h>
#include <typelib/typedescription.hxx>

#include <com/sun/star/reflection/XEnumTypeDescription.hpp>
#include <com/sun/star/beans/XMaterialHolder.hpp>

using com::sun::star::script::XInvocationAdapterFactory2;
using com::sun::star::beans::XIntrospection;
using com::sun::star::beans::XMaterialHolder;
using com::sun::star::lang::XSingleServiceFactory;
using com::sun::star::reflection::XIdlReflection;
using com::sun::star::script::XInvocation;
using com::sun::star::script::XTypeConverter;

using rtl::OString;
using rtl::OUString;
using rtl::OUStringToOString;

using namespace com::sun::star::uno;

namespace runo
{

static RuntimeImpl *gImpl;

bool Runtime::isInitialized() throw (RuntimeException)
{
    if (gImpl)
        return gImpl->valid;
    return false;
}


Runtime::Runtime() throw (RuntimeException)
{
    imple = gImpl;
}


Runtime::~Runtime()
{
    imple = NULL;
}


static int 
valuecmp(const int a, const int b)
{
    return a != b;
}


static st_index_t 
valuehash(const int n)
{
    return n;
}


static struct st_hash_type adapter_hash = {
    (int(*)(...))valuecmp, 
    (st_index_t(*)(...))valuehash
};


void Runtime::initialize(const Reference< XComponentContext > &ctx) throw (RuntimeException)
{
    if (gImpl)
    {
        throw RuntimeException(OUString(RTL_CONSTASCII_USTRINGPARAM("runo runtime is already initialized.")), Reference< XInterface >());
    }
    gImpl = new RuntimeImpl();
    
    gImpl->xComponentContext = ctx;
    
    gImpl->xInvocation = Reference < XSingleServiceFactory > (
            ctx->getServiceManager()->createInstanceWithContext(
                OUString(RTL_CONSTASCII_USTRINGPARAM("com.sun.star.script.Invocation")), 
                ctx), UNO_QUERY);
    
    if (!gImpl->xInvocation.is())
    {
        throw RuntimeException(
            OUString(RTL_CONSTASCII_USTRINGPARAM("runo: failed to instantiate com.sun.star.script.Invocation.")), Reference< XInterface >());
    }
    gImpl->xIntrospection = Reference < XIntrospection > (
            ctx->getServiceManager()->createInstanceWithContext(
                OUString(RTL_CONSTASCII_USTRINGPARAM("com.sun.star.beans.Introspection")), 
                ctx), UNO_QUERY);
    if (!gImpl->xIntrospection.is())
    {
        throw RuntimeException(
            OUString(RTL_CONSTASCII_USTRINGPARAM("runo: failed to instantiate com.sun.star.beans.Instrospection")), Reference< XInterface >());
    }
    gImpl->xCoreReflection = Reference < XIdlReflection > (
            ctx->getServiceManager()->createInstanceWithContext(
                OUString(RTL_CONSTASCII_USTRINGPARAM("com.sun.star.reflection.CoreReflection")), 
                ctx), UNO_QUERY);
    if (!gImpl->xCoreReflection.is())
    {
        throw RuntimeException(
            OUString(RTL_CONSTASCII_USTRINGPARAM("runo: failfed to instantiate com.sun.star.reflection.CoreReflection.")), Reference< XInterface >());
    }
    gImpl->xTypeConverter = Reference < XTypeConverter > (
            ctx->getServiceManager()->createInstanceWithContext(
                OUString(RTL_CONSTASCII_USTRINGPARAM("com.sun.star.script.Converter")), 
                ctx), UNO_QUERY);
    if (!gImpl->xTypeConverter.is())
    {
        throw RuntimeException(
            OUString(RTL_CONSTASCII_USTRINGPARAM("runo: failfed to instantiate com.sun.star.script.Converter.")), Reference< XInterface >());
    }
    gImpl->xAdapterFactory = Reference < XInvocationAdapterFactory2 > (
            ctx->getServiceManager()->createInstanceWithContext(
                OUString(RTL_CONSTASCII_USTRINGPARAM("com.sun.star.script.InvocationAdapterFactory")), 
                ctx), UNO_QUERY);
    if (!gImpl->xTypeConverter.is())
    {
        throw RuntimeException(
            OUString(RTL_CONSTASCII_USTRINGPARAM("runo: failed to instantiate com.sun.star.script.InvocationAdapterFactory.")), Reference< XInterface >());
    }
    Any tdm = ctx->getValueByName(
            OUString(RTL_CONSTASCII_USTRINGPARAM("/singletons/com.sun.star.reflection.theTypeDescriptionManager")));
    tdm >>= gImpl->xTypeDescription;
    if (! gImpl->xTypeDescription.is())
    {
        throw RuntimeException(
            OUString(RTL_CONSTASCII_USTRINGPARAM("runo: failed to get /singletons/com.sun.star.reflection.theTypeDescriptionManager.")), Reference< XInterface >());
    }
    gImpl->valid = true;
    
    gImpl->map = st_init_table(&adapter_hash);
    gImpl->getTypesID = rb_intern("getTypes");
}


static Sequence< Type >
getTypes(const Runtime &runtime, VALUE *value)
{
    Sequence< Type > ret;
    
    if (! rb_respond_to(*value, runtime.getImpl()->getTypesID))
        rb_raise(rb_eArgError, "illegal argument does not support com.sun.star.lang.XTypeProvider interface", NULL);
    VALUE types = rb_funcall(*value, runtime.getImpl()->getTypesID, 0);
    
    const long size = RARRAY_LEN(types);
    if (size > 0)
    {
        ret.realloc(size + 1);
        for (long i = 0; i < size; i++)
        {
            Any a = runtime.value_to_any(rb_ary_entry(types, i));
            a >>= ret[i];
        }
        ret[size] = getCppuType((Reference< com::sun::star::lang::XUnoTunnel > *)0);
    }
    return ret;
}


/*
 * Convert UNO Any to Ruby VALUE.
 */
VALUE Runtime::any_to_VALUE(const Any &a) const throw (RuntimeException)
{
    switch (a.getValueTypeClass())
    {
    case typelib_TypeClass_BOOLEAN:
        {
            sal_Bool b = sal_Bool();
            if ((a >>= b) && b)
            {
                return Qtrue;
            } else {
                return Qfalse;
            }
        }
    case typelib_TypeClass_BYTE:
    case typelib_TypeClass_SHORT:
    case typelib_TypeClass_UNSIGNED_SHORT:
        {
            sal_Int32 l = 0;
            a >>= l;
            return INT2FIX(l);
        }
    case typelib_TypeClass_LONG:
    case typelib_TypeClass_UNSIGNED_LONG:
    case typelib_TypeClass_HYPER:
    case typelib_TypeClass_UNSIGNED_HYPER:
        {
            sal_Int64 l = 0;
            a >>= l;
            return INT2NUM(l);
        }
    case typelib_TypeClass_FLOAT:
        {
            float f;
            a >>= f;
#ifdef DBL2NUM
            return DBL2NUM(f);
#else
            NEWOBJ(flt, struct RFloat);
            OBJSETUP(flt, rb_cFloat, T_FLOAT);

            flt->value = f;
            return (VALUE)flt;
#endif
        }
    case typelib_TypeClass_DOUBLE:
        {
            double d;
            a >>= d;
#ifdef DBL2NUM
            return DBL2NUM(d);
#else
            NEWOBJ(flt, struct RFloat);
            OBJSETUP(flt, rb_cFloat, T_FLOAT);

            flt->value = d;
            return (VALUE)flt;
#endif

        }
    case typelib_TypeClass_STRING:
        {
            OUString s;
            a >>= s;
            return ustring2RString(s);
        }
    case typelib_TypeClass_ENUM:
        {
            sal_Int32 v = *(sal_Int32 *) a.getValue();
            TypeDescription desc(a.getValueType());
            if (desc.is())
            {
                desc.makeComplete();
                typelib_EnumTypeDescription * pEnumDesc = (typelib_EnumTypeDescription *) desc.get();
                for (int i = 0; i < pEnumDesc->nEnumValues; i++)
                {
                    if (pEnumDesc->pEnumValues[i] == v)
                    {
                        OUString typeName = pEnumDesc->aBase.pTypeName;
                        OUString valueName = pEnumDesc->ppEnumNames[i];
                        
                        VALUE type_name = ustring2RString(typeName);
                        VALUE value_name = ustring2RString(valueName);
                        VALUE enumValue = rb_funcall(get_enum_class(), rb_intern("new"), 2, type_name, value_name);
                        return enumValue;
                    }
                }
            }
            throw RuntimeException(OUString(RTL_CONSTASCII_USTRINGPARAM("illegal enum")), Reference< XInterface >());
        }
    case typelib_TypeClass_STRUCT:
    case typelib_TypeClass_EXCEPTION:
        {
            VALUE klass;
            Runtime runtime;
            klass = find_class(a.getValueTypeName(), (typelib_TypeClass)a.getValueTypeClass());
            if (NIL_P(klass))
                rb_raise(rb_eRuntimeError, "failed to create class (%s)", OUStringToOString(a.getValueTypeName(), RTL_TEXTENCODING_ASCII_US).getStr());
            
            return new_runo_proxy(a, runtime.getImpl()->xInvocation, klass);
        }
    case typelib_TypeClass_SEQUENCE:
        {
            Sequence< Any > s;
            
            TypeDescription desc(OUString(RTL_CONSTASCII_USTRINGPARAM("[]byte")));
            if (a.getValueTypeRef()->pType == desc.get())
            {
                Sequence< sal_Int8 > bytes;
                a >>= bytes;
                VALUE klass = get_bytes_class();
                return rb_funcall(klass, rb_intern("new"), 1, bytes2VALUE(bytes));
            }
            else
            {
                Reference< XTypeConverter > tc = getImpl()->xTypeConverter;
                tc->convertTo(a, ::getCppuType(&s)) >>= s;
                VALUE ary = Qnil;
                ary = rb_ary_new2(s.getLength());
                int i = 0;
                try{
                    for (i = 0; i < s.getLength(); i++)
                    {
                        rb_ary_push(ary, any_to_VALUE(tc->convertTo(s[i], s[i].getValueType())));
                    }
                }
                catch (com::sun::star::uno::Exception &e)
                {
                    for (; i < s.getLength(); i++)
                    {
                        rb_ary_push(ary, Qnil);
                    }
                }
                return ary;
            }
        }
    case typelib_TypeClass_INTERFACE:
        {
            Reference< com::sun::star::lang::XUnoTunnel > xUnoTunnel;
            a >>= xUnoTunnel;
            if (xUnoTunnel.is())
            {
                sal_Int64 nAddr = xUnoTunnel->getSomething(Adapter::getTunnelImpleId());
                if (nAddr)
                {
                    Adapter *pAdapter = (Adapter *)sal::static_int_cast< sal_IntPtr >(nAddr);
                    if (pAdapter != NULL)
                    {
                        return pAdapter->getWrapped();
                    }
                }
            }
            return new_runo_object(a, getImpl()->xInvocation);
        }
    case typelib_TypeClass_TYPE:
        {
            Type t;
            a >>= t;
            OString o = OUStringToOString(t.getTypeName(), RTL_TEXTENCODING_ASCII_US);
            VALUE type_class = any_to_VALUE(Any((com::sun::star::uno::TypeClass)t.getTypeClass()));
            VALUE type;
            type = rb_funcall(get_type_class(), rb_intern("new"), 2, rb_str_new2(o.getStr()), type_class);
            return type;
        }
    case typelib_TypeClass_VOID:
        {
            return Qnil;
        }
    case typelib_TypeClass_CHAR:
        {
            sal_Unicode c = *(sal_Unicode*)a.getValue();
            VALUE v = ustring2RString(OUString(c));
            VALUE char_class = get_char_class();
            return rb_funcall(char_class, rb_intern("new"), 1, v);
        }
    case typelib_TypeClass_ANY:
        {
            return Qnil; // unknown
        }
    default:
        {
            throw RuntimeException(OUString(RTL_CONSTASCII_USTRINGPARAM("Unknown type.")), Reference< XInterface >());
        }
    }
    return Qnil;
}

/*
 * Convert Ruby VALUE to UNO Any.
 */
Any Runtime::value_to_any(VALUE value) const 
    throw (com::sun::star::uno::RuntimeException)
{
//printf("value_to_any: %s\n", rb_obj_classname(value));
    Any a;
    
    switch (TYPE(value))
    {
    case T_NIL:
        {
            break;
        }
    case T_TRUE:
        {
            sal_Bool b = sal_True;
            a = Any(&b, getBooleanCppuType());
            break;
        }
    case T_FALSE:
        {
            sal_Bool b = sal_False;
            a = Any(&b, getBooleanCppuType());
            break;
        }
    case T_FIXNUM:
        {
        // 63bit Fixnum be over flow
            sal_Int32 l = (sal_Int32) FIX2LONG(value);
            if (l <= 127 && l >= -128)
            {
                sal_Int8 b = (sal_Int8) l;
                a <<= b;
            }
            else if (l <= 0x7fff && l >= -0x8000)
            {
                sal_Int16 i = (sal_Int16) l;
                a <<= i;
            }
            else
            {
                a <<= l;
            }
            break;
        }
    case T_BIGNUM:
        {
            sal_Int64 l = (sal_Int64) NUM2LONG(value);
            if (l <= 127 && l >= -128)
            {
                sal_Int8 b = (sal_Int8) l;
                a <<= b;
            }
            else if (l <= 0x7fff && l >= -0x8000)
            {
                sal_Int16 i = (sal_Int16) l;
                a <<= i;
            }
            else if (l <= SAL_CONST_INT64(0x7fffffff) && l >= -SAL_CONST_INT64(0x80000000))
            {
                sal_Int32 l32 = (sal_Int32) l;
                a <<= l32;
            }
            else
            {
                a <<= l;
            }
            break;
        }
    case T_FLOAT:
        {
            double d = NUM2DBL(value);
            a <<= d;
            break;
        }
    case T_STRING:
        {
            if (rb_obj_is_kind_of(value, get_bytes_class()))
            {
                char *s = RSTRING_PTR(value);
                Sequence< sal_Int8 > seq((sal_Int8*)s, (sal_Int32)RSTRING_LEN(value));
                a <<= seq;
            }
            else
            {
                a <<= rbString2OUString(value);
            }
            break;
        }
    case T_ARRAY:
        {
            Sequence< Any > s(RARRAY_LEN(value));
            for (long i = 0; i < RARRAY_LEN(value); i++)
            {
                s[i] = value_to_any(rb_ary_entry(value, i)); // long?
            }
            a <<= s;
            break;
        }
    case T_DATA:
        {
            if (rb_obj_is_kind_of(value, get_proxy_class()))
            {
                RunoInternal *runo;
                Data_Get_Struct(value, RunoInternal, runo);
                if (runo)
                {
                    a = runo->wrapped;
                }
            }
            else if (rb_obj_is_kind_of(value, get_enum_class()) ||
                    rb_obj_is_kind_of(value, get_type_class()))
            {
                RunoValue *ptr;
                Data_Get_Struct(value, RunoValue, ptr);
                if (ptr)
                {
                    a <<= ptr->value;
                }
            }
            else if (rb_obj_is_kind_of(value, get_struct_class()) ||
                    rb_obj_is_kind_of(value, get_exception_class()))
            {
                RunoInternal *runo;
                Data_Get_Struct(value, RunoInternal, runo);
                Reference< XMaterialHolder > xholder(runo->invocation, UNO_QUERY);
                if (xholder.is())
                    a = xholder->getMaterial();
                else
                {
                    throw RuntimeException(OUString(RTL_CONSTASCII_USTRINGPARAM("XMaterialHolder is not supported.")), Reference< XInterface >());
                }
            }
            else if (rb_obj_is_kind_of(value, get_any_class()))
            {
                a = value_to_any(rb_iv_get(value, "@value"));
                Type t;
                value_to_any(rb_iv_get(value, "@type")) >>= t;
                try
                {
                    a = getImpl()->xTypeConverter->convertTo(a, t);
                }
                catch (com::sun::star::uno::Exception &e)
                {
                    throw RuntimeException(e.Message, e.Context);
                }
            }
            else if (rb_obj_is_kind_of(value, get_char_class()))
            {
                RunoValue *ptr;
                Data_Get_Struct(value, RunoValue, ptr);
                if (ptr)
                {
                    sal_Unicode c;
                    ptr->value >>= c;
                    a.setValue(&c, getCharCppuType());
                }
            }
            break;
        }
    default:
        {
            Reference< XInterface > mapped;
            Reference< XInvocation > adapted;
            
            Adapter *adapter = NULL;
            int s = st_lookup(imple->map, value, (st_data_t *)&adapter);
            
            if (adapter != NULL)
            {
                adapted = com::sun::star::uno::WeakReference< XInvocation >(adapter);
                Reference< com::sun::star::lang::XUnoTunnel > tunnel(adapted, UNO_QUERY);
                adapter = (Adapter *) sal::static_int_cast< sal_IntPtr >(tunnel->getSomething(Adapter::getTunnelImpleId()));
                
                mapped = imple->xAdapterFactory->createAdapter(adapted, adapter->getWrappedTypes());
            }
            else
            {
                Sequence< Type > types = getTypes(*this, &value);
                if (types.getLength())
                {
                    adapter = new Adapter(value, types);
                    mapped = getImpl()->xAdapterFactory->createAdapter(adapter, types);
                    st_add_direct(getImpl()->map, value, (st_data_t)adapter);
                    // keep wrapped values to be lived by GC
                    VALUE a = get_class(ADAPTED_OBJECTS);
                    rb_ary_push(a, value);
                }
                else
                    rb_raise(rb_eArgError, "value does not support any UNO interfaces", NULL);
            }
            if (mapped.is())
            {
                a = makeAny(mapped);
            }
            else
            {
                rb_raise(rb_eArgError, "unknown type (%s)", rb_obj_classname(value));       
            }
        }
    }
    return a;
}

}


