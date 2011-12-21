#! /bin/env rake
#
#  Copyright 2011 Tsutomu Uchino
# 
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#    http://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing,
#  software distributed under the License is distributed on an
#  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#  KIND, either express or implied.  See the License for the
#  specific language governing permissions and limitations
#  under the License.
#  

require 'rbconfig'
require 'rake/packagetask'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rubygems'
require 'rake/rdoctask'

# Build packages.
# Gem file for RPC.
# RubyLoader provides that you can write an UNO component in Ruby.
# RubyScriptProvider is a servicee to execute ruby script as macros.

env_descriptions = <<EOD
OO_SDK_HOME is used to find include files and map file which are part of the SDK.
OO_SDK_URE_HOME is used to find libraries and types.rdb file.
OFFICE_BASE_PROGRAM_PATH is used to offapi.rdb file.
EOD

sdk_home = ENV['OO_SDK_HOME']
ure_home = ENV['OO_SDK_URE_HOME']
base_path = ENV['OFFICE_BASE_PROGRAM_PATH']


# Building environment
c = Config::CONFIG

cc = c['CC']
link = c['LDSHAREDXX']
cxx = c['CXX']
host = c['host']

LIB_EXT = c['DLEXT']
OBJ_EXT = c['OBJEXT']

CPPU_INCLUDE = './include'
CPPUMAKER = 'cppumaker'
CPPUMAKER_FLAG = "#{CPPU_INCLUDE}/flag"

sdk_include = "#{sdk_home}/include"


rubyhdrdir = c['rubyhdrdir']
arch_rubyhdrdir = "#{rubyhdrdir}/#{c['arch']}"
ruby_backward = "#{rubyhdrdir}/ruby/backward"

dldlibs = c['DLDLIBS']

CFLAGS = c['CFLAGS']
cxxflags = CFLAGS + c['CXXFLAGS']
cxxflags.gsub!(/-O\d?/, "")


target = '3.4'
VERSION = '0.2.0'

RD2 = "rd2"
ZIP = "zip"
ZIP_ARGS = "-9"

OXT_EXT = 'oxt'
RD_EXT = 'rd'

# Local directories
SRC_DIR = "./src"
LIB_DIR = "./lib"
PKG_DIR = "./pkg"
DOC_DIR = "./doc"

# Definitions for the component loader for Ruby.
LOADER_PKG_NAME = "RubyLoader"
LOADER_PKG_DISPLAY_NAME = "Ruby Loader"
LOADER_PKG_ID = "mytools.loader.Ruby"
LOADER_PKG_DESC = "The UNO component loader written in Ruby."

LOADER_REGISTRATION = "RubyLoader.components"
LOADER_IMPLE_NAME = "mytools.loader.Ruby"
LOADER_SERVICE_NAMES = ["com.sun.star.loader.Ruby"]
LOADER_RB = "rubyloader.rb"

LOADER_PKG_DIR_NAME = "#{LOADER_PKG_NAME}-#{VERSION}"
LOADER_PKG_FULL_NAME = "#{LOADER_PKG_NAME}-#{VERSION}.#{OXT_EXT}"
LOADER_PKG_DIR = "#{PKG_DIR}/#{LOADER_PKG_NAME}-#{VERSION}"
LOADER_PKG = "#{PKG_DIR}/#{LOADER_PKG_FULL_NAME}"

# Definitions for the script provider for Ruby.
SCRIPT_PKG_NAME = "RubyScriptProvider"
SCRIPT_PKG_DISPLAY_NAME = "Ruby Script Provider"
SCRIPT_PACKAGE_ID = "mytools.script.provider.ScriptProviderForRuby"

SCRIPT_REGISTRATION = "ScriptProviderForRuby.components"
SCRIPT_DESC = "The script provider for Ruby."
SCRIPT_IMPLE_NAME = "mytools.script.provider.ScriptProviderForRuby"
SCRIPT_SERVICE_NAMES = [
  "com.sun.star.script.provider.ScriptProviderForRuby", 
  "com.sun.star.script.provider.LanguageScriptProvider"]
SCRIPT_RB = "rubyscriptprovider.rb"

