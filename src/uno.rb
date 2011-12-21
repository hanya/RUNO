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
  @@ctx = get_component_context # initialize runo internal

  require_uno 'com.sun.star.lang.XTypeProvider'

  # Uno.msgbox(message="", title="", buttons=1, type="messbox", peer=nil) -> Integer
  # Shows message dialog on top frame window or specific window.
  # @message [String] message to show
  # @title [String] title for the message box
  # @param [String] type can be messbox, infobox, warningbox, errorbox or querybox.
  # @param [Fixnum] buttons is combination of constants css.awt.MessageBoxButtons.
  # @param [object] peer window peer to show the dialog.
  # @return [Fixnum] depends on buttons, see buttons
  def Uno.msgbox(message="", title="", buttons=1, type="messbox", peer=nil)
    unless peer
      ctx = Uno.get_component_context
      desktop = ctx.getServiceManager.createInstanceWithContext(
                   "com.sun.star.frame.Desktop", ctx)
      doc = desktop.getCurrentComponent
      peer = doc.getCurrentController.getFrame.getContainerWindow if doc
    end
    if peer
      rectangle = require_uno("com.sun.star.awt.Rectangle")
      msgbox = peer.getToolkit.createMessageBox(
          peer, rectangle.new, type, buttons, title, message)
      n = msgbox.execute
      msgbox.dispose
      return n
    end
  end

  UNO_TYPES = {}
  # Keeps type information about a class which implements 
  # css.lang.XTypeProvider interface.
  class << UNO_TYPES
  
    def types(klass)
      return find_type(klass)[0]
    end
    
    def id(klass)
      return find_type(klass)[1]
    end
    
    private
    
    def find_type(klass)
      value = self[klass]
      value = self[klass] = [get_uno_types(klass), Uno.uuid] unless value
      return value
    end
    
    def get_uno_types(klass)
      types = []
      klass.ancestors.each do |m|
        if m.const_defined?(:UNO_TYPE_NAME)
          c = m.const_get(:UNO_TYPE_NAME)
          types << Uno.get_type(c)
        end
      end
      types.uniq!
      return types
    end
  end

  # This is base module which is used to define UNO component, 
  # just include this module like the following:
  #   class MyListener
  #      include Uno::UnoBase
  #      include ...other interfaces
  #   end
  # The adapter needs to know its types (interfaces) are implemented by the 
  # component, therefore methods of this module provide it.
  # If it should be class itself, implement XTypeProvider interface to 
  # the class.
  module UnoBase
    include Uno::Com::Sun::Star::Lang::XTypeProvider
    def getTypes
      return Uno::UNO_TYPES.types self.class
    end
    
    def getImplementationId
      return Uno::UNO_TYPES.id self.class
    end
  end
end
