URL = require("url")
Context = require("./context")

class SimpleDispatcher

  constructor: (@service, @handlers) ->
    @supply_missing_handlers()


  supply_missing_handlers: () ->
    handler = @handlers.service.default

    for resource, definition of @service.resources
      for action, spec of definition.actions
        @handlers[resource] ||= {}
        @handlers[resource][action] ||= handler

  request_listener: () ->
    (request, response) =>
      @dispatch(request, response)

  dispatch: (request, response) ->
    @service.augment_request(request)
    match = @service.classify(request)
    if match.error
      @error_handler(match.error, response)
    else
      if match.content_type && @service.options.validate
        report = @validate(match.content_type, request)
        if report.valid != true
          @error_handler(
            # TODO: more informative description
            {status: 400, message: "Bad Request"},
            response
          )
          return

      handler = @find_handler(match)
      context = new Context(@service, request, response, match)
      handler(context)

  validate: (mediaType, request) ->
    @service.schema_manager.validate {mediaType}, request.body


  find_handler: (match) ->
    if resource = @handlers[match.resource_type]
      if action = resource[match.action_name]
        action
      else
        throw "Resource '#{match.resource_type}' has no such action: #{match.action_name}"
    else
      throw "No such resource: #{match.resource_type}"

  error_handler: (error, response) ->
    response.setHeader "Access-Control-Allow-Origin", "*"

    response.writeHead error.status,
      "Content-Type": "application/json"
    response.end JSON.stringify(error)



module.exports = SimpleDispatcher