SCRIPT_PKG_DIR_NAME = "#{SCRIPT_PKG_NAME}-#{VERSION}"
SCRIPT_PKG_FULL_NAME = "#{SCRIPT_PKG_NAME}-#{VERSION}.#{OXT_EXT}"
SCRIPT_PKG_DIR = "#{PKG_DIR}/#{SCRIPT_PKG_DIR_NAME}"
SCRIPT_PKG = "#{PKG_DIR}/#{SCRIPT_PKG_FULL_NAME}"

UNO_RB = "uno.rb"
CONNECTOR_RB = "connector.rb"
LIB_RB = "lib.rb"

# Local files

LIB_UNO_DIR = "#{LIB_DIR}/uno"

MODULE_DLL = "runo.#{LIB_EXT}"

ALL_SRCS = FileList["#{SRC_DIR}/*.cxx"]
MODULE_SRCS = FileList["#{SRC_DIR}/module.cxx"]
LOADER_SRCS = FileList["#{SRC_DIR}/loader.cxx"]
LIB_SRCS = FileList["#{SRC_DIR}/*.cxx"] - MODULE_SRCS - LOADER_SRCS

ALL_OBJS = ALL_SRCS.ext(OBJ_EXT)
MODULE_OBJS = MODULE_SRCS.ext(OBJ_EXT)
LOADER_OBJS = LOADER_SRCS.ext(OBJ_EXT)
LIB_OBJS = LIB_SRCS.ext(OBJ_EXT)

RD_DOCS = FileList["#{DOC_DIR}/*.rd"]
HTML_DOCS = RD_DOCS.ext("html")

CLEAN.include(MODULE_OBJS)
CLEAN.include(LOADER_OBJS)
CLEAN.include(LIB_OBJS)
CLEAN.include(HTML_DOCS)

directory LIB_DIR
directory PKG_DIR
directory LIB_UNO_DIR


if host.include? 'linux'
  # how about 64bit?, Linux_x64
  platform = "Linux_x86"
  lib_dll = "libruno.#{LIB_EXT}"
  loader_dll = "rubyloader.uno.#{LIB_EXT}"
  
  local_link_lib = "-L#{LIB_DIR}"
  lib = "-L#{c['libdir']}"
  
  coutflag = c['COUTFLAG']
  optflags = "-O1"
  cflags = "-fPIC"
  debugflags = ""#c['debugflags']
  
  flags = "#{cflags} #{optflags} #{debugflags} #{cxxflags}"
  
  ruby_defs = c['DEFS']
  cc_defs = "-fno-strict-aliasing -DUNX -DGCC -DLINUX -DCPPU_ENV=gcc3 " + 
        " #{ruby_defs}"
  
  incflags = "-I. -I#{arch_rubyhdrdir} -I#{ruby_backward} -I#{rubyhdrdir} " + 
    "-I#{sdk_include} -I#{CPPU_INCLUDE} "
  
  sdk_lib = "-L#{sdk_home}/lib"
  ure_lib = "-L#{ure_home}/lib"
  
  sdk_libs = " -luno_cppuhelpergcc3 -luno_cppu -luno_salhelpergcc3 -luno_sal -lm "
  ldflags = c['LDFLAGS']
  lib_ldflags = ""
  
  LIB = ""
  LIBS = "#{c['LIBS']} #{dldlibs}"
  LIBRUBYARG = c['LIBRUBYARG']
  runo_libs = "-lruno"
  
  uno_link_flags = "'-Wl,-rpath,$ORIGIN' -Wl,--version-script,#{sdk_home}/settings/component.uno.map"
  
  ure_types = "#{ure_home}/share/misc/types.rdb"
  
