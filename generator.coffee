config = 
  autoCamera: yes
  autoRotate: yes
  autoRotateY: yes
  rotateOnMouseMove: no
  letterDelay: 50     # default: 50
  useDelay: yes
  useAnimation: yes
  magnification: 3    # only used when setting the zoom level at the end of the build
  forceCenterOnFinish: no
  saveFileOnFinish: no
  autoDimensions: no
  dimensions:
    width: 500
    height: 500

fullString = ""
capturedString = ""
visibleString = ""
letterQueue = []
animating = false
animationId = 0


class Face
  constructor: (a, b, c) ->
    @a = -> return a
    @b = -> return b
    @c = -> return c

    ab = new THREE.Vector3().subVectors(@a(), @b())
    ac = new THREE.Vector3().subVectors(@a(), @c())
    @normal = new THREE.Vector3().crossVectors(ab, ac)
    @normal.normalize()

  m: ->
    x = (@a().x + @b().x + @c().x) / 3
    y = (@a().y + @b().y + @c().y) / 3
    z = (@a().z + @b().z + @c().z) / 3
    return new THREE.Vector3(x, y, z)

class Tetra
  constructor: (base, elevation) ->
    @elevation = elevation
    @base = base
    @color = [Math.random()*255, Math.random()*255, Math.random()*255]
    @inflation = 0

  face: (n) ->
    if n==0
      return @base
    else if n==1
      return new Face(@base.a(), @base.b(), @tip())
    else if n==2
      return new Face(@base.b(), @base.c(), @tip())
    else if n==3
      return new Face(@base.c(), @base.a(), @tip())

  tip: ->
    n = @base.normal.clone()
    n.multiplyScalar(@elevation)
    n.add(@base.m())
    return n

  base: -> return @face(0)

  updateGeometry: ->
    points = [
      @base.a(),
      @base.b(),
      @base.c(),
      @tip()]
    @geometry =  new THREE.ConvexGeometry(points)

  getMesh: ->
    unless @mesh?
      this.updateGeometry()
      material = new THREE.MeshBasicMaterial(shading: THREE.FlatShading, vertexColors: THREE.VertexColors)
      @mesh = new THREE.Mesh(@geometry, material)

      # EXPERIMENTAL
      _.each @geometry.faces, (f, i) ->
        Colors.setGradientForFace f, visibleString.length % 2
      #@geometry.faces[0].vertexColors[0] = new THREE.Color(0xFF0000)
      # /EXPERIMENTAL


      @mesh.translateOnAxis(@base.normal, 2)
    return @mesh

  tick: ->
    # check if we need to animate at all
    unless config.useAnimation
      animating = false
      @inflation = 1
      @mesh.translateOnAxis(@base.normal, -2)
      this.tick = -> return null

    # @inflation = 1
    animating = true
    if @inflation < 1
      @inflation += 0.05
      @mesh.translateOnAxis(@base.normal, -0.05*2)
    else
      animating = false
      this.tick = -> return null


Colors =
  setGradientForFace: (f, index) ->
    if index is 0
      f.vertexColors[0] = new THREE.Color(0xC50265)
      f.vertexColors[1] = new THREE.Color(0xFF781C)
      f.vertexColors[2] = new THREE.Color(0xFF781C)
    else #if index is 1
      f.vertexColors[0] = new THREE.Color(0xC50265)
      f.vertexColors[1] = new THREE.Color(0x00D0D0)
      f.vertexColors[2] = new THREE.Color(0x00D0D0)
    # else
    #   f.vertexColors[0] = new THREE.Color(0x000000)
    #   f.vertexColors[1] = new THREE.Color(0x333333)
    #   f.vertexColors[2] = new THREE.Color(0x333333)


addTetra = (elevation, prev) ->
  prev = _.last tetras unless prev?
  side = Math.floor(Math.random()*3) + 1
  side = tetras.length % 3 + 1
  newTetra = new Tetra prev.face(side), elevation
  tetras.push newTetra
  return newTetra

after = (t, fn) -> window.setTimeout(fn, t)

# Utility functions
dist = (a, b) ->
  dx = a.x - b.x
  dy = a.y - b.y
  dz = a.z - b.z
  return Math.abs Math.sqrt(dx*dx + dy*dy + dz*dz)


