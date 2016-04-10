getClasses = (elem) ->
  $(elem).attr('class').split(' ')

getTagClass = (elem) ->
  for clss in getClasses(elem)
    return clss.replace('tag-','') if (clss.startsWith('tag-'))

getTagClasses = (elem) ->
  tagClasses = []
  for clss in getClasses(elem)
    tagClasses.push(clss.replace('tag-','')) if (clss.startsWith('tag-'))
  return tagClasses

getEnabledToggles = () ->
  enabledToggles = []
  for toggleBtnElem in $('.toggles .btn')
    toggleBtnElem = $(toggleBtnElem)
    enabledToggles.push(getTagClass(toggleBtnElem)) if toggleBtnElem.hasClass('on')
  return enabledToggles

showCards = () ->
  # go through all cards
  for panel in $('.content-container .panel')
    panel = $(panel)
    enabledToggles = getEnabledToggles()
    tagClasses = getTagClasses(panel)

    # if all the toggles match, add the class, else remove it
    if _.intersection(enabledToggles, tagClasses).length == enabledToggles.length
      panel.addClass('on')
    else
      panel.removeClass('on')

$(document).on 'job_data_loaded', ->
  showCards()
  $.material.init()

  # when click on a button to toggle by tag
  $('.toggles .btn').click (e) ->
    if e.clientX > 0
      $(this).toggleClass('on')
      showCards()

  $('body').click (e) ->
    if !e.target.closest('.panel')
      $('.panel.selected .long-description').velocity('slideUp', duration: 400)
      $('.panel').removeClass('selected')

  $('.panel').click ->
    $(this).addClass('keep-open')
    $('.panel.selected:not(.keep-open) .long-description').velocity('slideUp', duration: 400)
    $(this).removeClass('keep-open')
    $(this).find('.long-description').velocity('slideDown', duration: 400) unless $(this).hasClass('selected')

    $('.panel').removeClass('selected')
    $(this).addClass('selected')
