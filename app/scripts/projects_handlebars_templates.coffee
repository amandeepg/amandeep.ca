jobPromise = $.get 'scripts/job_data.yml', (data) ->
  data = jsyaml.load(data)
  template = $('#job-template').html()
  compiledTemplate = Handlebars.compile(template)
  renderedHtml = compiledTemplate(data)
  
  $('#items-insert-point').replaceWith renderedHtml

togglePromise = $.get 'scripts/toggle_data.yml', (data) ->
  data = jsyaml.load(data)
  template = $('#toggle-template').html()
  compiledTemplate = Handlebars.compile(template)
  renderedHtml = compiledTemplate(data)
  
  $('#toggles-insert-point').replaceWith renderedHtml

$.when(jobPromise, togglePromise).done ->
  $(document).trigger('job_data_loaded')
