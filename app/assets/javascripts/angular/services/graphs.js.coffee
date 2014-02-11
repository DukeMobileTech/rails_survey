App.factory 'DailyGraph', ['$resource', ($resource) ->
  $resource '/api/v1/projects/:project_id/graphs/daily', { project_id: '@project_id'}
]

App.factory 'HourGraph', ['$resource', ($resource) ->
  $resource '/api/v1/projects/:project_id/graphs/hourly', { project_id: '@project_id'}
]
