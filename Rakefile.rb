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

# Build two packages.
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

target = "3.4"

VERSION = "0.2.0"

# Definitions for the component loader for Ruby.
LOADER_PACKAGE_NAME = "RubyLoader"
LOADER_PACKAGE_DISPLAY_NAME = "Ruby Loader"
LOADER_PACKAGE_ID = "mytools.loader.Ruby"
LOADER_PACKAGE_DESC = "The UNO component loader written in Ruby."
LOADER_REGISTRATION = "RubyLoader.components"
LOADER_IMPLE_NAME = "mytools.loader.Ruby"
LOADER_SERVICE_NAMES = ["com.sun.star.loader.Ruby"]
LOADER_RB = "rubyloader.rb"

# Definitions for the script provider for Ruby.
SCRIPT_PROVIDER_PACKAGE_NAME = "RubyScriptProvider"
SCRIPT_PROVIDER_PACKAGE_DISPLAY_NAME = "Ruby Script Provider"
PROVIDER_PACKAGE_ID = "mytools.script.provider.ScriptProviderForRuby"
PROVIDER_REGISTRATION = "ScriptProviderForRuby.components"
SCRIPT_PROVIDER_DESC = "The script provider for Ruby."
SCRIPT_PROVIDER_IMPLE_NAME = "mytools.script.provider.ScriptProviderForRuby"
SCRIPT_PROVIDER_SERVICE_NAMES = [
  "com.sun.star.script.provider.ScriptProviderForRuby", 
  "com.sun.star.script.provider.LanguageScriptProvider"]
SCRIPT_PROVIDER_RB = "rubyscriptprovider.rb"

# build env
config = Config::CONFIG

CC = config['CC']
LINK = config['LDSHAREDXX']
CXX = config['CXX']
HOST = config['host']

LIB_EXT = config['DLEXT']
OBJ_EXT = config['OBJEXT']

SRC_DIR = "./src"
LIB_DIR = "./lib"
PKG_DIR = "./pkg"
DOC_DIR = "./doc"
TEMPLATE_DIR = "./templates"
LIB_UNO_DIR = "#{LIB_DIR}/uno"

MODULE_DLL = "runo." + LIB_EXT
LOADER_DLL = "rubyloader.uno." + LIB_EXT
#LIB_DLL = "libruno." + LIB_EXT

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

CPPU_INCLUDE = './include'
CPPUMAKER = 'cppumaker'
CPPUMAKER_FLAG = "#{CPPU_INCLUDE}/flag"

sdk_include = "#{sdk_home}/include"

rubyhdrdir = config['rubyhdrdir']
arch_rubyhdrdir = "#{rubyhdrdir}/#{config['arch']}"
ruby_backward = "#{rubyhdrdir}/ruby/backward"

COUTFLAG = config['COUTFLAG']
LDFLAGS = config['LDFLAGS']
LIB = config['libdir']

dldlibs = config['DLDLIBS']

CFLAGS = config['CFLAGS']
cxxflags = CFLAGS + config['CXXFLAGS']
cxxflags.gsub!(/-O\d?/, "")

directory LIB_DIR
directory PKG_DIR
directory LIB_UNO_DIR


if HOST.include?('linux')
  # how about 64bit?, Linux_x64
  PLATFORM = "Linux_x86"
  LIB_DLL = "libruno." + LIB_EXT
  
  optflags = "-O1"
  cflags = "-fPIC"
  
  out_flag = "-o "
  debugflags = ""#config['debugflags']
  flags = "#{cflags} #{optflags} #{debugflags}"
  
  DEFS = config['DEFS']
  CC_DEFINES = "-fno-strict-aliasing -DUNX -DGCC -DLINUX -DCPPU_ENV=gcc3 " + 
        " #{DEFS}"
  #"-DGXX_INCLUDE_PATH=#{ENV['SDK_GXX_INCLUDE_PATH']}
  
  incflags = "-I. -I#{arch_rubyhdrdir} -I#{ruby_backward} -I#{rubyhdrdir} " + 
    "-I#{sdk_include} -I#{CPPU_INCLUDE} "
  
  URE_LIB = "#{ure_home}/lib"
  SDK_LIBS = " -luno_cppuhelpergcc3 -luno_cppu -luno_salhelpergcc3 -luno_sal -lm "
  
  LIBS = "#{config['LIBS']} #{dldlibs}"
  LIBRUBYARG = config['LIBRUBYARG']
  RUNO_LIBS = "-lruno"
  
  UNO_LINK_FLAGS = "'-Wl,-rpath,$ORIGIN' -Wl,--version-script,#{sdk_home}/settings/component.uno.map"

