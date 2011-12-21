# coding: utf-8
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

module RubyLoader
  NAME = "RubyLoader"
  
  LOADER_DEBUG_FLAG = "#{RubyLoader::NAME}Debug"
  LOADER_DEBUG_OUTPUT = "#{LOADER_DEBUG_FLAG}Output"
  LOG_DEFAULT_PATH = "$(user)/temp/#{LOADER_DEBUG_FLAG}.txt"
  if ENV[LOADER_DEBUG_OUTPUT]
    require 'logger'
    @@log = Logger.new(
      case ENV.fetch(LOADER_DEBUG_OUTPUT, "STDOUT")
      when "STDOUT"
        STDOUT
      when "STDERR"
        STDERR
      when "FILE"
        Uno.to_system_path(Uno.get_component_context.getServiceManager.
          createInstanceWithContext("com.sun.star.util.PathSubstitution", 
            Uno.get_component_context).
              substituteVariables(LOG_DEFAULT_PATH, true))
      else
        ENV.fetch(LOADER_DEBUG_OUTPUT)
      end
    )
    @@log.level = Logger.const_get(
        ENV.fetch(LOADER_DEBUG_FLAG, "ERROR").intern)
  else
    class DummyLogger
      def null_out(progname=nil, &b)
      end
      
      def out(progname=nil, &b)
        if b
          puts "#{progname} -- #{b()}"
        else
          puts b()
        end
        true
      end
      
      alias :log :null_out
      alias :debug :null_out
      alias :warn :null_out
      alias :error :out
      alias :fatal :out
    end
    @@log = DummyLogger.new
  end
  
  def self.log
    return @@log
  end
end

module Uno
  require_uno 'com.sun.star.lang.XServiceInfo'
  
  # All UNO components should be include UnoComponentBase module 
  # to its class and define two constants for it. If your class 
  # include css.lang.XServiceInfo module also, they are used to provide 
  # service information of your component.
  # IMPLE_NAME: implementation name of the component, have to be defined 
  #             on herself.
  # SERVICE_NAMES: Array of supported service names.
  module UnoComponentBase
    # IMPLE_NAME = ""
    # SERVICE_NAMES = []
  end
  
  # Provides XServiceInfo interface from two constants.
  # IMPLE_NAME is its implementation name in String.
  # SERVICE_NAMES is supported service names of the component 
  # in Array of String.
  module Com::Sun::Star::Lang::XServiceInfo
    def getImplementationName
      return self.class::IMPLE_NAME
    end
    
    def supportsService(name)
      return self.class::SERVICE_NAMES.include? name
    end
    
    def getSupportedServiceNames
      return self.class::SERVICE_NAMES
    end
  end
end

