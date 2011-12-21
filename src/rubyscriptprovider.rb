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

# 
# When you want to execute a macro written in Ruby, 
# it should be placed under user_profile/Scripts/ruby directory.
module RubyScriptProvider
  LANGUAGE = "Ruby"
  NAME = "#{LANGUAGE}ScriptProvider"
  RB_EXTENSION = ".rb"
end

module LoggerForRubyScriptProvider
  
  PROVIDER_DEBUG_FLAG = "#{RubyScriptProvider::NAME}Debug"
  PROVIDER_DEBUG_OUTPUT = "#{PROVIDER_DEBUG_FLAG}Output"
  LOG_DEFAULT_PATH = "$(user)/temp/#{PROVIDER_DEBUG_OUTPUT}.txt"

  require 'logger'
  @@log = Logger.new(
    case ENV.fetch(LOADER_DEBUG_OUTPUT, "STDOUT")
    when "STDOUT"
      STDOUT
    when "FILE"
      Uno.to_system_path(
        Uno.get_component_context.getServiceManager.
          createInstanceWithContext(
            "com.sun.star.util.PathSubstitution", 
            Uno.get_component_context).
              substituteVariables(LOG_DEFAULT_PATH, true))
    else
      ENV.fetch(LOADER_DEBUG_OUTPUT)
    end
  )
  @@log.level = Logger.const_get(
      ENV.fetch(LOADER_DEBUG_FLAG, "ERROR").intern)
end


module RubyScriptProvider
  # keeps loaded scripts
  module RubyScripts
    @@scripts = {}
    
    # get(name, datetime) -> RubyScript|nil
    # Try to get script. If the script is updated, 
    # nil is returned. Otherwise found script is returned.
    def self.get(name, datetime)
      item = @@scripts[name]
      if item
        if item[:timestamp] >= datetime
          return item[:module]
        else
          @@scripts.delete(name)
          return nil
        end
      end
    end
    
    # add(name, datetime, capsule) -> Hash
    # Register new script with update time. 
    def self.add(name, datetime, capsule)
      @@scripts[name] = {:timestamp => datetime, :module => capsule}
    end
    
    # delete(name) -> Hash
    # Delete specific script.
    def self.delete(name)
      @@scripts.delete(name)
    end
    
    # get_script(storage, script_context, url, uri) -> RubyScript
    # Creates capsulated script.
    def self.get_script(storage, script_context, url, uri)
      script = nil
      capsule = nil
      file_name, func_name = url.to_url(uri)
      if storage.exists?(file_name)
        if file_name.start_with?(DOC_PROTOCOL)
          t = Time.new # avoide illegal error
        else
          t = RubyScripts.datetime_to_time(storage.modified_time(file_name))
        end
        capsule = RubyScripts.get(uri, t)
        unless capsule
          klass = Class.new
          klass.const_set(:XSCRIPTCONTEXT, script_context)
          text = storage.file_content(file_name)
          klass.class_eval(text, Uno.to_system_path(file_name))
          capsule = klass.new
          RubyScripts.add(uri, t, capsule)
        end
      end
      unless capsule
        ex = ScriptFrameworkErrorException.new(
                   "script not found", nil, uri, LANGUAGE, 2)
        raise ex
      end
      if capsule.public_methods(false).include?(func_name.intern)
        script = RubyScript.new(capsule, file_name, func_name)
      end
      return script
    end
    
    private 
    
    # datetime_to_time(dt) -> Time
    # Convert css.util.DateTime to Time.
    def self.datetime_to_time(dt)
      return Time.local(dt.Year, dt.Month, dt.Day, 
                    dt.Hours, dt.Minutes, dt.Seconds)
    end
  end

  Uno.require_uno 'com.sun.star.script.provider.XScriptContext'
  
  # class for XSCRIPTCONTEXT constant
  class ScriptContext
    include Uno::UnoBase
    include Uno::Com::Sun::Star::Script::Provider::XScriptContext
    
    def initialize(component_context, document, inv)
      @component_context = component_context
      @document = document
      @inv = inv
    end
    
    # XScriptContext
    def getComponentContext
      return @component_context
    end
    
    def getDocument
      return @document if @document
      return getDesktop.getCurrentComponent
    end
    
    def getDesktop
      return @component_context.getServiceManager.createInstanceWithContext(
          "com.sun.star.frame.Desktop", @component_context)
    end
    
    def getInvocationContext
      return @inv
    end
  end
end