elsif HOST.include?('mswin') || HOST.include?('mingw')
  PLATFORM = "Windows"
  LIB_DLL = "runo." + LIB_EXT
  
  optflags = "/O1"
  cflags = "-MT -GR -EHa -Zm500 -Zc:forScope,wchar_t-"
  
  out_flag = "/OUT:"
  debugflags = ""#config['debugflags']
  warnflags = "-wd4251 -wd4275 -wd4290 -wd4675 -wd4786 -wd4800" + 
    "-Zc:forScope"
  flags = "#{cflags} #{optflags} #{warnflags} #{debugflags}"
  
  DEFS = config['DEFS']
  CC_DEFINES = "-DWIN32 -DWNT -D_DLL -DCPPU_V=msci"
  
  incflags = "-I. -I#{arch_rubyhdrdir} -I#{ruby_backward} -I#{rubyhdrdir} " + 
    "-I#{sdk_include} -I#{CPPU_INCLUDE} "
  
  URE_LIB = ""
  SDK_LIBS = "icppuhelper.lib icppu.lib isalhelper.lib isal.lib msvcrt.lib kernel32.lib"
  
  LIBS = "#{config['LIBS']} #{dldlibs}"
  LIBRUBYARG = config['LIBRUBYARG']
  RUNO_LIBS = "iruno.lib"
  
  UNO_LINK_FLAGS = "#{sdk_home}/DEF:/settings/component.uno.def"
  
else
  # unknown environment
  
end


task :default => [:all]

rule '.o' => '.cxx' do |t|
  sh "#{CXX} #{incflags} #{CC_DEFINES} #{flags} #{cxxflags} " + 
     "#{COUTFLAG} #{t.name} -c #{t.source} "
end

rule '.html' => '.rd' do |t|
  sh "rd2 #{t.source} > #{t.name}"
end

desc "Load SDK settings"
task :environment, :dist do |t, dist|
 # check variables
end

desc "generate headers"
task :header => :environment do
  unless File.exists?(CPPUMAKER_FLAG)
    puts "flag for cppumaker does not exist. starting cppumaker..."
    #p HOST
    office_types = "#{base_path}/offapi.rdb"
    if HOST.include?('linux')
      ure_types = "#{ure_home}/share/misc/types.rdb"
    end
    sh "#{CPPUMAKER} -Gc -BUCR -O#{CPPU_INCLUDE} #{ure_types} #{office_types}"
    sh "echo > #{CPPUMAKER_FLAG}"
  end
end


file :module => [LIB_UNO_DIR, *ALL_OBJS] do |t|
  sh "#{LINK} #{out_flag}#{LIB_UNO_DIR}/runo.so #{ALL_OBJS.join(' ')} " + 
    " -L. -L#{LIB} -L#{LIB_DIR} #{LDFLAGS} " + 
    %Q! -L"#{sdk_home}/lib" -L"#{URE_LIB}"! + 
    "#{SDK_LIBS} #{LIBRUBYARG} #{LIBS} "
end


file "#{LIB_DIR}/#{MODULE_DLL}" => [LIB_DIR, *MODULE_OBJS] do |t|
  #p "building runo module"
  sh "#{LINK} #{out_flag}#{LIB_DIR}/#{MODULE_DLL} #{MODULE_OBJS.join(' ')} " + 
    " -L. -L#{LIB} -L#{LIB_DIR} #{LDFLAGS} " + 
    %Q! -L"#{sdk_home}/lib" -L"#{URE_LIB}"! + 
    "#{SDK_LIBS} #{LIBRUBYARG} #{LIBS} #{RUNO_LIBS}"
