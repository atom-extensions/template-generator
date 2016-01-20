{SelectListView, $$, $ } = require 'atom-space-pen-views'
CSON = require 'season'
_ = require 'underscore'

FieldsListDialog = null
fuzzyFilter = null

module.exports =
class TemplateSelectorListView extends SelectListView
  selectedPath = null

  initialize: ({selectedPath}={}) ->
    super
    @setError(" ")
    @selectedPath = selectedPath

  viewForItem: ( item ) ->
    $$ ->
      @li =>
        @span item

  filter: ( query ) ->
    _.pick @items, ( val, key, object ) ->
      key.toLowerCase().includes query.toLowerCase()


  populateList: ->
    super
    @list.empty()

    filterQuery = @getFilterQuery()
    if filterQuery.length
      filteredItems = @filter(filterQuery)
    else
      filteredItems = @items

    for key of filteredItems
      item = filteredItems[key]
      obj = {}
      obj[key] = item
      itemView = $(@viewForItem(key))
      itemView.data('select-list-item', obj)
      @list.append itemView

    @selectItemView(@list.find('li:first'))

  confirmed: ( template ) ->
    pkgTreeView = atom.packages.getActivePackage('tree-view')
    selectedEntry = pkgTreeView.mainModule.treeView.selectedEntry() ? pkgTreeView.mainModule.treeView.roots[0]
    selectedPath = selectedEntry?.getPath() ? ''

    FieldsListDialog ?= require './template-generator-fields-list'
    maFieldsListDialog = new FieldsListDialog( { template, selectedPath} )
    maFieldsListDialog.attach()
    @close()

  cancelled: ->
    @close()

  close: ->
    panelToDestroy = @panel
    @panel = null
    panelToDestroy?.destroy()

  attach: ->
    @panel = atom.workspace.addModalPanel(item: this)
    @focusFilterEditor()