elsif host.include? 'mswin'
  platform = "Windows"
  
  link = "link -nologo "
  mt = "mt -nologo "
  
  DLL_EXT = 'dll'
  lib_dll = "libruno.#{DLL_EXT}"
  loader_dll = "rubyloader.uno.#{DLL_EXT}"
  
  out_flag = "/OUT:"
  coutflag = "/Fo"
  optflags = "/O1"
  cflags = "-MD -Zi -EHsc -Zm600 -Zc:forScope,wchar_t-" #-GR 
  debugflags = ""#c['debugflags']
  warnflags = "-wd4251 -wd4275 -wd4290 -wd4675 -wd4786 -wd4800 " + 
    "-Zc:forScope"
  
  flags = "#{cflags} #{optflags} #{warnflags} #{debugflags}"
  
  ruby_defs = c['DEFS']
  cc_defs = "-DWIN32 -DWNT -D_DLL -DCPPU_V=msci -DCPPU_ENV=msci"
  
  incflags = "-I. -I#{arch_rubyhdrdir} -I#{ruby_backward} -I#{rubyhdrdir} " + 
    "-I#{sdk_include} -I#{CPPU_INCLUDE} "
  
  sdk_lib = "/LIBPATH:#{sdk_home}/lib"
  ure_lib = ""
  
  sdk_libs = " icppuhelper.lib icppu.lib isal.lib isalhelper.lib msvcprt.lib msvcrt.lib kernel32.lib" # 
  
  module_def = "#{SRC_DIR}/runo.def"
  libuno_def = "#{SRC_DIR}/libruno.def"
  
  ldflags = " /DLL /NODEFAULTLIB:library /DEBUGTYPE:cv "
  module_ldflags = " #{ldflags} /MAP /DEF:#{module_def} "
  lib_ldflags = " #{ldflags} /MAP /DEF:#{libuno_def} "
  
  local_link_lib = "/LIBPATH:#{LIB_DIR}"
  LIB = " /LIBPATH:#{c['libdir']} "
  
  LIBS = "#{c['LIBS']} #{dldlibs}"
  LIBRUBYARG = c['LIBRUBYARG']
  runo_libs = "libruno.lib"
  
  uno_link_flags = "/DEF:#{sdk_home}/settings/component.uno.def"
  
  ure_types = "#{ure_home}/misc/types.rdb"
  
else
  raise "#{host} is not yet supported to build."
end


# Default task

task :default => [:all]

task :all => [
  :package, 
  :loader, :provider, 
  :rd_docs
]


# C++ files

rule ".#{OBJ_EXT}" => '.cxx' do |t|
  sh "#{cc} #{incflags} #{cc_defs} #{flags} " + 
     "#{coutflag}#{t.name} -c #{t.source} "
end


# Header from IDL

types = [
  "com.sun.star.beans.MethodConcept", 
  "com.sun.star.beans.PropertyAttribute", 
  "com.sun.star.beans.XIntrospection", 
  "com.sun.star.beans.XIntrospectionAccess", 
  "com.sun.star.beans.XMaterialHolder", 
  "com.sun.star.container.XEnumerationAccess", 
  "com.sun.star.container.XHierarchicalNameAccess", 
  "com.sun.star.container.XIndexContainer", 
  "com.sun.star.container.XNameContainer", 
  "com.sun.star.lang.XMultiServiceFactory", 
  "com.sun.star.lang.XServiceInfo", 
  "com.sun.star.lang.XSingleComponentFactory", 
  "com.sun.star.lang.XSingleServiceFactory", 
  "com.sun.star.lang.XTypeProvider", 
  "com.sun.star.lang.XUnoTunnel", 
  "com.sun.star.reflection.InvocationTargetException", 
  "com.sun.star.reflection.ParamMode", 
  "com.sun.star.reflection.XConstantTypeDescription", 
  "com.sun.star.reflection.XConstantsTypeDescription", 
  "com.sun.star.reflection.XEnumTypeDescription", 
  "com.sun.star.reflection.XIdlReflection", 
  "com.sun.star.reflection.XInterfaceTypeDescription2", 
  "com.sun.star.reflection.XTypeDescription", 
  "com.sun.star.registry.XRegistryKey", 
  "com.sun.star.script.InvocationInfo", 
  "com.sun.star.script.MemberType", 
  "com.sun.star.script.XInvocation2", 
  "com.sun.star.script.XInvocationAdapterFactory2", 
  "com.sun.star.script.XTypeConverter", 
  "com.sun.star.script.provider.ScriptFrameworkErrorException", 
  "com.sun.star.uno.XAggregation", 
  "com.sun.star.uno.TypeClass", 
  "com.sun.star.uno.XComponentContext", 
  "com.sun.star.uno.XWeak", 
]

