# coding: utf-8

require 'runo'

module Runo
  class << self
	  #  Shows input box that is create at runtime.
	  #  -> String|nil
	  def inputbox(message="", title="", default="", ctx=nil)
	    dlg_width, dlg_height = 350, 100
	    btn_width, btn_height = 80, 28
	    field_height = 28
	    if ! ctx
	      ctx = @@component_context
	    end
	    smgr = ctx.getServiceManager
	    desktop = smgr.createInstanceWithContext(
	      "com.sun.star.frame.Desktop", ctx)
	    pos_size = desktop.getActiveFrame.getContainerWindow.getPosSize
	    dlg = smgr.createInstanceWithContext(
	      "com.sun.star.awt.UnoControlDialog", ctx)
	    dlg_model = smgr.createInstanceWithContext(
	      "com.sun.star.awt.UnoControlDialogModel", ctx)
	    dlg.setModel(dlg_model)
	    dlg_model.Title = title
	    dlg.setPosSize((pos_size.Width - dlg_width)/2, 
	      (pos_size.Height - dlg_height)/2, 
	      dlg_width, dlg_height, PS_POSSIZE)
	    
	    label_model = dlg_model.createInstance(
	      "com.sun.star.awt.UnoControlFixedTextModel")
	    dlg_model.insertByName("label", label_model)
	    edit_model = dlg_model.createInstance(
	      "com.sun.star.awt.UnoControlEditModel")
	    dlg_model.insertByName("edit", edit_model)
	    btn_ok_model = dlg_model.createInstance(
	      "com.sun.star.awt.UnoControlButtonModel")
	    dlg_model.insertByName("btn_ok", btn_ok_model)
	    btn_cancel_model = dlg_model.createInstance(
	      "com.sun.star.awt.UnoControlButtonModel")
	    dlg_model.insertByName("btn_cancel", btn_cancel_model)
	    
	    btn_ok_model.setPropertyValues(
	      ["PushButtonType", "DefaultButton", "Label"], 
	      [1, true, "~OK"])
	    btn_cancel_model.setPropertyValues(
	      ["PushButtonType", "Label"], 
	      [2, "~Cancel"])
	    label_model.VerticalAlign = 1
	    dlg.getControl("label").setPosSize(4, 2, 
	        dlg_width - 8, field_height, PS_POSSIZE)
	    dlg.getControl("edit").setPosSize(2, field_height + 6, 
	        dlg_width - 4, field_height, PS_POSSIZE)
	    dlg.getControl("btn_ok").setPosSize(
	        dlg_width - btn_width - 5, dlg_height - field_height - 5, 
	        btn_width, btn_height, PS_POSSIZE)
	    dlg.getControl("btn_cancel").setPosSize(
	        dlg_width - btn_width * 2 - 15, dlg_height - field_height - 5, 
	        btn_width, btn_height, PS_POSSIZE)
	    
	    label_model.Label = message
	    edit_model.Text = default
	    
	    ret = nil
	    dlg.setVisible(true)
	    if dlg.execute == 1
	      ret = edit_model.Text
	    end
	    dlg.dispose
	    ret
	  end
  end
end

