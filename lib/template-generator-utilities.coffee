CSON = require 'season'
_ = require 'underscore'
Path = require 'path'
_fs = require 'fs-plus'
_rq = require 'request'
_changecase = require 'change-case'


module.exports =

  # Public Internal Deprecated: description.
  #
  # argument - argument description
  #
  # Examples
  #
  #  example
  #
  # returns/raises section
  getDirname: ( path ) ->
    if _fs.isFileSync( path )
      Path.dirname(path)
    else
      path

  # Public Internal Deprecated: description.
  #
  # argument - argument description
  #
  # Examples
  #
  #  example
  #
  # returns/raises section
  getRelativePathToProject: ( path ) ->
    Path.relative( atom.project.getPaths()[0], path )

  # Public Internal Deprecated: description.
  #
  # argument - argument description
  #
  # Examples
  #
  #  example
  #
  # returns/raises section
  getTemplatesDataFromFile: ->
    configFilePath = atom.config.get('template-generator.templatesFilePath')

    # Read the config file from and populate the list
    CSON.readFileSync configFilePath

  # Public Internal Deprecated: description.
  #
  # argument - argument description
  #
  # Examples
  #
  #  example
  #
  # returns/raises section
  getExtensionFromFileName: ( fileName ) ->
    Path.extname(fileName)

  # Public Internal Deprecated: description.
  #
  # argument - argument description
  #
  # Examples
  #
  #  example
  #
  # returns/raises section
  writeTemplatesDataToFile: ( data ) ->
    configFilePath = atom.config.get('template-generator.templatesFilePath')
    CSON.writeFileSync configFilePath, data

  # Public Internal Deprecated: description.
  #
  # argument - argument description
  #
  # Examples
  #
  #  example
  #
  # returns/raises section
  generateFilesUsingTemplateObject: ( templateObject, parentFolder ) ->
    bSuccess = true
    iterateOverObject = ( obj, sParentFolderPath ) ->
      for key of obj
        item = obj[key]
        console.log(key);
        sFilePath = "#{sParentFolderPath}//#{key}"

        if item.type == "FOLDER"
          sFilePath = "#{sParentFolderPath}//#{key}"

          if not _fs.isDirectorySync
            _fs.makeTreeSync sFilePath

          iterateOverObject item, sFilePath

        else if item.type == "URL"
          if _fs.existsSync sFilePath
            atom.notifications.addWarning "Error Occured while trying to create file #{sFilePath} File already axists at the Location"
          else
            downloadFile = (sFP, sURL) ->
              _rq.get {uri: sURL, encoding: null}, (error, response, body) ->
                if !error && response.statusCode == 200
                  _fs.writeFileSync sFP, body
                else
                  atom.notifications.addError "Fetching file at #{sURL} threw an error"
              console.log(sFP)
            downloadFile sFilePath, item.content

        else if item.type == "FILE"
          if _fs.existsSync sFilePath
            atom.notifications.addWarning "Error Occured while trying to create file #{sFilePath} File already axists at the Location"
          else
            _fs.writeFileSync sFilePath, item.content

        else if item.type == "GROUP"
          iterateOverObject item, sParentFolderPath

    iterateOverObject templateObject, parentFolder

    bSuccess

  # Public Internal Deprecated: description.
  #
  # argument - argument description
  #
  # Examples
  #
  #  example
  #
  # returns/raises section
  getFieldsFromTemplate: ( str ) ->
    retArr = []
    regex = /\[{\[([\w\s]*)[\s|]*([\w\s]*)\]}\]/g

    # Check for fields in the Template content property
    match = regex.exec( str )
    while ( match != null )
      field = {}
      field.name = match[1]
      field.casetransform = match[2]
      field.fullmatch = match[0]
      retArr.push field

      match = regex.exec( str )

    retArr

  # Public Internal Deprecated: description.
  #
  # argument - argument description
  #
  # Examples
  #
  #  example
  #
  # returns/raises section
  parseTemplate: ( template ) ->
    fields = []
    self = @

    iterateOverItem = ( items ) ->

      for key of items
        # If the key is "type" and "content" that means its a variable so parse it
        fields = fields.concat(self.getFieldsFromTemplate key) if (key isnt "type") and (key isnt "content")
        if key == "content"
          fields = fields.concat(self.getFieldsFromTemplate items[key])

        if typeof items[key] == "object"
          iterateOverItem items[key]

    iterateOverItem template

    fields

  transformString: ( str, targetcase ) ->
    _changecase[targetcase]?(str) or str


  # Public Internal Deprecated: description.
  #
  # argument - argument description
  #
  # Examples
  #
  #  example
  #
  # returns/raises section
  tansformTemplateObjectWithFields: ( templateObject, sFieldsArray ) ->
    scope = this

    transformedTemplate = {}

    replaceFieldsInString = ( str ) ->
      fields = scope.getFieldsFromTemplate(str)

      _.each fields, ( field ) ->
        strToReplace = sFieldsArray[field.name]
        if strToReplace?.length
          str = str.replace field.fullmatch, scope.transformString(strToReplace, field.casetransform)

      str

    recursiveReplace = ( _object, context ) ->

      _.each _object, ( value, key ) ->
        transformedKey = ""
        transformedValue = {}

        if key.indexOf("[{[") > -1
          transformedKey = replaceFieldsInString(key)
        else
          transformedKey = key

        if _.isString(value) and value.indexOf("[{[") > -1
          transformedValue = replaceFieldsInString(value)
        else if (_.isObject value)
          recursiveReplace value, transformedValue
        else
          transformedValue = value

        @[transformedKey] = transformedValue

      , context

    recursiveReplace templateObject, transformedTemplate

    transformedTemplate