# Scene Setup
initScene = ->
  console.log 'initializing scene'
  # Clear existing scene
  window.cancelAnimationFrame(animationId)
  canv = document.getElementsByTagName('canvas')
  canv[0].parentNode.removeChild(canv[0]) if canv[0]?

  window.parentElement = document.getElementById('generator-main')

  window.scene = new THREE.Scene()
  window.renderer = new THREE.WebGLRenderer({alpha: true, preserveDrawingBuffer: true})
  if config.autoDimensions
    config.dimensions =
      width: parentElement.offsetWidth
      height: (parentElement.offsetWidth/16)*9
  renderer.setSize(config.dimensions.width, config.dimensions.height)
  parentElement.appendChild(renderer.domElement)


  # Lights
  window.lightBox = new THREE.Object3D()
  scene.add(lightBox)

  # Set up geometry
  f1 = new Face(
    new THREE.Vector3(0, 0, 0),
    new THREE.Vector3(0, 0.5, 0),
    new THREE.Vector3(0.5, 0.5, 0.5))

  # Create the object that holds all meshes
  window.meshBox = new THREE.Object3D()
  window.meshCenter = {x:0, y:0, z:0}
  window.tetras = []
  tetras.push new Tetra(f1, 0.3)
  meshBox.add(tetras[0].getMesh())
  for n in [0..1]
    t = addTetra(1)
    meshBox.add(t.getMesh())

  # Create boxes for centering the meshes
  window.rotationBox = new THREE.Object3D()
  scene.add(meshBox)
  scene.add(rotationBox)

  # Camera setup
  window.camera = new THREE.PerspectiveCamera( 45, config.dimensions.width / config.dimensions.height, 0.1, 1000 )
  camera.position.z = 10
  rotationBox.add( camera )

  window.bbox = new THREE.BoundingBoxHelper(meshBox)

  # Kick off rendering
  render()



createRotationBuild = (onEnd) ->
  build = 
    onEnd: onEnd
    maxRotation: 100
    increment: 0.01
    multiplyer: 1.03
    baseRotation: rotationBox.rotation.y

    perform: ->
      rotationBox.rotation.y += @increment
      camera.position.z = camera.position.z + 2
      @increment *= @multiplyer
      if rotationBox.rotation.y-@baseRotation > @maxRotation
        @onEnd()
  return build

createExplosionBuild = (onEnd, direction, max) ->
  animating = no
  direction = 1 unless direction?
  build = 
    onEnd: onEnd
    maxPos: max
    increment: 0.2*direction
    currentPos: 0

    perform: ->
      inc = @increment
      _.each tetras, (tetra, index) ->
        tetra.getMesh().translateOnAxis(tetra.base.normal, -inc)
      @currentPos += @increment
      if Math.abs(@currentPos) > Math.abs(@maxPos)
        animating = yes
        @onEnd()


BuildOut =
  active: no
  init: ->
    BuildOut.actions = [
      createExplosionBuild(BuildOut.nextAction, 1, 10),
      #createExplosionBuild(BuildOut.nextAction, -1, 20),
      createRotationBuild(BuildOut.nextAction)
    ]
    BuildOut.currentAction = 0
    BuildOut.active = yes
    animating = yes

  tick: ->
    action = BuildOut.actions[BuildOut.currentAction]
    action.perform() if action?

  nextAction: ->
    console.log "next buildout"
    BuildOut.currentAction += 1
    unless BuildOut.actions[BuildOut.currentAction]?
      BuildOut.active = no
      animating = no


# Rendering
render = -> 
  window.animationId = requestAnimationFrame(render)
  _.each tetras, (item) -> item.tick()
  
  if config.autoRotate
    rotationBox.rotation.y += 0.01
    if config.autoRotateY
      rotationBox.rotation.x += 0.005
  # lightBox.rotation.y -= 0.01

  # BuildOuts
  if BuildOut.active
    BuildOut.tick()

  # Camera testing
  unless animating or !config.autoCamera
    # Positioning
    bbox.update()
    c = bbox.box.center()
    rc = rotationBox.position
    rotationBox.position.set rc.x+(c.x-rc.x)/5, rc.y+(c.y-rc.y)/7, rc.z+(c.z-rc.z)/7

    # Zooming
    size = bbox.box.size().x
    size = 3 if size < 3
    dist =  size / (Math.sin( camera.fov * (Math.PI/180) / 2) )
    camera.position.z = camera.position.z-(camera.position.z-dist)/5
  
  renderer.render(scene, camera)





buildFinished = ->
  console.log 'build finished'
  
  if config.forceCenterOnFinish
    # update position
    bbox.update()
    c = bbox.box.center()
    rc = rotationBox.position
    rotationBox.position.set rc.x+(c.x-rc.x), rc.y+(c.y-rc.y), rc.z+(c.z-rc.z)

    # update zooming
    size = bbox.box.size().x
    #size = 3 if size < 3
    dist =  size / (Math.sin( camera.fov * (Math.PI/180) / 2) )
    camera.position.z = dist/config.magnification

  if config.saveFileOnFinish
    after 10, ->
      #saveStaticImage(fullString)
      window.actionAfterBuild() if window.actionAfterBuild?