module RubyScriptProvider
  
  DOC_PROTOCOL = "vnd.sun.star.tdoc:"
  
  # Macro URL.
  class URL
    EXPAND_PROTOCOL = "vnd.sun.star.expand:"
    
    def initialize(ctx, context, url)
      @ctx = ctx
      @context = context
      @url = url
      @url = helper.getRootStorageURI unless url
    end
    
    attr_reader :url, :context
    alias :to_s :url
    
    def create(url)
      return RubyScriptProvider::URL.new(@ctx, @context, url)
    end
    
    def helper
      return create_service("com.sun.star.script.provider.ScriptURIHelper", 
        [LANGUAGE, @context])
    end
    
    def absolutize
      return Uno.absolutize(@url, @url) rescue nil
      return @url
    end
    
    def transient?
      return @url.start_with?(DOC_PROTOCOL)
    end
    
    def basename(ext="")
      return File.basename(@url, ext)
    end
    
    def dirname
      return File.dirname(@url)
    end
    
    def to_uri(function_name=nil)
      url = @url
      url += "$" + function_name if function_name
      return helper.getScriptURI(url)
    end
    
    def join(a, b=nil)
      if b
        return a + b if a.end_with?("/")
        return "#{a}/#{b}"
      else
        return @url + a if @url.end_with?("/")
        return "#{@url}/#{a}"
      end
    end
    
    def expand(uri)
      url = @ctx.getValueByName(
           "/singletons/com.sun.star.util.theMacroExpander").expandMacros(uri)
      url[EXPAND_PROTOCOL] = ""
      url = Uno.absolutize(url, url) rescue nil
      url += "/" if uri.end_with?("/")
      return url
    end
    
    def to_url(uri)
      url = helper.getStorageURI(uri)
      n = url.rindex("$")
      return url[0..n-1], url[n+1..-1]
    end
    
    private
    
    # create_service(name, args=nil) -> obj
    # Create instance of service.
    def create_service(name, args=nil)
      return @ctx.getServiceManager.createInstanceWithArgumentsAndContext(
          name, args, @ctx) if args
      return @ctx.getServiceManager.createInstanceWithContext(name, @ctx)
    end
  end

  # Wrapper for file access.
  class Storage
    YAML_EXTENSION = '.yml'
    
    def initialize(ctx)
      @ctx = ctx
      @sfa = create_service("com.sun.star.ucb.SimpleFileAccess")
    end
    
    def modified_time(url)
      return @sfa.getDateTimeModified(url.to_s)
    end
    
    def exists?(url)
      return @sfa.exists(url.to_s)
    end
    
    def is_dir?(url)
      return @sfa.isFolder(url.to_s)
    end
    
    def is_readonly?(url)
      return @sfa.isReadOnly(url.to_s)
    end
    
    def rename(url, dest_url)
      @sfa.move(url, dest_url)
    end
    
    def delete(url)
      @sfa.kill(url.to_s)
      return true
    end
    
    def dir_contents(url)
      return @sfa.getFolderContents(url.to_s, true) if exists?(url)
      return []
    end
    
    def dir_create(url)
      @sfa.createFolder(url.to_s) unless exists?(url)
    end
    
    def file_create(url, name)
      dir_create(url)
      write_text(url.join(name))
    end
    
    def file_copy(source, dest, yaml=false)
      source = source.to_s
      dest = dest.to_s
      if @sfa.exists(source)
        source_input = @sfa.openFileRead(source)
        @sfa.kill(dest) if @sfa.exists(dest)
        @sfa.writeFile(dest, source_input)
        source_input.closeInput
        if yaml
          yaml_source = source[0..-File.extname(source).length-1] + 
                YAML_EXTENSION
          if @sfa.exists(yaml_source)
            yaml_dest = dest[0..-File.extname(dest).length-1] + 
                YAML_EXTENSION
            file_copy(yaml_source, yaml_dest)
          end
        end
      end
    end
    
    def write_text(url, text="")
      file_url = url.to_s
      text_output = create_service("com.sun.star.io.TextOutputStream")
      if url.start_with?(DOC_PROTOCOL)
        pipe = create_service("com.sun.star.io.Pipe")
        text_output.setOutputStream(pipe)
        text_output.writeString(text)
        text_output.closeOutput
        @sfa.writeFile(file_url, pipe)
        pipe.closeInput
      else
        file_output = @sfa.openFileWrite(file_url)
        text_output.setOutputStream(file_output)
        text_output.writeString(text)
        text_output.flush()
        file_output.closeOutput
      end
    end
    
    def choose_file
      scripts_dir = create_service("com.sun.star.util.PathSubstitution")
          .substituteVariables("$(user)/Scripts/#{LANGUAGE.downcase}", true)
      picker = create_service("com.sun.star.ui.dialogs.FilePicker")
      picker.appendFilter("All Files (*.*)", "*.*")
      picker.appendFilter(
         "#{LANGUAGE} Files (*#{RB_EXTENSION})", "*#{RB_EXTENSION}")
      picker.setCurrentFilter("All Files (*.*)")
      picker.setDisplayDirectory(scripts_dir)
      picker.setMultiSelectionMode(false)
      picker.getFiles[0] if picker.execute > 0
    end
    
    def file_content(url)
      lines = []
      text_input = create_service("com.sun.star.io.TextInputStream")
      text_input.setInputStream(@sfa.openFileRead(url.to_s))
      lines << text_input.readLine until text_input.isEOF
      text_input.closeInput
      return lines.join("\n")
    end
    
    def descriptions(url)
      require 'yaml'
      ret = nil
      yaml_url = url.join(url.dirname, 
              url.basename(RB_EXTENSION) + YAML_EXTENSION)
      if exists?(yaml_url)
        text = file_content(yaml_url)
        ret = YAML.load(text) rescue nil
      end
      ret = {} unless ret
      return ret
    end
    
    # try to find public methods from sexp tree
    def get_method_names(url)
      require 'ripper'
      text = file_content(url)
      result = Ripper.sexp(text, url.to_s)
      method_defs = []
      if result.length == 2 && result[0] == :program
        is_public = true
        result[1].each do |item|
          case item[0]
          when :def
            ident = find_item(item, :@ident)
            if ident
              if is_public
                method_defs << ident
              else
                method_defs.delete(ident)
              end
            end
          when :command
            ident = find_item(item, :@ident)
            case ident
            when "private", "protected", "public"
              block = find_item(item, :args_add_block)
              items = get_symbol_literals(block)
              if ident == "public"
                method_defs.concat(items)
              else
                items.each do |i|
                  method_defs.delete(i)
                end
              end
            end
          when :var_ref
            ident = find_item(item, :@ident)
            is_public = ident == "public" if ident
          end
        end
        method_defs.uniq!
      end
      return method_defs
    end
    
    private
    
    def find_item(args, type)
      found = args[1..-1].assoc(type)
      return found[1] if found
    end
    
    def get_symbol_literals(args)
      founds = []
      args.each do |i|
        if i[0] == :symbol_literal
          ident = find_item(i[1], :@ident)
          founds << ident if ident
        end
      end
      return founds
    end
    
    def create_service(name)
      return @ctx.getServiceManager.createInstanceWithContext(name, @ctx)
    end
  end
  
  Uno.require_uno 'com.sun.star.task.XInteractionHandler'
  Uno.require_uno 'com.sun.star.ucb.XProgressHandler'
  Uno.require_uno 'com.sun.star.ucb.XCommandEnvironment'
  
  class DummyInteractionHandler
    include Uno::UnoBase
    include Uno::Com::Sun::Star::Task::XInteractionHandler
    
    def handle(request)
    end
  end
  
  class DummyProgressHandler
    include Uno::UnoBase
    include Uno::Com::Sun::Star::Ucb::XProgressHandler
    
    def push(status)
    end
    
    def update(status)
    end
    
    def pop
    end
  end
  
  class CommandEnvironment
    include Uno::UnoBase
    include Uno::Com::Sun::Star::Ucb::XCommandEnvironment
    
    def initialize
      @interaction_handler = DummyInteractionHandler.new
      @progress_handler = DummyProgressHandler.new
    end
    
    def getInteractionHandler
      return @interaction_handler
    end
    
    def getProgressHandler
      return @progress_handler
    end
  end
  
  Property = Uno.require_uno 'com.sun.star.beans.Property'
  Command = Uno.require_uno 'com.sun.star.ucb.Command'
  
  # get_document_model(ctx, uri) -> obj
  # Get document model from internal uri.
  def self.get_document_model(ctx, uri)
    doc = nil
    smgr = ctx.getServiceManager
    ucb = smgr.createInstanceWithArgumentsAndContext(
        "com.sun.star.ucb.UniversalContentBroker", ["Local", "Office"], ctx)
    identifier = ucb.createContentIdentifier(uri)
    content = ucb.queryContent(identifier)
    property = Property.new("DocumentModel", -1, Uno.get_type("void"), 1)
    command = Command.new(
        "getPropertyValues", -1, 
        Uno::Any.new("[]com.sun.star.beans.Property", [property]))
    env = CommandEnvironment.new
    begin
      result_set = content.execute(command, 0, env)
      doc = result_set.getObject(1, nil)
    rescue => e
      p e.to_s + "\n" + e.backtrace.join("\n") + "\n"
    end
    return doc
  end
  
  # get_context(ctx, doc) -> obj
  # Get document context.
  def self.get_context(ctx, doc)
    return ctx.getServiceManager.createInstanceWithContext(
            "com.sun.star.frame.TransientDocumentsDocumentContentFactory", ctx).
            createDocumentContent(doc).getIdentifier.getContentIdentifier
  end