end

desc "create liruno library"
file "#{LIB_DIR}/#{LIB_DLL}" => [LIB_DIR, *LIB_OBJS] do |t|
  sh "#{LINK} #{out_flag}#{LIB_DIR}/#{LIB_DLL} #{LIB_OBJS.join(' ')} " + 
    "-L. -L#{LIB} #{LDFLAGS} " + 
    %Q! -L"#{sdk_home}/lib" -L"#{URE_LIB}"! + 
    "#{SDK_LIBS} #{LIBRUBYARG} #{LIBS} "
end

desc "create loader component"
file "#{LIB_DIR}/#{LOADER_DLL}" => [LIB_DIR, *LOADER_OBJS] do |t|
  #p "building loader"
  sh "#{LINK} #{out_flag}#{LIB_DIR}/#{LOADER_DLL} #{LOADER_OBJS.join(' ')} " + 
    " -L. -L#{LIB} -L#{LIB_DIR} #{LDFLAGS} #{UNO_LINK_FLAGS}" + 
    %Q! -L"#{sdk_home}/lib" -L"#{URE_LIB}"! + 
    "#{SDK_LIBS} #{LIBRUBYARG} #{LIBS} #{RUNO_LIBS} "
end


# package task for OXT package
# OXT package having well defined structure.
module Rake
  class OXTPackageTask < PackageTask
    def initialize(name, version)
      super(name, version)
      @need_zip = true
    end
    
    def define
      super()

      dir_path = "#{package_dir}/#{zip_file}"
      task :package => [dir_path]
      file dir_path => [package_dir_path] + @package_files do
        chdir package_dir_path do
          sh "#{@zip_command} -r -o ../#{zip_file} * **/*"
        end
      end
      self
    end
    
    def zip_file
      return "#{package_name}.oxt"
    end
  end
end

desc "Packaging task of Ruby loader."
loader_package_task = Rake::OXTPackageTask.new(LOADER_PACKAGE_NAME, VERSION) do |p|
  p.package_files.include("#{LIB_DIR}/#{LIB_DLL}")
  p.package_files.include("#{LIB_DIR}/#{MODULE_DLL}")
  p.package_files.include("#{LIB_DIR}/#{LOADER_DLL}")
  p.package_files.include("#{LIB_DIR}/#{LOADER_RB}")
  p.package_files.include("#{LIB_DIR}/lib.rb")
end

desc "Packaging task of Ruby script provider."
provider_package_task = Rake::OXTPackageTask.new(SCRIPT_PROVIDER_PACKAGE_NAME, VERSION) do |p|
  p.package_files.include("#{LIB_DIR}/#{SCRIPT_PROVIDER_RB}")
end


# Templates

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


# Creates description.xml
def description_task(this_package_task, id, target, display_name)
  description_file = "#{this_package_task.package_dir_path}/description.xml"
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
def manifest_task(this_package_task, full_path, media_type)
  
  manifest_file = "#{this_package_task.package_dir_path}/META-INF/manifest.xml"
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


def registration_task(this_package_task, file_name, loader_name, uri, imple_name, services)
  components_f = "#{this_package_task.package_dir_path}/lib/#{file_name}"
  
  rm_f components_f if File.exists?(components_f)

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
def extension_description_task(this_package_task, desc) 
  path = "#{this_package_task.package_dir_path}/descriptions/desc.en"
  desc_dir = File.dirname(path)
  mkdir_p desc_dir unless File.exist?(desc_dir)
  open(path, "w") do |f|
    f.write(desc)
    f.flush
  end
end


file "#{LIB_DIR}/#{LOADER_RB}" => [] do |t|
  safe_ln "#{SRC_DIR}/#{LOADER_RB}", t.name
end

