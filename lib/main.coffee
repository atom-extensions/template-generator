{CompositeDisposable} = require 'event-kit'
CSON = require 'season'
path = require 'path'

TemplateSelectorDialog = null

module.exports = TemplateGenerator =
  config:
    templatesFilePath:
      type:'string'
      default:path.join("#{atom.packages.resolvePackagePath('template-generator')}","templates.cson")
      title:'Templates File'
      description:'Templates File to store all the Templates data'


  activate: ( state ) ->
    @disposables = new CompositeDisposable

    @disposables.add atom.commands.add('atom-workspace', {
      'template-generator:toggle-settings-view': => @createSettingsView().toggle()
      'template-generator:toggle-template-generator': => @toggleTemplateSelectorDialog()
    })

  createSettingsView: ->
    unless @maSettingsView?
      SettingsView = require './template-generator-bottom-panel'
      @maSettingsView = new SettingsView()

    @maSettingsView

  createTemplateSelectorDialog: (  ) ->
    unless @maTemplateSelectorDialog?
      TemplateSelectorDialog ?= require './template-generator-template-selector-dialog'
      @maTemplateSelectorDialog = new TemplateSelectorDialog(  )

    @maTemplateSelectorDialog

  toggleTemplateSelectorDialog: ->

    configFilePath = atom.config.get('template-generator.templatesFilePath')
    dialog = @createTemplateSelectorDialog( )
    CSON.readFile configFilePath, ( err, json ) =>
        if json?
          dialog.setItems( json )
          dialog.toggle()

  deactivate: ->
    @disposables.dispose()

  serialize: ->