# Loads implementations which are written in Ruby.
module RubyLoader
  
  Uno.require_uno 'com.sun.star.uno.Exception'
  Uno.require_uno 'com.sun.star.lang.XSingleComponentFactory'
  Uno.require_uno 'com.sun.star.loader.XImplementationLoader'
  
  def self.error_to_str(e)
    return %Q!#{e}\n#{e.backtrace.join("\n")}\n!
  end
  
  # Component factory class wraps your class which implements 
  # UNO component.
  class SingleComponentFactory
    include Uno::UnoBase
    include Uno::Com::Sun::Star::Lang::XServiceInfo
    include Uno::Com::Sun::Star::Lang::XSingleComponentFactory
    
    def initialize(klass, imple_name, url)
      @klass = klass
      @imple_name = imple_name
      @url = url
    end
    
    # XSingleComponentFactory
    def createInstanceWithContext(ctx)
      begin
        load_class unless @klass
        return @klass.new(ctx)
      rescue => e
        RubyLoader.log.error(@klass.to_s) {
          "Error raised at #{self.class.name}##{__method__}\n" + 
          RubyLoader.error_to_str(e)}
        raise
      end
    end
    
    # Generaly, this method instantiate the class and 
    # calls css.lang.XInitialization#initialize method.
    # But Ruby's initialize method is special one. 
    # Therefore additional arguments are passed as second one.
    def createInstanceWithArgumentsAndContext(args, ctx)
      begin
        load_class unless @klass
        return @klass.new(ctx, args)
      rescue => e
        RubyLoader.log.error(@klass.to_s) {
          "Error raised at #{self.class.name}##{__method__}\n" + 
          RubyLoader.error_to_str(e)}
        raise
      end
    end
    
    # XServiceInfo
    
    def getImplementationName
      return @klass::IMPLE_NAME if @klass
      return @imple_name
    end
    
    def supportsService(name)
      return @klass::SERVICE_NAMES.include?(name)
    end
    
    def getSupportedServiceNames
      return @klass::SERVICE_NAMES if @klass
      return []
    end
    
    private
    
    # load_class -> Class
    # Load class from the file which implements components.
    def load_class
      begin
        @klass = REGISTERED.get_imple(@klass, @url, @imple_name)
      rescue => e
        # missing file, syntax error, load error and so on
        message = "#{@imple_name} was not found in #{@url}. " + 
            RubyLoader.error_to_str(e)
        puts message
        RubyLoader.log.error(@klass.to_s) {message}
        ex = Uno::Com::Sun::Star::Uno::Exception.new(message, nil)
        raise Uno::UnoError, ex
      end
      unless @klass
        ex = Uno::Com::Sun::Star::Uno::Exception.new(
            "#{@imple_name} was not found in #{@url}", nil)
        raise Uno::UnoError, ex
      end
    end
  end
  
  # keeps loaded modules of UNO components
  REGISTERED = {}
  class << REGISTERED
    
    EXPAND_PROTOCOL = "vnd.sun.star.expand:"
    
    # get_imple(ctx, url, imple_name) -> Class
    # Load file and get implementation as an class.
    def get_imple(ctx, url, imple_name)
      klass = find_imple(imple_name, url)
      unless klass
        mod = load_as_module(ctx, url)
        register_module(url, mod)
        klass = find_imple(url, imple_name)
      end
      return klass
    end
    
    private
    
    # load_as_module(ctx, url) -> Module
    # Loads file content into a module with eval.
    def load_as_module(ctx, url)
      path = get_path(ctx, url)
      mod = Module.new
      mod.module_eval(IO.read(path), path)
      return mod
    end
    
    # register_module(url, mod) -> obj
    # Register new module at url.
    def register_module(url, mod)
      REGISTERED[url] = mod
    end
    
    # find_imple(url, imple_name) -> Class|nil
    # Find implementation from the file.
    def find_imple(url, imple_name)
      klass = nil
      mod = REGISTERED[url]
      if mod
        get_component_classes(mod).each do |imple|
          if imple.const_defined?(:IMPLE_NAME) && 
             imple.const_defined?(:SERVICE_NAMES) && 
             imple.const_get(:IMPLE_NAME) == imple_name
            klass = imple
            break
          end
        end
      end
      return klass
    end
    
    # get_component_classes(mod) -> [Class]
    # Find all classes includes Uno::ComponentBase module from module.
    def get_component_classes(mod)
      klasses = []
      mod.constants.each do |item|
        c = mod.const_get(item)
        if c.instance_of?(Module)
          klasses.concat(get_component_classes(c))
        elsif c.instance_of?(Class) && 
              c.ancestors.include?(Uno::UnoComponentBase)
          klasses << c
        end
      end
      return klasses
    end
    
    # get_path(ctx, url) -> String
    # Make expanded url.
    def get_path(ctx, url)
      if url.start_with?(EXPAND_PROTOCOL)
        url = ctx.getValueByName(
            "/singletons/com.sun.star.util.theMacroExpander").expandMacros(url)
        url[EXPAND_PROTOCOL] = ""
      end
      return Uno.to_system_path(url)
    end
  end

  # This class is refered from C++ loader implementation.
  class RubyLoaderImpl
    include Uno::UnoBase
    include Uno::Com::Sun::Star::Loader::XImplementationLoader
    include Uno::Com::Sun::Star::Lang::XServiceInfo
    
    IMPLE_NAME = "mytools.loader.Ruby"
    SERVICE_NAMES = ["com.sun.star.loader.Ruby"]
    
    def initialize(ctx)
      @ctx = ctx
    end
    
    # XImplementationLoader
    def activate(imple_name, ignored, url, key)
      return SingleComponentFactory.new(nil, imple_name, url)
    end
    
    # this method is no longer required
    def writeRegistryInfo(key, ignored, url)
      return true
    end
  end
end