file "#{LIB_DIR}/lib.rb" => [] do |t|
  cp "#{SRC_DIR}/uno.rb", t.name
end


# ToDo platform
desc "Create files for the loader."
task :loader_misc => [PKG_DIR, "#{LIB_DIR}/#{LIB_DLL}", "#{LIB_DIR}/#{MODULE_DLL}", "#{LIB_DIR}/#{LOADER_DLL}", "#{LIB_DIR}/lib.rb"] do
  full_path = "lib/#{LOADER_REGISTRATION}"
  media_type = "application/vnd.sun.star.uno-components;platform=#{PLATFORM}"
      "#{LIB_DIR}/#{LOADER_DLL}"

  registration_task(loader_package_task, LOADER_REGISTRATION, 
      "com.sun.star.loader.SharedLibrary", LOADER_DLL, 
      LOADER_IMPLE_NAME, LOADER_SERVICE_NAMES)
  manifest_task(loader_package_task, full_path, media_type)
  description_task(loader_package_task, LOADER_PACKAGE_ID, target, LOADER_PACKAGE_DISPLAY_NAME)
  extension_description_task(loader_package_task, LOADER_PACKAGE_DESC)
end


file "#{LIB_DIR}/#{SCRIPT_PROVIDER_RB}" => [] do |t|
  safe_ln "#{SRC_DIR}/#{SCRIPT_PROVIDER_RB}", t.name
end


desc "Create files for the script provider."
task :provider_misc => [PKG_DIR] do
  media_type = "application/vnd.sun.star.uno-components"
  
  registration_task(provider_package_task, PROVIDER_REGISTRATION, 
      "com.sun.star.loader.Ruby", SCRIPT_PROVIDER_RB, 
      SCRIPT_PROVIDER_IMPLE_NAME, SCRIPT_PROVIDER_SERVICE_NAMES)
  manifest_task(provider_package_task, "lib/#{PROVIDER_REGISTRATION}", media_type)
  description_task(provider_package_task, PROVIDER_PACKAGE_ID, target, SCRIPT_PROVIDER_PACKAGE_DISPLAY_NAME)
  extension_description_task(provider_package_task, SCRIPT_PROVIDER_DESC)
end


spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = config['RUBY_PROGRAM_VERSION']
  s.summary = "Ruby-UNO native bridge."
  s.name = "rubyuno"
  s.version = VERSION
  s.requirements << 'none'
  s.author = "hanya"
  s.email = "hanya.runo@gmail.com"
  s.homepage = "https://github.com/hanya/RUNO"
  s.files = [
    "#{LIB_DIR}/uno.rb", 
    "#{LIB_UNO_DIR}/runo.so"
  ]
  s.extra_rdoc_files = FileList["#{DOC_DIR}/*.rd"]
  s.description = <<EOF
RubyUNO is native bridge between Ruby and UNO.
EOF
end

=begin
Rake::RDocTask.new do |rd|
  readme = "README.rd"
  rd.main = readme
  #rd.external = true
  rd.rdoc_files.include(readme, "#{DOC_DIR}/*.rd")
end
=end

task :rd_docs => [*HTML_DOCS] do |t|
end


loader_package = "#{PKG_DIR}/#{loader_package_task.zip_file}".intern
provider_package = "#{PKG_DIR}/#{provider_package_task.zip_file}".intern

file loader_package => [:loader_misc]
file provider_package => [:provider_misc]

file "#{LIB_DIR}/uno.rb" => [LIB_DIR] do |t|
  uno = IO.read("#{SRC_DIR}/uno.rb")
  connector = IO.read("#{SRC_DIR}/connector.rb")
  open("#{LIB_DIR}/uno.rb", "w") do |f|
    f.write uno
    f.write connector
    f.flush
  end
end

task :package => [:module, "#{LIB_DIR}/uno.rb"]

task :all => [
  :environment, :header, :package,  
  loader_package, provider_package, 
  :rd_docs
  ]

Rake::GemPackageTask.new(spec) do |pkg|
end