desc "generate headers"
task :header do
  unless File.exists?(CPPUMAKER_FLAG)
    puts "flag for cppumaker does not exist. starting cppumaker..."
    
    office_types = "#{base_path}/offapi.rdb"
    sh "#{CPPUMAKER} -Gc -BUCR -O#{CPPU_INCLUDE} -T\"#{types.join(';')}\" \"#{ure_types}\" \"#{office_types}\""
    sh "echo > #{CPPUMAKER_FLAG}"
  end
end


# Gem
GEM_LIB_UNO_RB = "#{LIB_DIR}/#{UNO_RB}"
GEM_LIB_RUNO_MODULE = "#{LIB_UNO_DIR}/#{MODULE_DLL}"

task :package => [:header, GEM_LIB_UNO_RB, GEM_LIB_RUNO_MODULE]

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = c['RUBY_PROGRAM_VERSION']
  s.summary = "Ruby-UNO native bridge."
  s.name = "rubyuno"
  s.version = VERSION
  s.requirements << 'none'
  s.author = "hanya"
  s.email = "hanya.runo@gmail.com"
  s.homepage = "https://github.com/hanya/RUNO"
  s.files = [
    GEM_LIB_UNO_RB, 
    GEM_LIB_RUNO_MODULE
  ]
  s.extra_rdoc_files = FileList["#{DOC_DIR}/*.#{RD_EXT}"]
  s.description = <<EOF
RubyUNO is native bridge between Ruby and UNO.
EOF
end

Rake::GemPackageTask.new(spec) do |t|
end

