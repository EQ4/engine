part of flutter_sprites;

enum PhysicsBodyType {
    static,
    dynamic
}

class PhysicsBody {
  PhysicsBody(this.shape, {
    this.tag: null,
    this.type: PhysicsBodyType.dynamic,
    double density: 1.0,
    double friction: 0.0,
    double restitution: 0.0,
    bool isSensor: false,
    Offset linearVelocity: Offset.zero,
    double angularVelocity: 0.0,
    this.linearDampening: 0.0,
    double angularDampening: 0.0,
    bool allowSleep: true,
    bool awake: true,
    bool fixedRotation: false,
    bool bullet: false,
    bool active: true,
    this.gravityScale: 1.0,
    collisionCategory: "Default",
    collisionMask: null
  }) {
    this.density = density;
    this.friction = friction;
    this.restitution = restitution;
    this.isSensor = isSensor;

    this.linearVelocity = linearVelocity;
    this.angularVelocity = angularVelocity;
    this.angularDampening = angularDampening;

    this.allowSleep = allowSleep;
    this.awake = awake;
    this.fixedRotation = fixedRotation;
    this.bullet = bullet;
    this.active = active;

    this.collisionCategory = collisionCategory;
    this.collisionMask = collisionMask;
  }

  Vector2 _lastPosition;
  double _lastRotation;
  Vector2 _targetPosition;
  double _targetAngle;

  double _scale;

  Object tag;

  final PhysicsShape shape;

  PhysicsBodyType type;

  double _density;

  double get density => _density;

  set density(double density) {
    _density = density;

    if (_body == null)
      return;
    for (box2d.Fixture f = _body.getFixtureList(); f != null; f = f.getNext()) {
      f.setDensity(density);
    }
  }

  double _friction;

  double get friction => _friction;

  set friction(double friction) {
    _friction = friction;

    if (_body == null)
      return;
    for (box2d.Fixture f = _body.getFixtureList(); f != null; f = f.getNext()) {
      f.setFriction(friction);
    }
  }

  double _restitution;

  double get restitution => _restitution;

  set restitution(double restitution) {
    _restitution = restitution;

    if (_body == null)
      return;
    for (box2d.Fixture f = _body.getFixtureList(); f != null; f = f.getNext()) {
      f.setRestitution(restitution);
    }
  }

  bool _isSensor;

  bool get isSensor => _isSensor;

  set isSensor(bool isSensor) {
    _isSensor = isSensor;

    if (_body == null)
      return;
    for (box2d.Fixture f = _body.getFixtureList(); f != null; f = f.getNext()) {
      f.setSensor(isSensor);
    }
  }

  Offset _linearVelocity;

  Offset get linearVelocity {
    if (_body == null)
      return _linearVelocity;
    else {
      double dx = _body.linearVelocity.x * _physicsNode.b2WorldToNodeConversionFactor;
      double dy = _body.linearVelocity.y * _physicsNode.b2WorldToNodeConversionFactor;
      return new Offset(dx, dy);
    }
  }

  set linearVelocity(Offset linearVelocity) {
    _linearVelocity = linearVelocity;

    if (_body != null) {
      Vector2 vec = new Vector2(
        linearVelocity.dx / _physicsNode.b2WorldToNodeConversionFactor,
        linearVelocity.dy / _physicsNode.b2WorldToNodeConversionFactor
      );
      _body.linearVelocity = vec;
    }
  }

  double _angularVelocity;

  double get angularVelocity {
    if (_body == null)
      return _angularVelocity;
    else
      return _body.angularVelocity;
  }

  set angularVelocity(double angularVelocity) {
    _angularVelocity = angularVelocity;

    if (_body != null) {
      _body.angularVelocity = angularVelocity;
    }
  }

  // TODO: Should this be editable in box2d.Body ?
  final double linearDampening;

  double _angularDampening;

  double get angularDampening => _angularDampening;

  set angularDampening(double angularDampening) {
    _angularDampening = angularDampening;

    if (_body != null)
      _body.angularDamping = angularDampening;
  }

  bool _allowSleep;

  bool get allowSleep => _allowSleep;

