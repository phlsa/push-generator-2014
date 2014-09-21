fullString = ""
capturedString = ""
visibleString = ""
letterQueue = []
animating = false


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
        Colors.setGradientForFace f, visibleString.length % 3
      #@geometry.faces[0].vertexColors[0] = new THREE.Color(0xFF0000)
      # /EXPERIMENTAL


      @mesh.translateOnAxis(@base.normal, 2)
    return @mesh

  tick: ->
    # @inflation = 1
    animating = true
    if @inflation < 1
      @inflation += 0.05
      @mesh.translateOnAxis(@base.normal, -0.05*2)
    else
      animating = false
      this.tick = ->
        return null


Colors =
  setGradientForFace: (f, index) ->
    if index is 0
      f.vertexColors[0] = new THREE.Color(0xC50265)
      f.vertexColors[1] = new THREE.Color(0xFF781C)
      f.vertexColors[2] = new THREE.Color(0xFF781C)
    else if index is 1
      f.vertexColors[0] = new THREE.Color(0xC50265)
      f.vertexColors[1] = new THREE.Color(0x00D0D0)
      f.vertexColors[2] = new THREE.Color(0x00D0D0)
    else
      f.vertexColors[0] = new THREE.Color(0x000000)
      f.vertexColors[1] = new THREE.Color(0x333333)
      f.vertexColors[2] = new THREE.Color(0x333333)


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
scene = new THREE.Scene()
renderer = new THREE.WebGLRenderer({alpha: true})
renderer.setSize(window.innerWidth, window.innerHeight)
document.body.appendChild(renderer.domElement)


# Lights
lightBox = new THREE.Object3D()
# # lightBox.add(new THREE.AmbientLight 0x111111)
# l1 = new THREE.PointLight(0xffffff, 1, 100)
# l1.position.set(0, 0.5, 1)
# lightBox.add(l1)
# l2 = new THREE.PointLight(0xffffff, 1, 100)
# l2.position.set(1, 0.5, 0)
# lightBox.add(l2)
# l3 = new THREE.PointLight(0xffffff, 1, 100)
# l3.position.set(-0.5, -0.5, -3)
# lightBox.add(l3)
# l4 = new THREE.PointLight(0xffffff, 1, 100)
# l4.position.set(0.5, 0.5, 3)
# lightBox.add(l4)

scene.add(lightBox)

# Set up geometry
f1 = new Face(
  new THREE.Vector3(0, 0, 0),
  new THREE.Vector3(0, 0.5, 0),
  new THREE.Vector3(0.5, 0.5, 0.5))

# Create the object that holds all meshes
meshBox = new THREE.Object3D()
meshCenter = {x:0, y:0, z:0}
tetras = []
tetras.push new Tetra(f1, 0.3)
meshBox.add(tetras[0].getMesh())
for n in [0..1]
  t = addTetra(1)
  meshBox.add(t.getMesh())

# Create boxes for centering the meshes
rotationBox = new THREE.Object3D()
scene.add(meshBox)
scene.add(rotationBox)

# Camera setup
camera = new THREE.PerspectiveCamera( 45, window.innerWidth / window.innerHeight, 0.1, 1000 )
camera.position.z = 10
rotationBox.add( camera )

bbox = new THREE.BoundingBoxHelper(meshBox)

# Rendering
render = -> 
  requestAnimationFrame(render)
  _.each tetras, (item) -> item.tick()
  rotationBox.rotation.y += 0.01
  lightBox.rotation.y -= 0.01

  # Camera testing
  unless animating
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

render()


nextLetter = ->
  return if fullString is capturedString
  l = fullString[capturedString.length]
  capturedString += l

  frequencies = Language.getChar(l)
  frequencies = [frequencies[0], frequencies[1], frequencies[2]]

  baseTetra = _.last(tetras)
  _.each frequencies, (freq, index) ->
    after index*50, ->
      t = addTetra(freq, baseTetra)
      meshBox.add(t.getMesh())
  
  #resume once the letter is finished
  after frequencies.length*50, ->
    visibleString += l
    letterQueue.splice(0, 1)
    nextLetter()

# Interaction
input = document.getElementById('generator-input')
input.value = getURLText()
input.focus()

if input.value isnt ""
  fullString = input.value
  nextLetter()

document.addEventListener 'mousemove', (e) ->
  rotationBox.rotation.x = (e.clientY / window.innerHeight - 0.5) * 3


input.addEventListener 'input', (e) ->
  str = e.currentTarget.value
  if str.substr(0, fullString.length) isnt fullString
    input.value = fullString
  else
    fullString = str
    updateLocationBar(fullString)
  nextLetter()


reset = document.getElementById('generator-reset')
reset.addEventListener 'click', (e) ->
  url = location.protocol + '//' + location.host + location.pathname
  window.location.href = url
