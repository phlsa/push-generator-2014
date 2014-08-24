class Face
  constructor: (a, b, c) ->
    @a = -> return a
    @b = -> return b
    @c = -> return c

    ab = P.PVector.sub(@a(), @b())
    ac = P.PVector.sub(@a(), @c())
    @normal = ab.cross(ac)
    @normal.normalize()

  m: ->
    x = (@a().x + @b().x + @c().x) / 3
    y = (@a().y + @b().y + @c().y) / 3
    z = (@a().z + @b().z + @c().z) / 3
    return new P.PVector(x, y, z)


class Tetra
  constructor: (base, elevation) ->
    @elevation = elevation
    @base = base
    @color = [Math.random()*255, Math.random()*255, Math.random()*255]
    @elevationPercentage = 0

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
    n = @base.normal.get()
    n.mult(@elevation)
    n.add(@base.m())
    return n

  base: -> return @face(0)

  update: ->



drawFace = (f) ->
  P.beginShape()
  P.texture(window.tex)
  P.normal(f.normal.x, f.normal.y, f.normal.z)
  P.vertex f.a().x, f.a().y, f.a().z
  P.vertex f.b().x, f.b().y, f.b().z
  P.vertex f.c().x, f.c().y, f.c().z
  P.endShape(P.CLOSE)

drawTetra = (t) ->
  #P.fill(t.color[0], t.color[1], t.color[2])
  drawFace t.face(n) for n in [1..3]


tetras = []

addTetra = (elevation) ->
  prev = _.last tetras
  side = Math.floor(Math.random()*3) + 1
  newTetra = new Tetra prev.face(side), elevation
  tetras.push newTetra
  return newTetra

processingFunction = (p) ->
  p.setup = ->
    p.size 600, 600, p.OPENGL
    p.smooth()
    p.noStroke();
    window.tex = p.loadImage("../tex.png");
    window.P = p;
    window.f1 = new Face new P.PVector(0, 50, 0), new P.PVector(-50, 100, 100), new P.PVector(100, -100, 0)
    tetras.push new Tetra(f1, 70)
    addTetra(Math.random(50)+50) for n in [0..50]

  p.draw = ->
    p.background 20
    #p.scale(2)
    #p.lights()
    #p.ambientLight(100, 100, 100)
    p.translate(300, 300)
    #p.pointLight(255, 0, 0, -300, 0, 0)
    #p.pointLight(0, 255, 0, p.mouseX/2-300, p.mouseY/2-300, 200)
    #p.pointLight(0, 0, 255, p.mouseY/2-300, p.mouseX/2-300, 200)
    p.pushMatrix()
    p.translate(-300, -300)
    p.box(100)
    p.popMatrix()
    p.rotateY(p.radians(p.mouseX-300))
    p.rotateX(p.radians(p.mouseY-300))
    drawFace(f1)
    _.each tetras, (tetra) ->
      drawTetra tetra
    

  p.mouseClicked = ->
    addTetra(Math.random(50)+50)
    document.getElementById('canv').blur()


processing = new Processing document.getElementById('canv'), processingFunction
  