  set allowSleep(bool allowSleep) {
    _allowSleep = allowSleep;

    if (_body != null)
      _body.setSleepingAllowed(allowSleep);
  }

  bool _awake;

  bool get awake {
    if (_body != null)
      return _body.isAwake();
    else
      return _awake;
  }

  set awake(bool awake) {
    _awake = awake;

    if (_body != null)
      _body.setAwake(awake);
  }

  bool _fixedRotation;

  bool get fixedRotation => _fixedRotation;

  set fixedRotation(bool fixedRotation) {
    _fixedRotation = fixedRotation;

    if (_body != null)
      _body.setFixedRotation(fixedRotation);
  }

  bool _bullet;

  bool get bullet => _bullet;

  set bullet(bool bullet) {
    _bullet = bullet;

    if (_body != null) {
      _body.setBullet(bullet);
    }
  }

  bool _active;

  bool get active {
    if (_body != null)
      return _body.isActive();
    else
      return _active;
  }

  set active(bool active) {
    _active = active;

    if (_body != null)
      _body.setActive(active);
  }

  double gravityScale;

  Object _collisionCategory = null;

  Object get collisionCategory {
    return _collisionCategory;
  }

  set collisionCategory(Object collisionCategory) {
    _collisionCategory = collisionCategory;
    _updateFilter();
  }

  List<Object> _collisionMask = null;

  List<Object> get collisionMask => _collisionMask;

  set collisionMask(List<Object> collisionMask) {
    _collisionMask = collisionMask;
    _updateFilter();
  }

  box2d.Filter get _b2Filter {
    print("_physicsNode: $_physicsNode groups: ${_physicsNode._collisionGroups}");
    box2d.Filter f = new box2d.Filter();
    f.categoryBits = _physicsNode._collisionGroups.getBitmaskForKeys([_collisionCategory]);
    f.maskBits = _physicsNode._collisionGroups.getBitmaskForKeys(_collisionMask);

    print("Filter: $f category: ${f.categoryBits} mask: ${f.maskBits}");

    return f;
  }

  void _updateFilter() {
    if (_body != null) {
      box2d.Filter filter = _b2Filter;
      for (box2d.Fixture fixture = _body.getFixtureList(); fixture != null; fixture = fixture.getNext()) {
        fixture.setFilterData(filter);
      }
    }
  }

  PhysicsWorld _physicsNode;
  Node _node;

  box2d.Body _body;

  List<PhysicsJoint> _joints = <PhysicsJoint>[];

  bool _attached = false;

  void applyForce(Offset force, Point worldPoint) {
    assert(_body != null);

    Vector2 b2Force = new Vector2(
      force.dx / _physicsNode.b2WorldToNodeConversionFactor,
      force.dy / _physicsNode.b2WorldToNodeConversionFactor);

    Vector2 b2Point = new Vector2(
      worldPoint.x / _physicsNode.b2WorldToNodeConversionFactor,
      worldPoint.y / _physicsNode.b2WorldToNodeConversionFactor
    );

    _body.applyForce(b2Force, b2Point);
  }

  void applyForceToCenter(Offset force) {
    assert(_body != null);

    Vector2 b2Force = new Vector2(
      force.dx / _physicsNode.b2WorldToNodeConversionFactor,
      force.dy / _physicsNode.b2WorldToNodeConversionFactor);

    _body.applyForceToCenter(b2Force);
  }

  void applyTorque(double torque) {
    assert(_body != null);

    _body.applyTorque(torque / _physicsNode.b2WorldToNodeConversionFactor);
  }

  void applyLinearImpulse(Offset impulse, Point worldPoint, [bool wake = true]) {
    assert(_body != null);

    Vector2 b2Impulse = new Vector2(
      impulse.dx / _physicsNode.b2WorldToNodeConversionFactor,
      impulse.dy / _physicsNode.b2WorldToNodeConversionFactor);

    Vector2 b2Point = new Vector2(
      worldPoint.x / _physicsNode.b2WorldToNodeConversionFactor,
      worldPoint.y / _physicsNode.b2WorldToNodeConversionFactor
    );

    _body.applyLinearImpulse(b2Impulse, b2Point, wake);
  }