file GEM_LIB_UNO_RB => [LIB_DIR] do |t|
  uno = IO.read("#{SRC_DIR}/#{UNO_RB}")
  connector = IO.read("#{SRC_DIR}/#{CONNECTOR_RB}")
  uno.sub!(/#require 'uno\/runo.so'/, "require 'uno/runo.so'")
  open("#{LIB_DIR}/#{UNO_RB}", "w") do |f|
    f.write uno
    f.write connector
    f.flush
  end
end

desc "runo.so for RPC connection."
file GEM_LIB_RUNO_MODULE => [LIB_UNO_DIR, *ALL_OBJS] do |t|
  puts "building ./lib/uno/runo.so"
  sh "#{link} #{out_flag}#{t.name} #{ALL_OBJS.join(' ')} " + 
    " #{LIB} #{module_ldflags} " + 
    " #{sdk_lib} #{ure_lib}" + 
    " #{sdk_libs} #{LIBRUBYARG} #{LIBS} "
  if host.include? 'mswin'
    sh "#{mt} -manifest #{t.name}.manifest -outputresource:#{t.name};2"
  end
end


# Templates for OXT file

TEMPLATE_MANIFEST = <<EOD
<?xml version="1.0" encoding="UTF-8"?>
<manifest:manifest>
 <manifest:file-entry manifest:full-path="${LOADER}" manifest:media-type="${MEDIA_TYPE}"/>
</manifest:manifest>
EOD

TEMPLATE_COMPONENTS = <<EOD
<?xml version="1.0" encoding="UTF-8"?>
<components xmlns="http://openoffice.org/2010/uno-components">
  <component loader="${LOADER_NAME}" uri="${URI}">
    <implementation name="${IMPLE_NAME}">
      ${SERVICES}
    </implementation>
  </component>
</components>
EOD

TEMPLATE_DESCRIPTION = <<EOD
<?xml version="1.0" encoding="UTF-8"?>
<description xmlns="http://openoffice.org/extensions/description/2006"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:d="http://openoffice.org/extensions/description/2006">
  <identifier value="${ID}"/>
  <version value="${VERSION}"/>
  <dependencies>
    <OpenOffice.org-minimal-version value="${TARGET}" d:name="OpenOffice.org ${TARGET}"/>
  </dependencies>
  <!--
  <registration>
    <simple-license accept-by="admin" default-license-id="this" suppress-on-update="true">
      <license-text xlink:href="LICENSE" license-id="this"/>
    </simple-license>
  </registration>
  -->
  <display-name>
    <name lang="en">${DISPLAY_NAME}</name>
  </display-name>
  <extension-description>
    <src lang="en" xlink:href="descriptions/desc.en"/>
  </extension-description>
</description>
EOD

# procedures depends on templates

# Creates description.xml
def description_task(dir_path, id, target, display_name)
  description_file = "#{dir_path}/description.xml"
  data = String.new TEMPLATE_DESCRIPTION
  data.gsub!(/\$\{ID\}/, id)
  data.gsub!(/\$\{VERSION\}/, VERSION)
  data.gsub!(/\$\{TARGET\}/, target)
  data.gsub!(/\$\{DISPLAY_NAME\}/, display_name)
  open(description_file, "w") do |f|
    f.write(data)
    f.flush
  end
end


# Creates META-INF/manifest.xml
def manifest_task(dir_path, full_path, media_type)
  
  manifest_file = "#{dir_path}/META-INF/manifest.xml"
  manifest_dir = File.dirname(manifest_file)
  mkdir_p manifest_dir unless File.exist?(manifest_dir)
    
  data = String.new TEMPLATE_MANIFEST
  data.gsub!(/\$\{LOADER\}/, full_path)
  data.gsub!(/\$\{MEDIA_TYPE\}/, media_type)
  open(manifest_file, "w") do |f|
    f.write(data)
    f.flush
  end
end


def registration_task(dir_path, file_name, loader_name, uri, imple_name, services)
  puts "registration"
  components_f = "#{dir_path}/lib/#{file_name}"
  
  data = String.new TEMPLATE_COMPONENTS
  data.gsub!(/\$\{LOADER_NAME\}/, loader_name)
  data.gsub!(/\$\{URI\}/, uri)
  data.gsub!(/\$\{IMPLE_NAME\}/, imple_name)
  services.map! do |name|
    "<service name=\"#{name}\"/>"
  end
  data.gsub!(/\$\{SERVICES\}/, services.join("\n"))
  open(components_f, "w") do |f|
    f.write(data)
    f.flush
  end
end


# Creates description/desc.en
def extension_description_task(dir_path, desc) 
  path = "#{dir_path}/descriptions/desc.en"
  desc_dir = File.dirname(path)
  mkdir_p desc_dir unless File.exist?(desc_dir)
  open(path, "w") do |f|
    f.write(desc)
    f.flush
  end
end


# Pack as zip archive
def packaging_task(dir_path, pkg_name)
  chdir dir_path do
    sh "#{ZIP} -9 -r -o ../#{pkg_name} * **/*"
  end
end


# Package of RubyLoader

task :loader => [:header, LOADER_PKG]

LOADER_PKG_DIR_LIB = "#{LOADER_PKG_DIR}/lib"
LOADER_LIB_RUNO_DLL = "#{LIB_DIR}/#{lib_dll}"
LOADER_MODULE_DLL = "#{LIB_DIR}/#{MODULE_DLL}"
LOADER_LIB_DLL = "#{LIB_DIR}/#{loader_dll}"

directory LOADER_PKG_DIR
directory LOADER_PKG_DIR_LIB


desc "create libruno library"
file LOADER_LIB_RUNO_DLL => [LIB_DIR, *LIB_OBJS] do |t|
  sh "#{link} #{out_flag}#{t.name} #{LIB_OBJS.join(' ')} " + 
     " #{LIB} #{lib_ldflags} " + 
     " #{sdk_lib} #{ure_lib}" + 
     " #{sdk_libs} #{LIBRUBYARG} #{LIBS} "
  if host.include? 'mswin'
    sh "#{mt} -manifest #{t.name}.manifest -outputresource:#{t.name};2"
  end
end


desc "runo.so for RubyLoader."
file LOADER_MODULE_DLL => [LIB_DIR, *MODULE_OBJS, "#{LIB_DIR}/#{lib_dll}"] do |t|
  p "building runo.so"
  sh "#{link} #{out_flag}#{LIB_DIR}/#{MODULE_DLL} #{MODULE_OBJS.join(' ')} " + 
     " #{LIB} #{local_link_lib} #{module_ldflags} " + 
     " #{sdk_lib} #{ure_lib}" + 
     " #{sdk_libs} #{LIBRUBYARG} #{LIBS} #{runo_libs}"
  if host.include? 'mswin'
    sh "#{mt} -manifest #{t.name}.manifest -outputresource:#{t.name};2"
  end
end


desc "create loader component"
file LOADER_LIB_DLL => [LIB_DIR, *LOADER_OBJS] do |t|
  p "building loader"
  sh "#{link} #{out_flag}#{LIB_DIR}/#{loader_dll} #{LOADER_OBJS.join(' ')} " + 
     "  #{LIB} #{local_link_lib} #{ldflags} #{uno_link_flags}" + 
     " #{sdk_lib} #{ure_lib}" + 
     " #{sdk_libs} #{LIBRUBYARG} #{LIBS} #{runo_libs} "
  if host.include? 'mswin'
    sh "#{mt} -manifest #{t.name}.manifest -outputresource:#{t.name};2"
  end
end


file LOADER_PKG => [LOADER_PKG_DIR, "#{LOADER_PKG_DIR}/lib", LOADER_LIB_RUNO_DLL, LOADER_MODULE_DLL, LOADER_LIB_DLL] do |t|
  
  dir_path = t.name.sub(/.oxt$/, "")
  media_type = "application/vnd.sun.star.uno-components;platform=#{platform}"
      "#{LIB_DIR}/#{loader_dll}"
  full_path = "lib/#{LOADER_REGISTRATION}"
  
  registration_task(dir_path, LOADER_REGISTRATION, 
      "com.sun.star.loader.SharedLibrary", loader_dll, 
      LOADER_IMPLE_NAME, LOADER_SERVICE_NAMES)
  manifest_task(dir_path, full_path, media_type)
  description_task(dir_path, LOADER_PKG_ID, target, LOADER_PKG_DISPLAY_NAME)
  extension_description_task(dir_path, LOADER_PKG_DESC)
  
  cp "#{LOADER_LIB_RUNO_DLL}", "#{LOADER_PKG_DIR_LIB}/#{lib_dll}"
  cp "#{LOADER_MODULE_DLL}", "#{LOADER_PKG_DIR_LIB}/#{MODULE_DLL}"
  cp "#{LOADER_LIB_DLL}", "#{LOADER_PKG_DIR_LIB}/#{loader_dll}"
  
  cp "#{SRC_DIR}/#{LOADER_RB}", "#{LOADER_PKG_DIR_LIB}/#{LOADER_RB}"
  cp "#{SRC_DIR}/#{UNO_RB}", "#{LOADER_PKG_DIR_LIB}/#{LIB_RB}"
  
  packaging_task dir_path, File.basename(t.name)
end


# Package of RubyScriptProvider

task :provider => [SCRIPT_PKG]

SCRIPT_PKG_DIR_LIB = "#{SCRIPT_PKG_DIR}/lib"

directory SCRIPT_PKG_DIR
directory SCRIPT_PKG_DIR_LIB


file SCRIPT_PKG => [SCRIPT_PKG_DIR, SCRIPT_PKG_DIR_LIB] do |t|
  
  dir_path = t.name.sub(/.oxt$/, "")
  media_type = "application/vnd.sun.star.uno-components"
  
  registration_task(dir_path, SCRIPT_REGISTRATION, 
      "com.sun.star.loader.Ruby", SCRIPT_RB, 
      SCRIPT_IMPLE_NAME, SCRIPT_SERVICE_NAMES)
  manifest_task(dir_path, "lib/#{SCRIPT_REGISTRATION}", media_type)
  description_task(dir_path, SCRIPT_PACKAGE_ID, target, SCRIPT_PKG_DISPLAY_NAME)
  extension_description_task(dir_path, SCRIPT_DESC)
  
  cp "#{SRC_DIR}/#{SCRIPT_RB}", "#{SCRIPT_PKG_DIR_LIB}/#{SCRIPT_RB}"
  
  packaging_task dir_path, File.basename(t.name)
end

# Documents

rule '.html' => '.rd' do |t|
  sh "#{RD2} #{t.source} > #{t.name}"
end

task :rd_docs => [*HTML_DOCS]


