# coding: utf-8

require 'uno'

# You can use extension to know well about UNO object.
# http://extensions.services.openoffice.org/project/MRI
# 
# inspect method is one of general Ruby's Object instance method. So, 
# you can not call it directory, use Runo.#invoke method.

ctx = Runo.component_context
smgr = ctx.getServiceManager

mri = smgr.createInstanceWithContext("mytools.Mri", ctx)
Runo.invoke(mri, 'inspect', [ctx])