  void applyAngularImpulse(double impulse) {
    assert(_body != null);

    _body.applyAngularImpulse(impulse / _physicsNode.b2WorldToNodeConversionFactor);
  }

  void _attach(PhysicsWorld physicsNode, Node node) {
    assert(_attached == false);

    _physicsNode = physicsNode;

    // Account for physics groups
    Point positionWorld = node._positionToPhysics(node.position, node.parent);
    double rotationWorld = node._rotationToPhysics(node.rotation, node.parent);
    double scaleWorld = node._scaleToPhysics(node.scale, node.parent);

    // Update scale
    _scale = scaleWorld;

    // Create BodyDef
    box2d.BodyDef bodyDef = new box2d.BodyDef();
    bodyDef.linearVelocity = new Vector2(linearVelocity.dx, linearVelocity.dy);
    bodyDef.angularVelocity = angularVelocity;
    bodyDef.linearDamping = linearDampening;
    bodyDef.angularDamping = angularDampening;
    bodyDef.allowSleep = allowSleep;
    bodyDef.awake = awake;
    bodyDef.fixedRotation = fixedRotation;
    bodyDef.bullet = bullet;
    bodyDef.active = active;
    bodyDef.gravityScale = gravityScale;
    if (type == PhysicsBodyType.dynamic)
      bodyDef.type = box2d.BodyType.DYNAMIC;
    else
      bodyDef.type = box2d.BodyType.STATIC;

    // Convert to world coordinates and set position and angle
    double conv = physicsNode.b2WorldToNodeConversionFactor;
    bodyDef.position = new Vector2(positionWorld.x / conv, positionWorld.y / conv);
    bodyDef.angle = radians(rotationWorld);

    // Create Body
    _body = physicsNode.b2World.createBody(bodyDef);

    _createFixtures(physicsNode);

    _body.userData = this;

    _node = node;

    _attached = true;

    // Attach any joints
    for (PhysicsJoint joint in _joints) {
      if (joint.bodyA._attached && joint.bodyB._attached) {
        joint._attach(physicsNode);
      }
    }
  }

  void _createFixtures(PhysicsWorld physicsNode) {
    // Create FixtureDef
    box2d.FixtureDef fixtureDef = new box2d.FixtureDef();
    fixtureDef.friction = friction;
    fixtureDef.restitution = restitution;
    fixtureDef.density = density;
    fixtureDef.isSensor = isSensor;
    fixtureDef.filter = _b2Filter;

    // Get shapes
    List<box2d.Shape> b2Shapes = <box2d.Shape>[];
    List<PhysicsShape> physicsShapes = <PhysicsShape>[];
    _addB2Shapes(physicsNode, shape, b2Shapes, physicsShapes);

    // Create fixtures
    for (int i = 0; i < b2Shapes.length; i++) {
      box2d.Shape b2Shape = b2Shapes[i];
      PhysicsShape physicsShape = physicsShapes[i];

      fixtureDef.shape = b2Shape;
      box2d.Fixture fixture = _body.createFixtureFromFixtureDef(fixtureDef);
      fixture.userData = physicsShape;
    }
  }

  void _detach() {
    if (_attached) {
      _physicsNode._bodiesScheduledForDestruction.add(_body);
      _attached = false;
    }
  }

  void _updateScale(PhysicsWorld physicsNode) {
    // Destroy old fixtures
    for (box2d.Fixture fixture = _body.getFixtureList(); fixture != null; fixture = fixture.getNext()) {
      _body.destroyFixture(fixture);
    }

    // Make sure we create new b2Shapes
    shape._invalidate();

    // Create new fixtures
    _createFixtures(physicsNode);
  }

  void _addB2Shapes(PhysicsWorld physicsNode, PhysicsShape shape, List<box2d.Shape> b2Shapes, List<PhysicsShape> physicsShapes) {
    if (shape is PhysicsShapeGroup) {
      for (PhysicsShape child in shape.shapes) {
        _addB2Shapes(physicsNode, child, b2Shapes, physicsShapes);
      }
    } else {
      b2Shapes.add(shape.getB2Shape(physicsNode, _scale));
      physicsShapes.add(shape);
    }
  }
}
