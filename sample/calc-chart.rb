# coding: utf-8

require 'uno.rb'

desktop = Runo.get_desktop
if desktop
  # create new Spreadsheet document
  doc = desktop.loadComponentFromURL('private:factory/scalc', '_blank', 0, [])
  Rect, Prop, CellRangeAddress = Runo.uno_require('com.sun.star.awt.Rectangle', 
                                'com.sun.star.beans.PropertyValue', 
                                'com.sun.star.table.CellRangeAddress')
  def make_prop(name, value)
    prop = Prop.new
    prop.Name = name
    prop.Value = value
    prop
  end
  
  # get sheet and cell range and set data
  sheet = doc.getSheets.getByIndex(0)
  cell_range = sheet.getCellRangeByPosition(0, 0, 1, 2)
  cell_range.setDataArray([['X', 'Y'], [0, 5], [2, 10]])
  
  # chart container
  charts = sheet.getCharts
  
  rect = Rect.new(1300, 1300, 7000, 5000)
  chart_name = 'chart2'
  if charts.hasByName(chart_name)
    charts.removeByName(chart_name)
  end
  
  charts.addNewByName(chart_name, rect, [CellRangeAddress.new], false, false)
  chart = charts.getByName(chart_name).getEmbeddedObject
  
  diagram = chart.getFirstDiagram
  type_manager = chart.getChartTypeManager
  template = type_manager.createInstance(
      'com.sun.star.chart2.template.ScatterLineSymbol')
  template.changeDiagram(diagram)
  data_prov = chart.getDataProvider
  
  coords = diagram.getCoordinateSystems
  coord = coords[0]
  
  chart_types = coord.getChartTypes
  chart_type = chart_types[0]
  
  
  props = Array.new
  props << make_prop('CellRangeRepresentation', cell_range.AbsoluteName)
  
  props << make_prop('DataRowSource', Runo.uno_require('com.sun.star.chart.ChartDataRowSource.COLUMNS'))
  props << make_prop('FirstCellAsLabel', false)
  props << make_prop('HasCategories', true)
  
  data_source = data_prov.createDataSource(props)
  
  args = Array.new
  args << make_prop('HasCategories', true)
  
  template.changeDiagramData(diagram, data_source, args)
end



