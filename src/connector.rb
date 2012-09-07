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

module Uno
  require_uno 'com.sun.star.connection.NoConnectException'
  require_uno 'com.sun.star.connection.ConnectionSetupException'
  
#
# Helps to connect to the office by RPC with UNO protocol.
# 
# These environmental variables should be set before to load 'runo' 
# module.
# URE_BOOTSTRAP specifies to fundamental(rc|.ini) placed under 
#   openoffice.org3/program directory.
# LD_LIBRARY_PATH path to URE library and program directory of the office. 
# 
  module Connector
  
    class NoConnectionError < StandardError
    end
    
    PIPE_NAME_PREFIX = "rubypipe_"
    
    @@sleep_time = 2.0
    @@retry = 5
    
    attr_accessor :sleep_time, :retry
    
    # Read Professional UNO chapter of Developer's Guide about 
    # UNO Remote protocol.
    def self.bootstrap(office="soffice", type="socket", 
         host="localhost", port=2083, pipe_name=nil, nodelay=false)
      url, argument = self.url_construct(type, host, port, pipe_name, nodelay)
      c = nil
      n = 0
      begin
        c = self.connect(url)
      rescue Uno::Com::Sun::Star::Uno::Exception => e
        raise e if e.uno_instance_of?(
            Uno::Com::Sun::Star::Connection::ConnectionSetupException)
        n += 1
        (raise NoConnectionError,"") if n > @@retry
        spawn(ENV, office, argument)
        sleep(@@sleep_time)
        retry
      end
      return c
    end
    
    def self.connect(data=nil, bridge_name=nil)
      if data.kind_of?(String)
        data = data[4..-1] if data.start_with?('uno:')
        description, protocol, object = data.split(';')
      elsif !data.kind_of?(Hash)
        data = {'type' => 'pipe', 'name' => 'rubypipe', 
                'protocol' => 'urp', 'object' => 'StarOffice.ComponentContext'}
        #data = {'type' => 'socket', 'host' => 'localhost', 'port' => 2082, 
        #        'protocol' => 'urp', 'object' => 'StarOffice.ComponentContext'}
      end
      if data.kind_of?(Hash)
        contype = data.fetch('type', 'pipe')
        if contype == 'pipe'
          description = "pipe,name=#{data.fetch('name')}"
        elsif contype == 'socket'
          description = "socket,host=#{data.fetch('host')},port=#{data.fetch('port')}"
        else
          raise "Illegal connection type is specified #{contype}"
        end
        protocol = data.fetch('protocol', 'urp')
        object = data.fetch('object', 'StarOffice.ComponentContext')
        bridge_name = data.fetch('bridge_name', bridge_name || "")
      end
      bridge_name = bridge_name.to_s
      local_ctx = Uno.get_component_context
      local_smgr = local_ctx.getServiceManager
      connector = local_smgr.createInstanceWithContext(
                    "com.sun.star.connection.Connector", local_ctx)
      connection = connector.connect(description)
      factory = local_smgr.createInstanceWithContext(
                    "com.sun.star.bridge.BridgeFactory", local_ctx)
      bridge = factory.createBridge(bridge_name, protocol, connection, nil)
      return bridge.getInstance(object)
    end
    
    def self.url_construct(type="socket", 
         host="localhost", port=2083, pipe_name=nil, nodelay=false)
      case type
      when "socket"
        part = "socket,host=#{host},port=#{port}," +
                  "tcpNoDelay=#{nodelay ? 1 : 0};urp;"
        url = "uno:#{part}StarOffice.ComponentContext"
        argument = "-accept=#{part}StarOffice.ServiceManager"
      when "pipe"
        pipe_name = "#{PIPE_NAME_PREFIX}#{srand * 10000}" unless pipe_name
        part = "pipe,name=#{pipe_name};urp;"
        url = "uno:#{part}StarOffice.ServiceManager"
        argument = "-accept=#{part}StarOffice.ComponentContext"
      else
        raise ArgumentError, "Illegal connection type (#{type})"
      end
      return url, argument
    end
    
  end
end

# If loadComponentFromURL method is not found on desktop instance, 
# environmental variables are not correct.
if __FILE__ == $0
  office = "/home/asuka/local/opt/openoffice.org3/program/soffice"
  ctx = Uno::Connector.bootstrap(office)
  smgr = ctx.getServiceManager
  desktop = smgr.createInstanceWithContext(
                   "com.sun.star.frame.Desktop", ctx)
  doc = desktop.loadComponentFromURL("private:factory/swriter", "_blank", 0, [])
  doc.getText.setString("Hello Ruby!")
end
