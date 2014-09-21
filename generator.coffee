fullString = ""
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
      material = new THREE.MeshLambertMaterial(shading: THREE.PhongShading, vertexColors: THREE.VertexColors)
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
      #@mesh.scale.x = @mesh.scale.y = @mesh.scale.z = @inflation
      @mesh.translateOnAxis(@base.normal, -0.05*2)
    else
      animating = false
      this.tick = ->
        return null


Colors =
  setGradientForFace: (f, index) ->
    if index is 0
      f.vertexColors[0] = new THREE.Color(0xFF781C)
      f.vertexColors[1] = new THREE.Color(0xC50265)
      f.vertexColors[2] = new THREE.Color(0xC50265)
    else if index is 1
      f.vertexColors[0] = new THREE.Color(0x00D0D0)
      f.vertexColors[1] = new THREE.Color(0xFF781C)
      f.vertexColors[2] = new THREE.Color(0xFF781C)
    else
      f.vertexColors[0] = new THREE.Color(0xC50265)
      f.vertexColors[1] = new THREE.Color(0x00D0D0)
      f.vertexColors[2] = new THREE.Color(0x00D0D0)


addTetra = (elevation, prev) ->
  prev = _.last tetras unless prev?
  side = Math.floor(Math.random()*3) + 1
  # dists = _.map [1,2,3], (item) ->
  #   dist(meshCenter, prev.face(item).m())
  # _.each dists, (item, index) ->
  #   if index is 0
  #     side = 0
  #   else
  #     if item > dists[index-1]
  #       side = index
  # side += 1
  # console.log side
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

centerOf = (obj) ->
  totalX = 0
  totalY = 0
  totalZ = 0
  _.each obj.children, (item, index) ->
    c = item.geometry.center()
    totalX += c.x
    totalY += c.y
    totalZ += c.z
  return { x: totalX/obj.children.length, y: totalY/obj.children.length, z: totalZ/obj.children.length }

# Scene Setup
scene = new THREE.Scene()
camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000)
renderer = new THREE.WebGLRenderer()
renderer.setSize(window.innerWidth, window.innerHeight)
document.body.appendChild(renderer.domElement)

camera.position.z = 3

# Lights
lightBox = new THREE.Object3D()
# lightBox.add(new THREE.AmbientLight 0x111111)
l1 = new THREE.PointLight(0xffffff, 1, 100)
l1.position.set(0, 0.5, 1)
lightBox.add(l1)
l2 = new THREE.PointLight(0xffffff, 1, 100)
l2.position.set(1, 0.5, 0)
lightBox.add(l2)
l3 = new THREE.PointLight(0xffffff, 1, 100)
l3.position.set(-0.5, -0.5, -3)
lightBox.add(l3)
l4 = new THREE.PointLight(0xffffff, 1, 100)
l4.position.set(0.5, 0.5, 3)
lightBox.add(l4)

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
camera.position.z = 5
rotationBox.add( camera )

bbox = new THREE.BoundingBoxHelper(meshBox)

# Rendering
render = -> 
  requestAnimationFrame(render)
  _.each tetras, (item) -> item.tick()
  rotationBox.rotation.y += 0.01
  lightBox.rotation.y += 0.01
  # unless animating
  #   c = centerOf(meshBox)
  #   meshBox.position.set(c.x, c.y, c.z)

  # Camera testing
  # Zoom and centerpoint stuff
  unless animating
    bbox.update()
    c = bbox.box.center()
    rc = rotationBox.position
    rotationBox.position.set rc.x+(c.x-rc.x)/5, rc.y+(c.y-rc.y)/7, rc.z+(c.z-rc.z)/7

    dist =  bbox.box.size().x / (Math.sin( camera.fov * (Math.PI/180) / 2) )
    camera.position.z = camera.position.z-(camera.position.z-dist)/5
  renderer.render(scene, camera)

render()


nextLetter = ->
  return if letterQueue.length is 0

  l = letterQueue[0]
  frequencies = Language.getChar(l)
  frequencies = [frequencies[0], frequencies[1], frequencies[2]]

  # meshCenter = centerOf(meshBox)
  # console.log meshCenter
  baseTetra = _.last(tetras)
  _.each frequencies, (freq, index) ->
    after index*50, ->
      t = addTetra(freq, baseTetra)
      meshBox.add(t.getMesh())
      # Scale the mesh when more tetras get added
      # meshBox.scale.set meshBox.scale.x * 0.995, meshBox.scale.y * 0.995, meshBox.scale.z * 0.995
      # Movement experiment
      #vecToLastTetra = _.last( _.filter(tetras, (v) -> v.inflation >=1) ).base.m()
      #meshBox.translateOnAxis(vecToLastTetra, -vecToLastTetra.length()/50)
      # TODO
      # - get exact amount of translation (or make a better guess)
      # - always calculate the distance from the last finished object
  
  #resume once the letter is finished
  after frequencies.length*50, ->
    visibleString += letterQueue[0]
    letterQueue.splice(0, 1)
    nextLetter()

# Interaction
prevMouse = x:0 ,y:0

document.addEventListener 'mousemove', (e) ->
  #rotationBox.rotation.x = (e.clientY / window.innerHeight - 0.5) * 3
  #rotationBox.rotation.y = (e.clientX / window.innerWidth - 0.5) * 3
  #xOff = e.clientX - prevMouse.x
  yOff = e.clientY - prevMouse.y
  prevMouse = x:e.clientX, y:e.clientY
  #rotationBox.rotation.x += yOff/window.innerHeight
  #rotationBox.rotation.y += xOff/window.innerWidth
  #meshBox.position.x = 2.5 - e.clientX/window.innerWidth*5
  #meshBox.geometry.computeBoundingBox()
  #console.log meshBox

  ###
  How to get to the bounding box
  - Calculate centre points of all meshes (tetras)
  - average them
  - Done
  ###

document.addEventListener 'keyup', (e) ->
  return if e.key.length > 1
  key = e.key.toLowerCase()
  fullString += key
  letterQueue.push(key)
  nextLetter() if letterQueue.length is 1
  

