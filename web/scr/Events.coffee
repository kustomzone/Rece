$(document).ready ->

  #Fix Tiles Height
  fixTilesAndInstances = ->
    p = $('.layers').height() + $('.tools').height() + $('#topbar').height()
    e = $(window).height() - (p + conf.tileSize + 16)
    $('.tiles')[0].style.height = e
    $('.instances')[0].style.height = e
  $(window).resize fixTilesAndInstances
  fixTilesAndInstances()

  #Navbar Items
  $('#Quit').on 'click', ->win.close()
  $('#LoadProject').on 'click', window.loadProject
  $('#SaveLevel').on 'click', window.saveLevel
  $('#OpenLevel').on 'click', window.openLevel

  #Tool Selection
  $.each $('.tool'), (i, e)->
    $(e).on 'click', (me)->
      $.each $('.tool'), (i, e)->
        $(e).removeClass 'active'
      conf.tool = $(me.target).attr('id')
      $(me.target).addClass 'active'

  #Switcher Selection
  $.each $('.switcheritem'), (i, e)->
    $(e).on 'click', (me)->
      $.each $('.switcheritem'), (i, e)->
        $(e).removeClass 'active'
      conf.switcher = $(me.target).attr('id')
      $(me.target).addClass 'active'

      $('.tiles').removeClass 'active'
      $('.instances').removeClass 'active'
      $(".#{$(me.target).attr('id').toLowerCase()}").addClass 'active'


  window.updateTilesAndInstances = ->
    #Tile Selection
    $.each $('.tile'), (i, e)->
      $(e).on 'click', (me)->
        $.each $('.tile'), (i, e)->
          $(e).removeClass 'active'
        conf.tile =
          Array.prototype.indexOf.call e.parentElement.children,
                                       e
        $(e).addClass 'active'

    #Instance Selection
    $.each $('.instance'), (i, e)->
      $(e).on 'click', (me)->
        $.each $('.instance'), (i, e)->
          $(e).removeClass 'active'
        conf.instance =
          Array.prototype.indexOf.call e.parentElement.children,
                                       e
        $(e).addClass 'active'

    #Collate All Tile Image Src's
    window.tlis = []
    $.each $('.tile-img'), (i, e)->
      i = new Image
      i.src = e.src
      tlis.push i

    #Collate All Tile Entity Src's
    window.inis = []
    $.each $('.instance-img'), (i, e)->
      i = new Image
      i.src = e.src
      inis.push i
  updateTilesAndInstances()


  #Layer Selection
  $.each $('.layer'), (i, e)->
    $(e).on 'click', (me)->
      #Change Layer Name
      if $(me.target).hasClass 'active'
        n = me.target.childNodes[0]
        vex.dialog.prompt {
          message: "New Layer Name"
          placeholder: n.nodeValue
          callback: (value)->n.nodeValue = value or n.nodeValue
        }

      #Change Selected Layer
      unless $(me.target).hasClass('remove') or $(me.target).hasClass('add')
        $.each $('.layer'), (i, e)->
          $(e).removeClass 'active'
        changeLayer Array.prototype.indexOf.call(me.target.parentElement.children, me.target) - 1
        $(me.target).addClass 'active'

  #Layer Deletion
  $.each $('.layer'), (i, e)->
    $(e).on 'click', (me)->
      if $(me.target).hasClass 'remove'
        p = me.target.parentElement
        id = Array.prototype.indexOf.call(p.parentElement.children, p)
        p.parentElement.removeChild p
        tls.splice id-1, 1
        conf.layer -= 1
        $($('.layers').children()[id-1]).addClass 'active'
        draw()

  #Layer Addition
  $.each $('.layer'), (i, e)->
    $(e).on 'click', (me)->
      if $(me.target).hasClass 'add'
        n = $('#TemplateLayer').clone true
        r = $('#TemplateLayer').children(0).clone true

        n.removeClass 'template'
        n.addClass 'clone'
        n.prop('id', '')
        n[0].innerHTML = "Layer #{$('.layers').children().length-2}"

        n.insertBefore me.target
        r.appendTo n


  #Create global reference to editor canvas and its context
  window.cnvs = $('#editor')[0]
  window.cnvsg = $('#grid')[0]
  window.cnvss = $('#selection')[0]
  window.ctx = cnvs.getContext('2d')
  window.ctxg = cnvsg.getContext('2d')
  window.ctxs = cnvss.getContext('2d')

  #Ensure that the canvas is ok with its size!
  resCanvas = ->
    cnvs.width = $(cnvs).width()
    cnvs.height = $(cnvs).height()
    cnvsg.width = $(cnvsg).width()
    cnvsg.height = $(cnvsg).height()
    cnvss.width = $(cnvss).width()
    cnvss.height = $(cnvss).height()

  #Do it when we resize
  $(window).resize ->
    resCanvas()
    drawGrid()
    drawTiles()

  #Do it now!
  resCanvas()
  drawGrid()
  drawTiles()

  #Reload previous project
  updateProject()

