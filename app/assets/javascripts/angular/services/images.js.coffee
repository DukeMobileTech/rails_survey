App.factory 'Images', ['$resource', ($resource) ->
  $resource '/api/v1/frontend/projects/:project_id/instruments/:instrument_id/questions/:question_id/images/', 
  { project_id: '@project_id', instrument_id: '@instrument_id', question_id: '@question_id', id: '@id' }
]