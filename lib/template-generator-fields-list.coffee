{View, SelectListView, $$, $, TextEditorView } = require 'atom-space-pen-views'
TemplateGeneratorUtilities = require './template-generator-utilities'
_ = require 'underscore'
CSON = require 'season'

module.exports =
class FieldsListView extends View

  @content: ->
    @div class:'inset-panel', =>
      @div class:'panel-heading', =>
        @span 'List of Fields you would like to replace in the files and file names'
      @div class:'panel-body', =>
        @div class:'block fields-list select-list', =>
          @ol class:'fields-group list-group', outlet:'fieldsList'
        @div class:'block btn-toolbar', =>
          @div class:'btn-group', =>
            @button 'Create', class:'btn btn-success', click:'createTheTemplates'
            @button 'Cancel', class:'btn btn-error', click:'close'

  initialize: ( {template, selectedPath}={} ) ->
    @template = template
    @selectedPath = selectedPath

    atom.commands.add @element, 'core:cancel': ( e ) =>
      @close()


  # createTheTemplates:
  #
  # * `` The [description] as {[type]}.
  #
  # Returns the [Description] as `undefined`.
  createTheTemplates: ( e ) ->
    self = $(e.target)
    fields = @fieldsList.children('li')
    sFieldsArray = []

    # Loop through the UI and get the fields and thier names
    _.each fields, ( fElement ) ->
      fieldName = $(fElement).data( 'field-item-data' )
      fieldValue = fElement.children[0].getModel().getText()
      sFieldsArray.push [fieldName, fieldValue]

    transformedTemplate = TemplateGeneratorUtilities.tansformTemplateObjectWithFields @template, sFieldsArray
    TemplateGeneratorUtilities.generateFilesUsingTemplateObject transformedTemplate, @selectedPath

    @close()


  # close: Close the view
  #
  # Returns the [Description] as `undefined`.
  close: ->
    panelToDestroy = @panel
    @panel = null
    panelToDestroy?.destroy()

  viewForItem : ( item ) ->
    $$ ->
      @li =>
        @tag 'atom-text-editor', mini:true, 'placeholder-text':item

  # populateFields: Populate all the fields in the modal panel
  #
  # * `fileds ` The [description] as {[type]}.
  #
  # Returns the [Description] as `undefined`.
  populateFields: ( fields ) ->
    @fieldsList.empty()
    for field in fields
      itemView = $(@viewForItem(field))
      itemView.data('field-item-data', field)
      @fieldsList.append itemView



  # attach: Attach the view to atom and display it
  #
  # Returns the [Description] as `undefined`.
  attach: ->
    @panel = atom.workspace.addModalPanel(item: this)
    fieldsList = TemplateGeneratorUtilities.parseTemplate( @template )
    @populateFields(_.uniq fieldsList)
