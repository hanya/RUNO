
require 'mkmf'

sdk_home = ENV['OO_SDK_HOME']
ure_home = ENV['OO_SDK_URE_HOME']
base_program = ENV['OFFICE_BASE_PROGRAM_PATH']


cppumaker = find_executable('cppumaker')
unless cppumaker
  message "set path to the cppumaker of the OpenOffice.org SDK\n"
  exit
end

if sdk_home and ure_home and base_program and cppumaker

  office_types = "#{base_program}/offapi.rdb"
  sdk_include = "#{sdk_home}/include"
  stl_include = "#{sdk_include}/stl"
  
  host = Config::CONFIG['host']
  
  if host['linux']
    ure_types = "#{ure_home}/share/misc/types.rdb"
    gxx_include = ENV['SDK_GXX_INCLUDE_PATH']
    CC_DEFINES= "-fno-strict-aliasing -DUNX -DGCC -DLINUX -DCPPU_ENV=gcc3 -DGXX_INCLUDE_PATH=\"#{gxx_include}\""
    SDK_LIBS = " -luno_cppuhelpergcc3 -luno_cppu -luno_salhelpergcc3 -luno_sal -lstlport_gcc "
    URE_LIB = "#{ure_home}/lib"
  elsif host['mingw']
    # failed to resolve symbol of the cppu::defaultBootstrap_InitialComponentContext function.
    ure_types = "#{ure_home}/misc/types.rdb"
    CC_DEFINES = "-DWIN32 -DWNT -D_DLL -DCPPU_ENV=msci"
    SDK_LIBS = " icppuhelper.lib icppu.lib isalhelper.lib isal.lib stlport_vc71.lib"
    URE_LIB = "#{ure_home}/bin"
  elsif host['mswin']
    # illegal linking or needs to embed manifest
    ure_types = "#{ure_home}/misc/types.rdb"
    CC_DEFINES = "-Zc:forScope,wchar_t- -wd4251 -wd4275 -wd4290 -wd4675 -wd4786 -wd4800 -wd4273 -Zc:forScope -DWIN32 -DWNT -D_DLL -DCPPU_ENV=msci"
    SDK_LIBS = " icppuhelper.lib icppu.lib isalhelper.lib isal.lib stlport_vc71.lib"
    URE_LIB = "#{ure_home}/bin"
  else
    message "unknown host name.\n"
  end
  
  unless File.exist?('./include/flag')
    message "cppumaker creating include files from type libraries...\n"
    message "#{cppumaker} -Gc -BUCR -O./inc #{ure_types} #{office_types}\n"
    `"#{cppumaker}" -Gc -BUCR -O./include "#{ure_types}" "#{office_types}"`
    `echo > ./include/flag`
  end
  
  $INCFLAGS += " -I\"#{sdk_include}\" -I\"#{stl_include}\" -I./include #{CC_DEFINES}"
  $CFLAGS += " "

  $LOCAL_LIBS = "-L\"#{sdk_home}/lib\" -L\"#{URE_LIB}\" #{SDK_LIBS} "

  create_makefile 'runo'
else
  message "Run setsdkenv to set variables.\n"
end

