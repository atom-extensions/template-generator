{View, $, $$} = require 'atom-space-pen-views'
TemplateGeneratorSelectListView = require './template-generator-select-view'
TemplateGeneratorUtilities = require './template-generator-utilities'

module.exports =
class TemplateGeneratorBottomPanel extends View

  @content: ->
    @div class:'tg-settings-view-wrapper', =>
      @div class:'tg-panel-header', =>
        @span class:'icon icon-package text-error'
        @span 'Template Generator Settings View',class:'text-highlight'
        @div class:'inline-block pull-right', =>
          @button 'Save', class:'inline-block btn btn-success icon icon-file-code', click:'saveSettings'
          @button 'Close', class: 'inline-block btn btn-warning icon icon-remove-close', click:'hide'
      @div class:'tg-panel-body', =>
        @div class:'tg-left-pane', =>
          @subview 'tgSelectListView', new TemplateGeneratorSelectListView()
        @div class:'tg-right-pane', outlet:'tgRightPane', =>
          @span '', class:"padded"
          @tag 'atom-text-editor', outlet:'templateContentEditor'

  initialize: ->
    @tgSelectListView.on 'selection-changed', ( e, view ) =>
      @onSelectViewSelectionChanged( $(view) )

    ceditor = @templateContentEditor[0].getModel()
    ceditor.onDidStopChanging (  ) =>
      validContentBool = true

      if @currentSelectedItem?
          @currentSelectedItem.data('item-list-data').content = ceditor.getText()

  # saveSettins: Save the Current state of the panel
  #
  # Returns the [Description] as `undefined`.
  saveSettings: ->
    serializedData = @tgSelectListView.serializeList()
    TemplateGeneratorUtilities.writeTemplatesDataToFile( serializedData )

  # getGrammarFromExtension: Get the grammmar for the current file extension
  #
  # * `ext ` The [description] as {[type]}.
  #
  # Returns the [Description] as `undefined`.
  getGrammarFromExtension: ( ext ) ->
    grammars = atom.grammars.getGrammars()
    g = undefined
    for grammar in grammars
      if ext in grammar.fileTypes
        return g = grammar
    g

  # onSelectViewSelectionChanged: Handler for the SelectListView selection changed
  #
  # * `view ` The [description] as {[type]}.
  #
  # Returns the [Description] as `undefined`.
  onSelectViewSelectionChanged: ( view ) ->
    @tgRightPane.find("span").replaceWith("<span></span>")
    # reset the content string variable and text
    @templateContentEditor.data('content-string', undefined)
    @templateContentEditor[0].getModel().setText("")


    if view? and view.length > 0
      @currentSelectedItem = view
      fileName = view.find('.editable-label > span.item-title').html()
      type = view.data('type')
      fContent = view.data('item-list-data').content or ""
      if type =="FILE" || type == "URL"
        grammar = @getGrammarFromExtension(TemplateGeneratorUtilities.getExtensionFromFileName(fileName).replace('.',""))

        if type == "URL"
          @tgRightPane.find("span").replaceWith("<span class=\"padded\">Enter URL below</span>")

        if grammar != undefined
          @templateContentEditor[0].getModel().setGrammar(grammar)

        @templateContentEditor[0].getModel().setText(fContent)
    else
      @currentSelectedItem = undefined

  # hide: Hide the bottom panel
  #
  # Returns the [Description] as `undefined`.
  hide: ->
    @panel.hide()

  isVisible: ( ) ->
    @panel.isVisible()

  # show: Show the Bottom Panel
  #
  # Returns the [Description] as `undefined`.
  show: ->
    @panel ?= atom.workspace.addBottomPanel(item:this)
    data = TemplateGeneratorUtilities.getTemplatesDataFromFile()
    @tgSelectListView.populateItems(data)
    @panel.show()

  # toggle: Toggle the bottom Panel
  #
  # Returns the [Description] as `undefined`.
  toggle: ->
    if @panel?.isVisible()
      @hide()
    else
      @show()
