import { all, resolve } from 'rsvp'
import { get } from './utils'

class ObjectValidator
  _validations : null

  constructor: ->
    @_validations = []

  addValidation: (attr, fn, message) ->
    list = @_validations[attr] ||= []
    list.push [fn, message]
    return null

  validate: (object, attributes..., callback) ->
    if typeof callback is 'string'
      attributes.push callback
      callback = null

    if attributes.length is 0
      attributes = (attr for own attr of @_validations)

    validationPromises = []
    for attr in attributes
      validationPromises.push @_validateAttribute(object, attr)...

    promise = all(validationPromises).then (results) =>
      results = @_collectResults results
      callback? results
      return results

    return promise unless callback?

  _validateAttribute: (object, attr) ->
    value  = get object, attr

    for [fn, message] in @_validations[attr]
      do (message) ->
        resolve(fn(value, attr, object))
          .then((isValid) -> [ attr, message ] if isValid isnt yes)

  _collectResults: (results) ->
    result =
      valid  : yes
      errors : {}

    for attrMessage in results when attrMessage?
      [ attr, message ] = attrMessage
      messages = result.errors[attr] ||= []
      messages.push message
      result.valid = no

    return result

export default ObjectValidator
