# coding: utf-8

require 'runo'

# Shows list of filter names that are installed your environment.
# 
# meaning of the list:
#   UIName: name shown in the file open dialog
#   Name: filter name that is used in API
#   Type: file type
#   Import: importable?
#   Export: exportable?
#   FilterService: service name of filtering service
#   UIComponent: dialog service
#   UserData: configuration data
#
# @param [Runo::RunoProxy] component context of remote server
#
def write_filter_names(ctx)
  def flag_to_s(flags)
    i = (flags & 1) == 1 ? 'X' : '-'
    e = (flags & 2) == 2 ? 'X' : '-'
    [i, e]
  end
  docTypes = {'com.sun.star.text.TextDocument'=> [], 
              'com.sun.star.sheet.SpreadsheetDocument'=> [], 
              'com.sun.star.drawing.DrawingDocument'=> [], 
              'com.sun.star.text.WebDocument'=> [], 
              'com.sun.star.presentation.PresentationDocument'=> [], 
              'com.sun.star.formula.FormulaProperties'=> [], 
              'com.sun.star.text.GlobalDocument'=> [], 
              'com.sun.star.sdb.OfficeDatabaseDocument'=> [], 
              'com.sun.star.chart2.ChartDocument'=> []}
  ids = {'UIName'=> 0, 'Name'=> 1, 'Type'=> 2, 
         'FilterService'=> 5, 'UIComponent'=> 6}
  # filter factory provides all existing filters
  ff = ctx.getServiceManager.createInstanceWithContext(
    'com.sun.star.document.FilterFactory', ctx)
  names = ff.getElementNames
  
  for name in names
    doc_type = ''
    d = Array.new(8, '')
    ps = ff.getByName(name)
    
    for pv in ps
      n = pv.Name
      if n == 'DocumentService'
        doc_type = pv.Value
      end
      pos = ids[n]
      if pos === nil
        if n == 'Flags'
          d[3], d[4] = flag_to_s(pv.Value)
        elsif n == 'UserData'
          d[7] = pv.Value.join
        end
      else
        d[pos] = pv.Value
      end
    end
    if ! doc_type.empty?
      docTypes[doc_type] << d
    end
  end
  
  # create new spreadsheet document from desktop
  desktop = ctx.getServiceManager\
                .createInstanceWithContext('com.sun.star.frame.Desktop', ctx)
  doc = desktop.loadComponentFromURL('private:factory/scalc', '_blank', 0, [])
  
  # lock controllers and disabel the modified status changing make little bit fast
  doc.disableSetModified
  doc.lockControllers
  
  sheets = doc.getSheets
  n = sheets.getCount
  
  h = ['UIName', 'Name', 'Type', 'Import', 'Export', 
    'FilterService', 'UIComponent', 'UserData']
  
  for k, v in docTypes
    v.unshift(h)
    sheet_name = k[k.rindex('.') + 1..-1].sub('Document', '').sub('Properties', '')
    # create and insert new sheet
    sheet = doc.createInstance('com.sun.star.sheet.Spreadsheet')
    sheets.insertByName(sheet_name, sheet)
    r = sheet.getCellRangeByPosition(0, 0, 7, v.size - 1)
    
    # set data from array, is faster than iteration of all cells
    r.setDataArray(v)
    r.getColumns.OptimalWidth = true
  end
  
  # remove disuse sheets. index
  for i in 0..n-1
    sheets.removeByName(sheets.getByIndex(0).getName)
  end
  
  # remove lockings
  doc.enableSetModified
  doc.unlockControllers
  print "done.\n"
end


def get_ctx(local_ctx)
  if local_ctx
    uno_url = 'uno:socket,host=localhost,port=2083;urp;StarOffice.ComponentContext'
    local_smgr = local_ctx.getServiceManager
    resolver = local_smgr\
        .createInstanceWithContext('com.sun.star.bridge.UnoUrlResolver', local_ctx)
    ctx = resolver.resolve(uno_url)
  end
end


ctx = get_ctx(Runo.get_component_context)
if ctx
  write_filter_names(ctx)
end


