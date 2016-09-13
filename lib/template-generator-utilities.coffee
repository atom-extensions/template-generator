CSON = require 'season'
_ = require 'underscore'
Path = require 'path'
_fs = require 'fs-plus'
_rq = require 'request'



module.exports =

  getDirname: ( path ) ->
    if _fs.isFileSync( path )
      Path.dirname(path)
    else
      path

  getRelativePathToProject: ( path ) ->
    Path.relative( atom.project.getPaths()[0], path )

  getTemplatesDataFromFile: ->
    configFilePath = atom.config.get('template-generator.templatesFilePath')

    # Read the config file from and populate the list
    CSON.readFileSync configFilePath

  getExtensionFromFileName: ( fileName ) ->
    Path.extname(fileName)

  writeTemplatesDataToFile: ( data ) ->
    configFilePath = atom.config.get('template-generator.templatesFilePath')
    CSON.writeFileSync configFilePath, data

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

  getFieldsFromTemplate: ( str ) ->
    retArr = []
    regex = /(\[\{\[([a-zA-Z0-9_]+)\]\}\])/g

    # Check for fields in the Template content property
    match = regex.exec( str )
    while ( match != null )
      retArr.push match[2]
      match = regex.exec( str )

    retArr

  parseTemplate: ( template ) ->
    fields = []
    self = @

    iterateOverItem = ( items ) ->
      for key of items
        fields = fields.concat(self.getFieldsFromTemplate key)
        if key == "content"
          fields = fields.concat(self.getFieldsFromTemplate items[key])

        if typeof items[key] == "object"
          iterateOverItem items[key]

    iterateOverItem template

    fields

  tansformTemplateObjectWithFields: ( t, sFA ) ->

    ienumrator = ( templateObject, sFieldsArray ) ->
      _obj = {}

      #  Find and replace all the fields from given string
      strReplace = ( str ) ->
        ret = str
        for field in sFieldsArray
          ret = ret.replace ///\[\{\[#{field[0]}\]\}\]///g, field[1]
        ret

      # Iterate over every property in the Object and replace fields
      _.each templateObject, ( hValue, sKey ) ->
        # Cache the values
        sOld = sNew = sKey
        hOld = hNew = hValue

        # If the current property is Object and recurse through it
        if _.isObject hValue
          hNew = ienumrator hOld, sFieldsArray

        # Replace the fields in the key
        sNew = strReplace sOld

        # Only replace fields in property if the property key is type content
        if sKey == "content"
          hNew = strReplace hOld

        # Return the New Object
        _obj[sNew] = hNew

      _obj

    ienumrator t, sFA
