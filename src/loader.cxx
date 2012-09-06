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

#include "runo.hxx"

#include <osl/module.hxx>
#include <osl/process.h>
#include <osl/thread.h>
#include <osl/file.hxx>

#include <cppuhelper/implementationentry.hxx>
#include <rtl/ustrbuf.hxx>

#include <com/sun/star/uno/XInterface.hpp>

using com::sun::star::uno::Reference;
using com::sun::star::uno::Sequence;
using com::sun::star::uno::XComponentContext;
using com::sun::star::uno::XInterface;

using rtl::OUString;
using rtl::OUStringToOString;
using rtl::OUStringBuffer;

#define IMPLE_NAME "mytools.loader.Ruby"
#define SERVICE_NAME "com.sun.star.loader.Ruby"

namespace runoloader
{

static void 
getLibraryPath(OUString &path) throw (com::sun::star::uno::RuntimeException)
{
    OUString libUrl;
    ::osl::Module::getUrlFromAddress(
        reinterpret_cast< oslGenericFunction >(getLibraryPath), libUrl);
    libUrl = libUrl.copy(0, libUrl.lastIndexOf('/'));
    osl::FileBase::RC e = osl::FileBase::getSystemPathFromFileURL(libUrl, path);
    if (e != osl::FileBase::E_None)
    {
        throw com::sun::star::uno::RuntimeException(
            OUString(RTL_CONSTASCII_USTRINGPARAM(
                "failed to retrieve path to the loader.")), 
            Reference< XInterface >());
    }
}

static int ruby_state = 1;

static void 
load_modules(VALUE args)
{
    rb_require(RSTRING_PTR(rb_ary_entry(args, 0)));
    rb_require(RSTRING_PTR(rb_ary_entry(args, 1)));
    rb_require(RSTRING_PTR(rb_ary_entry(args, 2)));
}


Reference< XInterface > 
createInstanceWithContext(const Reference< XComponentContext > &ctx)
{
    Reference< XInterface > ret;
    if (ruby_state == 1)
    {
        OUStringBuffer buf;
        OUString sysPath;
        getLibraryPath(sysPath);
        
        RUBY_INIT_STACK;
        ruby_init();
        ruby_init_loadpath();
        
        if (! runo::Runtime::isInitialized())
        {
            try
            {
                runo::Runtime::initialize(ctx);
            }
            catch (com::sun::star::uno::RuntimeException &e)
            {
                return ret;
            }
        }
        VALUE argv = rb_ary_new2(3);
        buf.append(sysPath);
        buf.appendAscii("/runo.so");
        rb_ary_store(argv, 0, runo::ustring2RString(buf.makeStringAndClear()));
        buf.append(sysPath);
        buf.appendAscii("/lib.rb");
        rb_ary_store(argv, 1, runo::ustring2RString(buf.makeStringAndClear()));
        buf.append(sysPath);
        buf.appendAscii("/rubyloader.rb");
        rb_ary_store(argv, 2, runo::ustring2RString(buf.makeStringAndClear()));
        int state;
        rb_protect((VALUE(*)(VALUE))load_modules, argv, &state);
        ruby_state = state; // 0 sucess
        if (state)
        {
            rb_p(rb_gv_get("$!"));
        }
    }
    if (ruby_state == 0 && runo::Runtime::isInitialized())
    {
        runo::Runtime runtime;
        VALUE loader_module = rb_const_get(
                    rb_cObject, rb_intern("RubyLoader"));
        VALUE loader_imple = rb_const_get(
                    loader_module, rb_intern("RubyLoaderImpl"));
        VALUE ctx_val = runtime.any_to_VALUE(makeAny(ctx));
        VALUE args[1];
        args[0] = ctx_val;
        VALUE loader = rb_class_new_instance(1, args, loader_imple);
        runtime.value_to_any(loader) >>= ret;
    }
    return ret;
}


OUString
getImplementationName()
{
    return OUString(RTL_CONSTASCII_USTRINGPARAM(IMPLE_NAME));
}

Sequence< OUString >
getSupportedServiceNames()
{
    OUString name(RTL_CONSTASCII_USTRINGPARAM(SERVICE_NAME));
    return Sequence< OUString >(&name, 1);
}

} // runoloader

static struct cppu::ImplementationEntry g_entries[] = 
{
    {
        runoloader::createInstanceWithContext, 
        runoloader::getImplementationName, 
        runoloader::getSupportedServiceNames, 
        cppu::createSingleComponentFactory, 
        0, 
        0
    }, 
    {0, 0, 0, 0, 0, 0}
};


extern "C"
{

void SAL_CALL
component_getImplementationEnvironment(const sal_Char **ppEnvTypeName, uno_Environment **)
{
    *ppEnvTypeName = CPPU_CURRENT_LANGUAGE_BINDING_NAME;
}
/*
sal_Bool SAL_CALL
component_writeInfo(void *pServiceManager, void *pRegistryKey)
{
    return cppu::component_writeInfoHelper(pServiceManager, pRegistryKey, g_entries);
}
*/
void* SAL_CALL
component_getFactory(const sal_Char *pImplName, void *pServiceManager, void *pRegistryKey)
{
    return cppu::component_getFactoryHelper(pImplName, pServiceManager, pRegistryKey, g_entries);
}

}
