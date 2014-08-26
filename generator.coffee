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
      @mesh = new THREE.Mesh(@geometry, randomMaterial())
      @mesh.translateOnAxis(@base.normal, 2)
    return @mesh

  tick: ->
    if @inflation < 1
      @inflation += 0.05
      #@mesh.scale.x = @mesh.scale.y = @mesh.scale.z = @inflation
      @mesh.translateOnAxis(@base.normal, -0.05*2)
    else
      this.tick = ->
        return null


addTetra = (elevation) ->
  prev = _.last tetras
  side = Math.floor(Math.random()*3) + 1
  newTetra = new Tetra prev.face(side), elevation
  tetras.push newTetra
  return newTetra

after = (t, fn) -> window.setTimeout(fn, t)

# Scene Setup
scene = new THREE.Scene()
camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000)
renderer = new THREE.WebGLRenderer()
renderer.setSize(window.innerWidth, window.innerHeight)
document.body.appendChild(renderer.domElement)

# Materials
materials = [
  new THREE.MeshLambertMaterial(color: 0xFF781C),
  new THREE.MeshLambertMaterial(color: 0xC50265),
  new THREE.MeshLambertMaterial(color: 0x00D0D0)]
randomMaterial = ->
  n = Math.floor Math.random()*(materials.length)
  return materials[n]
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
tetras = []
tetras.push new Tetra(f1, 0.3)
meshBox.add(tetras[0].getMesh())
for n in [0..1]
  t = addTetra(Math.random()*0.5)
  meshBox.add(t.getMesh())

# Create boxes for centering the meshes
bbox = new THREE.BoundingBoxHelper(meshBox, 0xffffff)
rotationBox = new THREE.Object3D()
rotationBox.add(meshBox)

scene.add(rotationBox)
# rotationBox.add( bbox )


# Rendering
render = -> 
  requestAnimationFrame(render)
  _.each tetras, (item) -> item.tick()
  # rotationBox.rotation.y += 0.01
  lightBox.rotation.y += 0.02
  bbox.update()
  # meshBox.position.x = -bbox.box.size().x/4
  # meshBox.position.y = -bbox.box.size().y/4
  # meshBox.position.z = -bbox.box.size().z/4
  renderer.render(scene, camera)

render()

# Interaction
document.addEventListener 'mousemove', (e) ->
  rotationBox.rotation.x = (e.clientY / window.innerHeight - 0.5) * 3
  rotationBox.rotation.y = (e.clientX / window.innerWidth - 0.5) * 3

document.addEventListener 'keydown', (e) ->
  for n in [0..5]
    after n*100, ->
      t = addTetra(Math.random()*0.5)
      meshBox.add(t.getMesh())