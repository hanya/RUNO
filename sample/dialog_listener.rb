
require 'uno.rb'

ctx = Runo::Connector.bootstrap

desktop = Runo.get_desktop
p desktop
unless desktop
  puts 'failed to get desktop.'
  exit
end

#ctx = Runo.get_component_context
Runo.uno_require('com.sun.star.awt.XActionListener')

class ButtonListener
  include Runo::Base
  include Runo::Com::Sun::Star::Awt::XActionListener
  
  # XEventListener
  # must be defined for all listeners
  def disposing(ev)
  end
  
  # XActionListener
  # called at button pushed
  def actionPerformed(ev)
    dlg = ev.Source.getContext
    dlg.getControl('edit').setText(Time.now.to_s)
  end
end

# this runtime dialog creation is just a demonstration.
# make a dialog with dialog editor of OpenOffice.org and 
# create instance of the dialog using css.awt.DialogProvider service.
def create_dialog(ctx)
  awt_prefix = 'com.sun.star.awt'
  smgr = ctx.getServiceManager
  dlg = smgr.createInstanceWithContext("#{awt_prefix}.UnoControlDialog", ctx)
  dlg_model = smgr.createInstanceWithContext("#{awt_prefix}.UnoControlDialogModel", ctx)
  #mri = smgr.createInstanceWithContext('mytools.Mri', ctx)
  #Runo.invoke(mri, 'inspect', [dlg])
  dlg.setModel(dlg_model)
  dlg_model.setPropertyValues(
      ['Height', 'PositionX', 'PositionY', 'Width'], 
      [55, 100, 100, 80])
  
  btn_model = dlg_model.createInstance("#{awt_prefix}.UnoControlButtonModel")
  edit_model = dlg_model.createInstance("#{awt_prefix}.UnoControlEditModel")
  btn_model.setPropertyValues(
      ['Height', 'Label', 'PositionX', 'PositionY', 'Width'], 
      [20, '~Push', 5, 30, 70])
  edit_model.setPropertyValues(
      ['Height', 'PositionX', 'PositionY', 'Width'], 
      [20, 5, 5, 70])
  dlg_model.insertByName('btn', btn_model)
  dlg_model.insertByName('edit', edit_model)
  
  # set button listener
  dlg.getControl('btn').addActionListener(ButtonListener.new)
  dlg.setVisible(true)
  dlg.execute
  dlg.dispose # call dispose method to destroy adapter to ensure free
end

create_dialog(ctx)




