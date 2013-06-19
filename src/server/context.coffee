SchemaManager = require "./schema_manager"
status_code = (description) ->
  # FIXME.  Probably use http.STATUS_CODES inverted.
  return 500


module.exports = class Context
  constructor: (@service, @request, @response, @match) ->
    @schema_manager = @service.schema_manager

  set_cors_headers: (origin) ->
    if @request.headers["origin"]
      origin ||= @request.headers["origin"]
      @response.setHeader "Access-Control-Allow-Origin", origin

  respond: (status, @response_content, headers) ->
    if status == 202 || status == 204 || !@response_content
      @response_content = ""
    headers ||= {}

    if @match.accept
      @response_schema = @schema_manager.find(media_type: @match.accept)
    else
      @response_schema = null

    @response_content = @marshal(@response_content)

    # Set the content-type and content-length headers explicitly 
    # for the benefit of connect's compress middleware
    @response.setHeader "Content-Length", Buffer.byteLength(@response_content)
    if @match.accept && @response_content.length > 0
      @response.setHeader("Content-Type", @match.accept)
    @response.writeHead(status, headers)
    @response.end(@response_content)

  error: (description) ->
    if description == "timeout"
      @respond(504)
    else
      status = status_code(description)
      @respond(status, description)

  url: (name, args...) ->
    @service.generate_url(name, args...)


  marshal: (content) ->
    if content.constructor == String
      content
    else
      if @service.decorator
        @service.decorator
          service: @service
          context: @
          response_schema: @response_schema
          response_content: content
      JSON.stringify(content)

  decorate: (callback) ->
    @traverse(@response_schema, @response_content, callback)

  traverse: (schema, data, callback) ->
    if callback && schema
      callback(schema, data)
    @_traverse(schema, data, callback)

  _traverse: (schema, data, callback) ->
    if !schema || !data
      return
    if ref = schema.$ref
      if schema = @schema_manager.find(ref)
        @traverse(schema, data, callback)
      else
        console.error "Can't find ref:", ref
        data
    else
      if schema.type == "array"
        if schema.items
          for item, i in data
            @traverse(schema.items, item, callback)
      else if !schema.is_primitive
        # Declared properties
        for key, value of schema.properties
          @traverse(value, data[key], callback)
        # Default for undeclared properties
        if addprop = schema.additionalProperties
          for key, value of data
            unless schema.properties?[key]
              @traverse(addprop, value, callback)
        return data

