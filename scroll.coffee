# a helper function
interpolate = (a, b, degree) ->
  Math.floor a + (b - a) * degree

$(document).ready ->
  dims =

    # update basic dimensions, then resize the view
    update: ->

      # add some 'padding' to prevent overscrolling effects in chrome/safari
      @minScroll = view.$window.height()
      @maxScroll = $(document).height() - 2 * @minScroll
      @halfWidth = 0.2 * $('.slide_range').height()
      @width = 2 * @halfWidth
      @triangleHeight = @halfWidth * Math.sqrt 3
      @triangleTop = @halfWidth - @triangleHeight / 2
      @triangleBottom = @triangleTop + @triangleHeight
      view.resize()
      this
  position = 

    # get page scroll position, then transform the view if there is some change
    update: (force) ->
      scroll = view.$window.scrollTop()

      #adjust scroll position if out of ranges
      if scroll < dims.minScroll
        scroll = dims.minScroll
      else if scroll > dims.maxScroll
        scroll = dims.maxScroll

      # relative scroll position (0 to 1)
      pos = (scroll - dims.minScroll) / (dims.maxScroll - dims.minScroll)
      if force or @current isnt pos
        @current = pos
        view.transform @current
      this

  # storage of rgb values for top an bottom positions
  colors =
    top: [0, 0, 0]
    bottom: [0, 0, 0]

    # pick a random color
    reset: (key) ->
      for i in [0, 1, 2]
        this[key][i] = Math.floor Math.random() * 256
      this
  view = 
    $window: $ window
    $slider: $ '.slider'
    ctx: document.getElementById('figure').getContext '2d'
    resize: ->
      $('#figure').css
        left: -dims.halfWidth
        top: -dims.halfWidth
      .attr
        width: dims.width
        height: dims.width

      # force update position to redraw with new dimensions
      position.update true
      this
    transform: (state) ->
      # if position is top or bottom change the color on the other side
      if state is 0
        colors.reset 'bottom'
      else if state is 1
        colors.reset 'top'
      @$slider.css 'top', Math.floor(state * 100) + '%'
      color = for i in [0, 1, 2]
        interpolate colors.top[i], colors.bottom[i], state
      @ctx.fillStyle = "rgb(#{color.join ','})"
      @ctx.clearRect 0, 0, dims.width, dims.width
      @ctx.beginPath()
      if state <= 0.5

        # draw a deltoid mutating from rhombus to triangle
        # rescale state to be from 0 to 1 again
        state *= 2
        xLeft = 0
        xCenter = dims.halfWidth
        xRight = dims.width
        yTop = interpolate 0, dims.triangleTop, state
        yCenter = interpolate dims.halfWidth, dims.triangleBottom, state
        yBottom = interpolate dims.width, dims.triangleBottom, state
        @ctx.moveTo xCenter, yTop
        @ctx.lineTo xRight, yCenter
        @ctx.lineTo xCenter, yBottom
        @ctx.lineTo xLeft, yCenter
        @ctx.lineTo xCenter, yTop
      else

        # draw a rounded triangle by filling space between 3 arcs
        state = 2 * state - 1
        xLeft = interpolate 0, dims.halfWidth, state
        xCenter = dims.halfWidth
        xRight = interpolate dims.width, dims.halfWidth, state
        yTop = interpolate dims.triangleTop, dims.halfWidth, state
        yBottom = interpolate dims.triangleBottom, dims.halfWidth, state
        r = interpolate 0, dims.halfWidth, state
        @ctx.arc(xCenter, yTop, r, -5 * Math.PI / 6, -Math.PI / 6)
        @ctx.arc(xRight, yBottom, r, -Math.PI / 6, Math.PI / 2)
        @ctx.arc(xLeft, yBottom, r, Math.PI / 2, -5 * Math.PI / 6)
      @ctx.fill()
      this

  # initialization
  colors.reset 'top'
  colors.reset 'bottom'
  dims.update()
  view.$window.scroll ->
    position.update()
  view.$window.resize ->
    dims.update()

  
  # a trick fixing position remembering issues in ios
  window.scrollBy(0, 0)

  # handling touch devices
  currentY = 0
  document.addEventListener 'touchstart', (e) ->
    currentY = e.touches[0].clientY
  document.addEventListener 'touchmove', (e) ->
    e.preventDefault()
    newY = e.touches[0].clientY
    window.scrollBy 0, -2 * (newY - currentY) if currentY
    currentY = newY
  return


