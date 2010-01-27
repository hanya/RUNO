# coding: utf-8

require 'uno'

ctx = Runo.component_context
desktop = Runo.get_desktop

doc1 = desktop.loadComponentFromURL('private:factory/swriter', '_blank', 0, [])
text = doc1.getText
cursor = text.createTextCursor
cursor.setString('RUNO')
cursor.ParaStyleName = 'Heading 1'

para = text.appendParagraph([])
para.ParaStyleName = 'Text body'
para.setString('RUNO is a bridge between Ruby and UNO.')
para = text.finishParagraph([])