$(document).on 'mousewheel', (e)->
  if e.target is $('#selection')[0] or
     e.target is $('#grid')[0] or
     e.target is $('#editor')[0]
      Camera.mouseWheel e.originalEvent
      drawGrid()
      draw()

$(document).on 'keydown', (e)->
  if $(e.target).attr('name') isnt 'vex'
    if not e.ctrlKey
      switch e.key
        when 'Alt'
          if conf.oldtool is 'None'
            $.each $('.tool'), (i, e)->
              $(e).removeClass 'active'
            $('#Picker').addClass 'active'
            conf.oldtool = conf.tool
            conf.tool = 'Picker'
          e.preventDefault()
          return

        when 'ArrowLeft'
          shiftSelected(-1, 0)
        when 'ArrowRight'
          shiftSelected(1, 0)
        when 'ArrowUp'
          shiftSelected(0, -1)
        when 'ArrowDown'
          shiftSelected(0, 1)

        when 'd'
          conf.tool = 'Place'
          $.each $('.tool'), (i, e)->
            $(e).removeClass 'active'
          $('#Place').addClass 'active'
        when 'e'
          conf.tool = 'Remove'
          $.each $('.tool'), (i, e)->
            $(e).removeClass 'active'
          $('#Remove').addClass 'active'
        when 's'
          conf.tool = 'Marquee'
          $.each $('.tool'), (i, e)->
            $(e).removeClass 'active'
          $('#Marquee').addClass 'active'
        when 'g'
          conf.grid = not conf.grid
          drawGrid()
        when 'Delete'
          for tile in conf.selection.tiles
            tls[conf.layer].splice tls[conf.layer].indexOf(tile), 1
          conf.selection.tiles = []
          e.preventDefault()
          draw()
    else
      switch e.key
        when 'a'
          conf.selection.tiles = []
          for tile in tls[conf.layer]
            conf.selection.tiles.push tile
          e.preventDefault()
          draw()
        when 'i'
          os = conf.selection.tiles
          conf.selection.tiles = []
          for tile in tls[conf.layer]
            if -1 is os.indexOf tile
              conf.selection.tiles.push tile
          e.preventDefault()
          draw()
        when 'v'
          #Duplicate
          os = conf.selection.tiles
          conf.selection.tiles = []
          for tile in os
            t = new Entity tile.type, tile.id, tile.x, tile.y
            conf.selection.tiles.push t
            tls[conf.layer].push t
        when 'd'
          conf.selection.tiles = []
          e.preventDefault()
          draw()

        when 'ArrowLeft'
          if conf.switcher is 'Instances' then shiftSelected(-conf.tileSize/4, 0)
        when 'ArrowRight'
          if conf.switcher is 'Instances' then shiftSelected(conf.tileSize/4, 0)
        when 'ArrowUp'
          if conf.switcher is 'Instances' then shiftSelected(0, -conf.tileSize/4)
        when 'ArrowDown'
          if conf.switcher is 'Instances' then shiftSelected(0, conf.tileSize/4)

$(document).on 'keyup', (e)->
  if e.key is 'Alt'
    $.each $('.tool'), (i, e)->
      $(e).removeClass 'active'
    $("##{conf.oldtool}").addClass 'active'
    conf.tool = conf.oldtool
    conf.oldtool = 'None'
    e.preventDefault()

$(document).on 'mousemove', (e)->
  conf.mouse.x = e.clientX
  conf.mouse.y = e.clientY
  Camera.mouseMove e
  if e.buttons is 1 or e.buttons is 3
    processClick e, false

$(document).on 'mousedown', (e)->
  #Press mouse
  conf.mouse.down[e.button] = true

  if e.button is 2
    if e.target is $('#selection')[0] or
       e.target is $('#grid')[0] or
       e.target is $('#editor')[0]
        Camera.startDragging()

  #Use Tools
  if e.button is 0
    if e.target is $('#selection')[0] or
       e.target is $('#grid')[0] or
       e.target is $('#editor')[0]
      window.processClick e, true

$(document).on 'mouseup', (e)->
  #Release mouse values
  conf.mouse.down[e.button] = false

  if e.button is 2
    Camera.stopDragging()

  #Finish Selecting
  if e.button is 0
    if conf.selection.selecting
      conf.selection.selecting = false
      conf.selection.tiles = []
      [x1, y1, x2, y2] = conf.selection.getCoords()

      if e.ctrlKey
        xd = (x2-x1)
        yd = (y2-y1)
        if conf.switcher is 'Instances'
          xd /= conf.tileSize
          yd /= conf.tileSize
        for i in [0...xd]
          for j in [0...yd]
            xx = x1 + i
            yy = y1 + j
            if conf.switcher is 'Tiles'
              tls[conf.layer].push new Entity 'Tile',
                                              conf.tile,
                                              xx,
                                              yy
            if conf.switcher is 'Instances'
              tls[conf.layer].push new Entity 'Instance', conf.tile, x1 + (i * conf.tileSize), y1 + (j * conf.tileSize)
      else
        for t in tls[conf.layer]
            if t.x >= x1 and t.y >= y1 and t.x < x2 and t.y < y2
              conf.selection.tiles.push t
    draw()
