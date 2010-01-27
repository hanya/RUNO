
require 'runo'

require 'open3'

module Runo
  # do not confuse local and remote context.
  @@connected = false
  @@local_context = Runo.get_component_context
  @@remote_context = nil
  PS_POSSIZE = Runo.uno_require('com.sun.star.awt.PosSize.POSSIZE')
  Runo.uno_require('com.sun.star.lang.XTypeProvider')
  
  class << self
    # Returns component context.
    def local_context
      @@local_context
    end
    # Set component context.
    def local_context=(ctx)
      @@local_context = ctx
    end
    def connected?
      @@connected
    end
    def connected(remote_ctx)
      @@connected = true
      @@remote_context = remote_ctx
    end
    def remote_context
      @@remote_context
    end
  end

  # Connecting to OpenOffice.org.
  module Connector
    class << self
      # Create UnoUrlResolver instance.
      def create_resolver
        local_ctx = Runo.local_context
        smgr = local_ctx.getServiceManager
        smgr.createInstanceWithContext(
            'com.sun.star.bridge.UnoUrlResolver', local_ctx)
      end
  
      # connect to the instance described by the uno_url
      def connect(uno_url, resolver=nil)
        unless resolver
          resolver = create_resolver
        end
        ctx = resolver.resolve(uno_url)
        if ctx
          Runo.connected(ctx)
        end
        ctx
      end
  
      #  Start OpenOffice.org and connect to it and component context 
      #  is returned if successed.
      #  If the office is in the remote host, it cannot be boot.
      #  @param [String] office path to the OpenOffice.org
      #  @param [String] connection_type can be socket or pipe
      #  @param [Hash] args defines arguments for UNO URL
      #         These values are allowed for the socket connection.
      #         host: the host name of the office to connect.
      #         port: port number of the office listening
      #         tcpNoDelay: delay for the each call
      #         The value can be passed for pipe connection.
      #         name: name of the pipe to share the data
      #         Additional parameters for execution of the office.
      #         interval: execution interval
      #         multiply: time to retry
      def bootstrap(office="soffice", connection_type='socket', args={})
        if connection_type == 'socket'
          host = args.fetch('host', 'localhost') # 129.0.0.1
          port = args.fetch('port', '2083').to_s
          tcpNoDelay = args.fetch('tcpNoDelay', '0')
          template = 'socket,host=%s,port=%s' % [host, port]
          template2 = tcpNoDelay ? (template + ',tcpNoDelay=%s' % tcpNoDelay) : template
        elsif connection_type == 'pipe'
          pipe_name = args.fetch('name', 'rubypipe')
          template2 = template = 'pipe,name=%s' % pipe_name
          template = template2
        else
          raise ArgumentError, "unknown connection type (%s)" % connection_type
        end
        uno_url = "uno:#{template2};urp;StarOffice.ComponentContext"
        argument = "-accept=#{template};urp;StarOffice.ServiceManager"
        interval = args.fetch('interval', 3.0).to_f
        multiply = args.fetch('multiply', 5).to_i

        ctx = nil
        resolver = create_resolver
        i = 1
        while i < multiply
          begin
            ctx = resolver.resolve(uno_url)
            if ctx
              break
            end
          rescue
              Open3.popen3(office + " '" + argument + "'")
              sleep(interval)
          end
          i += 1
        end
        if ctx
          Runo.connected(ctx)
        end
        ctx
      end
    end
  end
  
  # If bridge is not connected to remote service, desktop returnes 
  # in-functional one.
  def Runo.get_desktop
    if Runo.connected?
      ctx = Runo.remote_context
      smgr = ctx.getServiceManager
      smgr.createInstanceWithContext('com.sun.star.frame.Desktop', ctx)
    end
  end
  
  #  Shows message.
  #  @message [String] message to shown
  #  @title [String] title for the message box
  #  @param [String] type can be messbox, infobox, warningbox, errorbox or querybox.
  #  @param [Fixnum] buttons is combination of constants css.awt.MessageBoxButtons.
  #  @return [Fixnum] depends pushed button, cancel: 0, ok: 1, yes: 2, no: 3, abort: 0, retry: 4, ignore: 5
  def Runo.msgbox(message='', title='', type='messbox', buttons=1)
    desktop = get_desktop
    if desktop
      frame = desktop.getActiveFrame
      if frame
        rectangle = uno_require('com.sun.star.awt.Rectangle')
        window = frame.getContainerWindow
        toolkit = window.getToolkit
        messagebox = toolkit.createMessageBox(
            window, rectangle.new, type, buttons, title, message)
        messagebox.execute
      end
    end
  end
  
  @@uno_types = {}
  # construct type information of the class of the instance.
  # all interface classes are retaines their own interface name as a 
  # constant named TYPENAME.  
  def Runo.get_handle(obj)
    if @@uno_types.key?(obj.class)
      @@uno_types[obj.class]
    else
      types = {}
      for i in obj.class.ancestors#[0..-3]
        name = i.const_get('TYPENAME') if i.const_defined?('TYPENAME')
        if name #and Runo.interface?(name)
          types[name] = Runo::Type.new(name)
        end
      end
      @@uno_types[obj.class] = [types.values, Runo.uuid]
    end
  end
  
  # base module that is used to define UNO component, just include 
  # this module like the following:
  #   class MyListener
  #      include Runo::Base
  #      include ...other interfaces
  #   end
  # adapter needs to know types (interfaces) are implemented by the 
  # component, therefore methods of this module provide it.
  module Base
    include Runo::Com::Sun::Star::Lang::XTypeProvider
    # returns list of types in Runo::Type.
    def getTypes
      Runo.get_handle(self)[0]
    end
    
    # returns uuid for the instance.
    def getImplementationId
      Runo.get_handle(self)[1]
    end
  end
end