nextLetter = ->
  if fullString is capturedString
    _.defer buildFinished
    return
  l = fullString[capturedString.length]
  capturedString += l

  frequencies = Language.getChar(l)
  frequencies = [frequencies[0], frequencies[1], frequencies[2]]

  baseTetra = _.last(tetras)
  _.each frequencies, (freq, index) ->
    if config.useDelay
      after index*config.letterDelay, ->
        t = addTetra(freq, baseTetra)
        meshBox.add(t.getMesh())
    else
      t = addTetra(freq, baseTetra)
      meshBox.add(t.getMesh())
  
  #resume once the letter is finished
  if config.useDelay
    after frequencies.length*config.letterDelay, ->
      visibleString += l
      letterQueue.splice(0, 1)
      nextLetter()
  else
    visibleString += l
    letterQueue.splice(0, 1)
    nextLetter()

# Initialize the scene
initScene()

# Interaction
input = document.getElementById('generator-input')
input.value = getURLText()
input.focus()

if input.value isnt ""
  fullString = input.value
  nextLetter()

pMouse = {x:0, y:0}
document.addEventListener 'mousedown', (e) ->
    pMouse = {x: e.clientX, y: e.clientY}


if config.rotateOnMouseMove
  document.addEventListener 'mousemove', (e) ->
    rotationBox.rotation.x = (e.clientY / window.innerHeight - 0.5) * 3
else
  document.addEventListener 'mousemove', (e) ->
    if e.buttons isnt 0 and e.shiftKey is true
      rotationBox.rotation.y += (e.clientX-pMouse.x) * 0.01
      rotationBox.rotation.x += (e.clientY-pMouse.y) * 0.01
    _.defer -> pMouse = {x: e.clientX, y: e.clientY}

  document.addEventListener 'keydown', (e) ->
    if e.keyCode is 38 #UP
      rotationBox.rotation.z -= 0.1
    else if e.keyCode is 40 #DOWN
      rotationBox.rotation.z += 0.1


if not config.autoCamera
  document.addEventListener 'mousemove', (e) ->
    if e.buttons isnt 0
      rotationBox.position.x += (pMouse.x-e.clientX) / (window.innerWidth / 2)
      rotationBox.position.y += (e.clientY-pMouse.y) / (window.innerHeight / 2)
    _.defer -> pMouse = {x: e.clientX, y: e.clientY}

  document.addEventListener 'keydown', (e) ->
    if e.key is 'c'
      bbox.update()
      c = bbox.box.center()
      rc = rotationBox.position
      rotationBox.position.set rc.x+(c.x-rc.x), rc.y+(c.y-rc.y), rc.z+(c.z-rc.z)


input.addEventListener 'input', (e) ->
  str = e.currentTarget.value
  if str.substr(0, fullString.length) isnt fullString
    input.value = fullString
  else
    fullString = str
    updateLocationBar(fullString)
  nextLetter()


# Reset
reset = document.getElementById('generator-reset')
reset.addEventListener 'click', (e) ->
  url = location.protocol + '//' + location.host + location.pathname
  window.location.href = url

# Render Sequence
document.getElementById('render-sequence').addEventListener 'click', (e) ->
  e.preventDefault()
  list = parseNameData window.prompt('Enter names to be rendered separated by semicoli')
  renderSequence(list)

# Debug: Build out
document.getElementById('build-out').addEventListener 'click', (e) ->
  e.preventDefault()
  BuildOut.init()

saveStaticImage = (name, company) ->
  name = 'image-' + new Date().getTime() unless name?
  dataObj = renderer.domElement.toDataURL('image/png')

  $.post 'http://localhost/~psackl/generator-2014/saveImage.php', {
      'data': dataObj,
      'name': name
      'company': company
    }, (data) ->
      console.log( data )


renderSequence = (sequence) ->
  # Each element in sequence must have the format {first, last, company}
  config.saveFileOnFinish = yes

  renderNext = ->
    # reset all the strings
    fullString = ""
    capturedString = ""
    visibleString = ""
    letterQueue = []
    
    initScene()
    current = sequence.splice(0, 1)[0]
    fullString = "#{current.first} #{current.last}"
    console.log 'will render: ' + fullString
    if sequence.length > 0
      window.actionAfterBuild = ->
        saveStaticImage(fullString, current.company)
        renderNext()
    else
      window.actionAfterBuild = null
    nextLetter()

  renderNext()




