class @RailsRouter
  setupXHR: ->
    if token = $("meta[name='csrf-token']").attr("content")
      @$xhr.defaults.headers.post['X-CSRF-Token'] = token
      @$xhr.defaults.headers.put['X-CSRF-Token'] = token
      @$xhr.defaults.headers['delete']['X-CSRF-Token'] = token

@resourceService = (serviceName, path, methods...)->
  if methods.length is 0
    methods.push 'index', 'create', 'update', 'destroy', 'show'
  commandHash = {}
  for type in methods
    commandHash[type] = switch type
      when 'index'
        { method:'GET', isArray:true }
      when 'show'
        { method:'GET', isArray:false }
      when 'create'
        { method: 'POST' }
      when 'update'
        { method: 'PUT' }
      when 'destroy'
        { method: 'DELETE' }
	
  angular.service serviceName, ($resource)->
    $resource path, {}, commandHash

class @AngularModel
  initialize:->
    if @hasMany
      for name, clazz of @hasMany
        @[name] or= []
        for obj in @[name]
          objProto = new clazz()
          for key, value of objProto
            obj[key] = value
          obj.constructor = objProto.constructor
          obj.initialize?()

module = angular.module "eventuallyWork", ['$defer']
module.factory 'serviceId', ->
  eventuallyWork = (func, timeout)->
    try
      func()
    catch e
      $defer (-> eventuallyWork func, 2*timeout), timeout
  (func)->
    eventuallyWork(func, 10)

@adaptForAngular = (clazz, alias, injections...)=>
  injections.push "$scope"
  window[alias] = (args..., scope)->
    controller = new clazz()
    for key, value of controller
      scope[key] = value

    scope.initializeInjections? args...
    
    scope.$scope = scope
    
    for observer in (clazz.$observers || [])
      new observer(scope)

  window[alias].$inject = injections

class @JqueryObserver
  constructor:(@$scope)->
    $ =>
      @onReady?()
      @$scope.$digest()

@autowrap = (clazz, callback)->
  (result)->
    resultProto = new clazz()
    for key, value of resultProto
      result[key] = value
    result.constructor = resultProto.constructor
    result.initialize?()
    if callback
      callback(result)