end

module RubyScriptProvider
  
  Uno.require_uno 'com.sun.star.beans.XPropertySet'
  Uno.require_uno 'com.sun.star.container.XNameContainer'
  Uno.require_uno 'com.sun.star.lang.XServiceInfo'
  Uno.require_uno 'com.sun.star.script.browse.XBrowseNode'
  Uno.require_uno 'com.sun.star.script.provider.XScriptProvider'
  Uno.require_uno 'com.sun.star.script.provider.XScript'
  Uno.require_uno 'com.sun.star.script.XInvocation'
  ScriptFrameworkErrorException = Uno.require_uno(
        "com.sun.star.script.provider.ScriptFrameworkErrorException")
  RuntimeException = Uno.require_uno(
        "com.sun.star.uno.RuntimeException")
  BrowseNodeTypes = Uno.require_uno(
        "com.sun.star.script.browse.BrowseNodeTypes")
  
  # base node for all script nodes
  class BaseNode
    include Uno::UnoBase
    include Uno::Com::Sun::Star::Script::Browse::XBrowseNode
    include Uno::Com::Sun::Star::Script::XInvocation
    include Uno::Com::Sun::Star::Beans::XPropertySet
    
    NODE_TYPE = BrowseNodeTypes::CONTAINER
    
    def initialize(url, storage, name)
      @url = url
      @storage = storage
      @name = name
      context = @url.context
      @editable = (context == "user" || context.start_with?(DOC_PROTOCOL))
    end
    
    attr_reader :name, :editable
    
    def update(name, url)
      @name = name
      @url = url
    end
    
    # XBrowseNode
    alias :getName :name
    
    def getChildNodes
      return []
    end
    
    def hasChildNodes
      return true
    end
    
    def getType
      return self.class::NODE_TYPE
    end
    
    # XInvocation
    def getIntrospection
      return nil
    end
    
    def setValue(name, value)
    end
    
    def getValue(name)
      return nil
    end
    
    def hasMethod(name)
      return false
    end
    
    def hasProperty(name)
      return false
    end
    
    def invoke(name, arg1, arg2, arg3)
      return [false, [0], [nil]]
    end
    
    # XPrpertySet
    def getPropertySetInfo
      return nil
    end
    
    def addPropertyChangeListener(name, listener)
    end
    
    def removePropertyChangeListener(name, listener)
    end
    
    def addVetoableChangeListener(name, listener)
    end
    
    def removeVetoableChangeListener(name, listener)
    end
    
    def setPropertyValue(name, value)
    end
    
    def getPropertyValue(name)
      return nil
    end
    
    def rename(name)
      url = @url.join(@url.dirname, name)
      @storage.rename(@url, url)
      return url
    end
  end
  
  # 
  class ScriptBrowseNode < BaseNode
    NODE_TYPE = BrowseNodeTypes::SCRIPT
    
    def initialize(url, storage, name, func_name, description)
      super(url, storage, name)
      @func_name = func_name.to_s
      @description = description.to_s
    end
  
    def getPropertyValue(name)
      case name
      when "URI"
        return @url.to_uri(@func_name)
      when "Description"
        return @description
      when "Editable"
        return false
      end
    end
  end
  
  # describes file
  class FileBrowseNode < BaseNode
  
    def initialize(url, storage, name)
      super(url, storage, name)
    end
    
    def parse_entry(entry)
      begin
        return entry["name"], entry["description"]
      rescue
        return "", ""
      end
    end
    
    def getChildNodes
      result = []
      if @storage.exists?(@url)
        begin
          file_name = @url.basename
          descriptions = @storage.descriptions(@url)
          @storage.get_method_names(@url).each do |name|
            display_name, description = parse_entry(descriptions[name])
            display_name = name if display_name.empty?
            result << ScriptBrowseNode.new(
                    @url, @storage, display_name, name, description)
          end
        rescue => e
          p e.to_s + "\n" + e.backtrace.join("\n") + "\n"
        end
      end
      return result
    end
    
    def getPropertyValue(name)
      ret = false
      case name
      when "Renamable", "Deletable"
        ret = ! @storage.is_readonly?(@url)
      when "Editable"
        ret = @url.transient? && ! @storage.is_readonly?(@url)
      end
      return ret
    end
    
    def invoke(name, args, arg2, arg3)
      value = false
      begin
        case name
        when "Editable"
          # push yaml file too if there
          source = @storage.choose_file
          @storage.file_copy(source, @url, true) if source
        when "Renamable"
            name = args[0]
            name += RB_EXTENSION unless name.end_with?(RB_EXTENSION)
            dest = rename(name)
            update(name, dest)
            value = self
        when "Deletable"
            value = @storage.delete(@url)
        end
      rescue => e
        p %Q!#{e}\n#{e.backtrace.join("\n")}\n!
      end
      return [value, [0], [nil]]
    end
  end
  
  # describes directory
  class DirBrowseNode < BaseNode
    
    def initialize(url, storage, name)
      super(url, storage, name)
    end
    
    def getChildNodes
      ret = []
      begin
      if @storage.exists?(@url)
        @storage.dir_contents(@url).sort!.each do |name|
          url = @url.create(name)
          if @storage.is_dir?(url)
            ret << DirBrowseNode.new(url, @storage, url.basename)
          elsif File::extname(name) == RB_EXTENSION
            ret << FileBrowseNode.new(url, @storage, url.basename(RB_EXTENSION))
          end
        end
      end
      rescue => e
        p e
      end
      return ret
    end
    
    def getPropertyValue(name)
      ret = false
      case name
      when "Renamable", "Deletable", "Creatable"
        ret = ! @storage.is_readonly?(@url)
      end
      return ret
    end
    
    def invoke(name, args, arg2, arg3)
      value = false
      begin
        case name
        when "Creatable"
          name = args[0]
          if name.end_with?("/")
            name = name[0..-2]
            url = @url.create(@url.join(name))
            @storage.dir_create(url)
            node = DirBrowseNode.new(url, @storage, name)
          else
            name += RB_EXTENSION unless name.end_with?(RB_EXTENSION)
            url = @url.create(@url.join(name))
            @storage.file_create(@url, name)
            node = FileBrowseNode.new(url, @storage, url.basename(RB_EXTENSION))
          end
          value = node
        when "Renamable"
          name = args[0]
          dest = rename(name)
          update(name, dest)
          value = self
        when "Deletable"
          value = @storage.delete(@url)
        end
      rescue => e
        p e, e.backtrace.join("\n")
      end
      return [value, [0], [nil]]
    end
  end
  
  module PackageManager
    PACKAGE_REGISTERED = "extensions-ruby.txt"
    
    def package_manager_init(ctx, context)
      @context = context
      @file_path = ctx.getServiceManager.createInstanceWithContext(
        "com.sun.star.util.PathSubstitution", ctx).substituteVariables(
        "$(user)/Scripts/#{PACKAGE_REGISTERED}", true)
      @packages = {}
      load_registerd
    end
    
    def packages
      packages = {}
      @packages.each do |name, state|
        if state
          if name.find("USER")
            storage = "user"
          else
            storage = @context
          end
          if storage == @context
            url = @url.expand(name)
            packages[url] = File::basename(url)
          end
        end
      end
      return packages
    end
    
    # XNameContainer
    def hasByName(name)
      return @packages.has_key?(name)
    end
    
    def insertByName(name, value)
      @packages[name] = value.getName
      store_registered
    end
    
    def removeByName(name)
      @packages.delete(name)
      store_registered
    end
    
    def replaceByName(name, value)
      @packages[name] = value.getName
    end
    
    def getByName(name)
      return nil
    end
    
    def getElementNames
      return []
    end
    
    def getElementType
      return Uno.get_type("void")
    end
    
    def hasElements
      return false
    end
    
    private
    
    def has_scripts?(url)
      @storage.dir_contents(url).each do |name|
        if @storage.is_dir?(name)
          return true if has_scripts?(name)
        elsif name.end_with(RB_EXTENSION)
          return true
        end
      end
      return false
    end
    
    def load_registerd
      if File.exist?(@file_path)
        @packages.clear
        lines = IO.readlines(@file_path)
        lines.each do |name|
          name.strip!
          unless name.empty?
            url = @url.expand(name)
            @packages[name] = has_scripts?(url)
          end
        end
      end
    end
    
    def store_registered
      if File.writable?(File::dirname(@file_path))
        open(@file_path, "w") do |f|
          f.write(@packages.keys.join("\n"))
        end
      end
    end
  end
  
  # package node is read-only
  class PackageBrowseNode < DirBrowseNode
    def initialize(url, storage, name, manager)
      super(url, storage, name)
      @manager = manager
    end
    
    def getChildNodes
      ret = []
      @manager.packages.each do |url, name|
        ret << DirBrowseNode.new(@url.create(url), @storage, name)
      end
      return ret
    end
    
    def getPropertyValue(name)
      return false
    end
    
    def invoke(name, args, arg2, arg3)
      return [false, [0], [nil]]
    end
  end
  
 
  # Executes script.
  class RubyScript
    include Uno::UnoBase
    include Uno::Com::Sun::Star::Script::Provider::XScript
    
    def initialize(capsule, file_name, func_name)
      @capsule = capsule
      @file_name = file_name
      @func_name = func_name
    end
    
    def invoke(args, param_index, out_params)
      ret = nil
      begin
        m = @capsule.method(@func_name)
        if m
          ret = m.call(*args)
        end
      rescue Uno::UnoError => e
        trace = e.backtrace
        trace.unshift(trace[0].gsub(
            /`[^']*'/, "\`#{e.uno_method}'")) if e.respond_to? :uno_method
        trace.pop(2)
        e.uno_exception.Message += "\nError during invoking method: \n" + 
            "Script: #{@func_name}\n" + 
            "File: #{@file_name}\nType: #{e.type_name}" + "\n\n" + 
            %Q!#{e.uno_exception}\n#{trace.join("\n")}\n!
        raise
      rescue => e
        ex = RuntimeException.new(
                 %Q!\n#{e}\n#{e.backtrace.join("\n")}\n!, self)
        raise Uno::UnoError, ex
      end
      return [ret, [0], [nil]]
    end
  end
  
  # The script provider for Ruby.
  class ScriptProviderImpl < BaseNode
    include Uno::UnoComponentBase
    include Uno::Com::Sun::Star::Script::Provider::XScriptProvider
    include Uno::Com::Sun::Star::Lang::XServiceInfo
    include Uno::Com::Sun::Star::Container::XNameContainer
  
    IMPLE_NAME = "mytools.script.provider.ScriptProviderForRuby"
    SERVICE_NAMES = [
           "com.sun.star.script.provider.ScriptProviderForRuby", 
           "com.sun.star.script.provider.LanguageScriptProvider"]
    NODE_TYPE = BrowseNodeTypes::ROOT
    
    def initialize(ctx, args)
      @name = RubyScriptProvider::LANGUAGE
      doc = nil
      inv = nil
      is_package = false
      context = ""
      
      if args[0].kind_of?(String)
        context = args[0]
        is_package = context.end_with?(":uno_packages")
        doc = RubyScriptProvider.get_document_model(ctx, context) if 
                       context.start_with?(DOC_PROTOCOL)
      else
        inv = args[0]
        doc = inv.ScriptContainer
        context = RubyScriptProvider.get_context(ctx, doc)
      end
      @script_context = ScriptContext.new(ctx, doc, inv)
      @url = URL.new(ctx, context, nil)
      @storage = Storage.new(ctx)
      if is_package
        self.extend PackageManager
        package_manager_init(ctx, context)
        @node = PackageBrowseNode.new(@url, @storage, LANGUAGE, self)
      else
        @node = DirBrowseNode.new(@url, @storage, LANGUAGE)
      end
    end
    
    def getChildNodes
      @node.getChildNodes
    end

    def getScript(uri)
      begin
        script = RubyScripts.get_script(@storage, @script_context, @url, uri)
        return script
      rescue StandardError, ScriptError => e
        ex = ScriptFrameworkErrorException.new(
               %Q!\n#{e.message}\n#{e.backtrace.join("\n")}\n!, 
               nil, uri, LANGUAGE, 0)
        raise Uno::UnoError, ex
      end
    end

    def invoke(name, params, arg2, arg3)
      result = [false, [0], [nil]]
      case name
      when "Creatable"
        result = @node.invoke(name, params, arg2, arg3)
      end
      return result
    end

    def getPropertyValue(name)
      case name
      when "Creatable"
        return @node.editable
      end
      return false
    end
  end
end

