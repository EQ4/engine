part of flutter_sprites;

typedef void PhysicsJointBreakCallback(PhysicsJoint joint);

abstract class PhysicsJoint {
  PhysicsJoint(this._bodyA, this._bodyB, this.breakingForce, this.breakCallback) {
    bodyA._joints.add(this);
    bodyB._joints.add(this);
  }

  PhysicsBody _bodyA;

  PhysicsBody get bodyA => _bodyA;

  PhysicsBody _bodyB;

  PhysicsBody get bodyB => _bodyB;

  final double breakingForce;

  final PhysicsJointBreakCallback breakCallback;

  bool _active = true;
  box2d.Joint _joint;

  PhysicsWorld _physicsNode;

  void _completeCreation() {
    if (bodyA._attached && bodyB._attached) {
      _attach(bodyA._physicsNode);
    }
  }

  void _attach(PhysicsWorld physicsNode) {
    if (_joint == null) {
      _physicsNode = physicsNode;
      _joint = _createB2Joint(physicsNode);
      _physicsNode._joints.add(this);
    }
  }

  void _detach() {
    if (_joint != null && _active) {
      _physicsNode.b2World.destroyJoint(_joint);
      _joint = null;
      _physicsNode._joints.remove(this);
    }
    _active = false;
  }

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode);

  void destroy() {
    _detach();
  }

  void _checkBreakingForce(double dt) {
    if (breakingForce == null) return;

    if (_joint != null && _active) {
      Vector2 reactionForce = new Vector2.zero();
      _joint.getReactionForce(1.0 / dt, reactionForce);

      if (breakingForce * breakingForce < reactionForce.length2) {
        // Destroy the joint
        destroy();

        // Notify any observer
        if (breakCallback != null)
          breakCallback(this);
      }
    }
  }
}

class PhysicsJointRevolute extends PhysicsJoint {
  PhysicsJointRevolute(
    PhysicsBody bodyA,
    PhysicsBody bodyB,
    this._worldAnchor, {
      this.lowerAngle: 0.0,
      this.upperAngle: 0.0,
      this.enableLimit: false,
      PhysicsJointBreakCallback breakCallback,
      double breakingForce,
      bool enableMotor: false,
      double motorSpeed: 0.0,
      double maxMotorTorque: 0.0
    }) : super(bodyA, bodyB, breakingForce, breakCallback) {
    _enableMotor = enableMotor;
    _motorSpeed = motorSpeed;
    _maxMotorTorque = maxMotorTorque;
    _completeCreation();
  }

  final Point _worldAnchor;
  final double lowerAngle;
  final double upperAngle;
  final bool enableLimit;

  bool _enableMotor;

  bool get enableMotor => _enableMotor;

  set enableMotor(bool enableMotor) {
    _enableMotor = enableMotor;
    if (_joint != null) {
      box2d.RevoluteJoint revoluteJoint = _joint;
      revoluteJoint.enableMotor(enableMotor);
    }
  }

  double _motorSpeed;

  double get motorSpeed => _motorSpeed;

  set motorSpeed(double motorSpeed) {
    _motorSpeed = motorSpeed;
    if (_joint != null) {
      box2d.RevoluteJoint revoluteJoint = _joint;
      revoluteJoint.setMotorSpeed(radians(motorSpeed));
    }
  }

  double _maxMotorTorque;

  double get maxMotorTorque => _maxMotorTorque;

  set maxMotorTorque(double maxMotorTorque) {
    _maxMotorTorque = maxMotorTorque;
    if (_joint != null) {
      box2d.RevoluteJoint revoluteJoint = _joint;
      revoluteJoint.setMaxMotorTorque(maxMotorTorque);
    }
  }

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode) {
    // Create Joint Definition
    Vector2 vecAnchor = new Vector2(
      _worldAnchor.x / physicsNode.b2WorldToNodeConversionFactor,
      _worldAnchor.y / physicsNode.b2WorldToNodeConversionFactor
    );

    box2d.RevoluteJointDef b2Def = new box2d.RevoluteJointDef();
    b2Def.initialize(bodyA._body, bodyB._body, vecAnchor);
    b2Def.enableLimit = enableLimit;
    b2Def.lowerAngle = lowerAngle;
    b2Def.upperAngle = upperAngle;

    b2Def.enableMotor = _enableMotor;
    b2Def.motorSpeed = _motorSpeed;
    b2Def.maxMotorTorque = _maxMotorTorque;

    // Create joint
    return physicsNode.b2World.createJoint(b2Def);
  }
}

class PhysicsJointPrismatic extends PhysicsJoint {
  PhysicsJointPrismatic(
    PhysicsBody bodyA,
    PhysicsBody bodyB,
    this.axis, {
      double breakingForce,
      PhysicsJointBreakCallback breakCallback,
      bool enableMotor: false,
      double motorSpeed: 0.0,
      double maxMotorForce: 0.0
    }
  ) : super(bodyA, bodyB, breakingForce, breakCallback) {
    _enableMotor = enableMotor;
    _motorSpeed = motorSpeed;
    _maxMotorForce = maxMotorForce;
    _completeCreation();
  }

  final Offset axis;

  bool _enableMotor;

  bool get enableMotor => _enableMotor;

  set enableMotor(bool enableMotor) {
    _enableMotor = enableMotor;
    if (_joint != null) {
      box2d.PrismaticJoint prismaticJoint = _joint;
      prismaticJoint.enableMotor(enableMotor);
    }
  }

  double _motorSpeed;

  double get motorSpeed => _motorSpeed;

  set motorSpeed(double motorSpeed) {
    _motorSpeed = motorSpeed;
    if (_joint != null) {
      box2d.PrismaticJoint prismaticJoint = _joint;
      prismaticJoint.setMotorSpeed(motorSpeed / _physicsNode.b2WorldToNodeConversionFactor);
    }
  }

  double _maxMotorForce;

  double get maxMotorForce => _maxMotorForce;

  set maxMotorForce(double maxMotorForce) {
    _maxMotorForce = maxMotorForce;
    if (_joint != null) {
      box2d.PrismaticJoint prismaticJoint = _joint;
      prismaticJoint.setMaxMotorForce(maxMotorForce / _physicsNode.b2WorldToNodeConversionFactor);
    }
  }

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode) {
    box2d.PrismaticJointDef b2Def = new box2d.PrismaticJointDef();
    b2Def.initialize(bodyA._body, bodyB._body, bodyA._body.position, new Vector2(axis.dx, axis.dy));
    b2Def.enableMotor = _enableMotor;
    b2Def.motorSpeed = _motorSpeed;
    b2Def.maxMotorForce = _maxMotorForce;

    return physicsNode.b2World.createJoint(b2Def);
  }
}

class PhysicsJointWeld extends PhysicsJoint {
  PhysicsJointWeld(
    PhysicsBody bodyA,
    PhysicsBody bodyB, {
      double breakingForce,
      PhysicsJointBreakCallback breakCallback,
      this.dampening: 0.0,
      this.frequency: 0.0
    }
  ) : super(bodyA, bodyB, breakingForce, breakCallback) {
    _completeCreation();
  }

  final double dampening;
  final double frequency;

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode) {
    box2d.WeldJointDef b2Def = new box2d.WeldJointDef();
    Vector2 middle = new Vector2(
      (bodyA._body.position.x + bodyB._body.position.x) / 2.0,
      (bodyA._body.position.y + bodyB._body.position.y) / 2.0
    );
    b2Def.initialize(bodyA._body, bodyB._body, middle);
    b2Def.dampingRatio = dampening;
    b2Def.frequencyHz = frequency;
    return physicsNode.b2World.createJoint(b2Def);
  }
}

class PhysicsJointPulley extends PhysicsJoint {
  PhysicsJointPulley(
    PhysicsBody bodyA,
    PhysicsBody bodyB,
    this.groundAnchorA,
    this.groundAnchorB,
    this.anchorA,
    this.anchorB,
    this.ratio, {
      double breakingForce,
      PhysicsJointBreakCallback breakCallback
    }
  ) : super(bodyA, bodyB, breakingForce, breakCallback) {
    _completeCreation();
  }

  final Point groundAnchorA;
  final Point groundAnchorB;
  final Point anchorA;
  final Point anchorB;
  final double ratio;

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode) {
    box2d.PulleyJointDef b2Def = new box2d.PulleyJointDef();
    b2Def.initialize(
      bodyA._body,
      bodyB._body,
      _convertPosToVec(groundAnchorA, physicsNode),
      _convertPosToVec(groundAnchorB, physicsNode),
      _convertPosToVec(anchorA, physicsNode),
      _convertPosToVec(anchorB, physicsNode),
      ratio
    );
    return physicsNode.b2World.createJoint(b2Def);
  }
}

class PhysicsJointGear extends PhysicsJoint {
  PhysicsJointGear(
    PhysicsBody bodyA,
    PhysicsBody bodyB, {
      double breakingForce,
      PhysicsJointBreakCallback breakCallback,
      this.ratio: 0.0
    }
  ) : super(bodyA, bodyB, breakingForce, breakCallback) {
    _completeCreation();
  }

  final double ratio;

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode) {
    box2d.GearJointDef b2Def = new box2d.GearJointDef();
    b2Def.bodyA = bodyA._body;
    b2Def.bodyB = bodyB._body;
    b2Def.ratio = ratio;

    return physicsNode.b2World.createJoint(b2Def);
  }
}

class PhysicsJointDistance extends PhysicsJoint {
  PhysicsJointDistance(
    PhysicsBody bodyA,
    PhysicsBody bodyB,
    this.anchorA,
    this.anchorB, {
      double breakingForce,
      PhysicsJointBreakCallback breakCallback,
      this.length,
      this.dampening: 0.0,
      this.frequency: 0.0
    }
  ) : super(bodyA, bodyB, breakingForce, breakCallback) {
    _completeCreation();
  }

  final Point anchorA;
  final Point anchorB;
  final double length;
  final double dampening;
  final double frequency;

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode) {
    box2d.DistanceJointDef b2Def = new box2d.DistanceJointDef();
    b2Def.initialize(
      bodyA._body,
      bodyB._body,
      _convertPosToVec(anchorA, physicsNode),
      _convertPosToVec(anchorB, physicsNode)
    );
    b2Def.dampingRatio = dampening;
    b2Def.frequencyHz = frequency;
    if (length != null)
      b2Def.length = length / physicsNode.b2WorldToNodeConversionFactor;

    return physicsNode.b2World.createJoint(b2Def);
  }
}

class PhysicsJointWheel extends PhysicsJoint {
  PhysicsJointWheel(
    PhysicsBody bodyA,
    PhysicsBody bodyB,
    this.anchor,
    this.axis, {
      double breakingForce,
      PhysicsJointBreakCallback breakCallback,
      this.dampening: 0.0,
      this.frequency: 0.0
    }
  ) : super(bodyA, bodyB, breakingForce, breakCallback) {
    _completeCreation();
  }

  final Point anchor;
  final Offset axis;
  final double dampening;
  final double frequency;

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode) {
    box2d.WheelJointDef b2Def = new box2d.WheelJointDef();
    b2Def.initialize(
      bodyA._body,
      bodyB._body,
      _convertPosToVec(anchor, physicsNode),
      new Vector2(axis.dx, axis.dy)
    );
    b2Def.dampingRatio = dampening;
    b2Def.frequencyHz = frequency;

    return physicsNode.b2World.createJoint(b2Def);
  }
}

class PhysicsJointFriction extends PhysicsJoint {
  PhysicsJointFriction(
    PhysicsBody bodyA,
    PhysicsBody bodyB,
    this.anchor, {
      double breakingForce,
      PhysicsJointBreakCallback breakCallback,
      this.maxForce: 0.0,
      this.maxTorque: 0.0
    }
  ) : super(bodyA, bodyB, breakingForce, breakCallback) {
    _completeCreation();
  }

  final Point anchor;
  final double maxForce;
  final double maxTorque;

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode) {
    box2d.FrictionJointDef b2Def = new box2d.FrictionJointDef();
    b2Def.initialize(
      bodyA._body,
      bodyB._body,
      _convertPosToVec(anchor, physicsNode)
    );
    b2Def.maxForce = maxForce / physicsNode.b2WorldToNodeConversionFactor;
    b2Def.maxTorque = maxTorque / physicsNode.b2WorldToNodeConversionFactor;
    return physicsNode.b2World.createJoint(b2Def);
  }
}

class PhysicsJointConstantVolume extends PhysicsJoint {
  PhysicsJointConstantVolume(
    this.bodies, {
      double breakingForce,
      PhysicsJointBreakCallback breakCallback,
      this.dampening,
      this.frequency
    }
  ) : super(null, null, breakingForce, breakCallback) {
    assert(bodies.length > 2);
    _bodyA = bodies[0];
    _bodyB = bodies[1];
    _completeCreation();
  }

  final List<PhysicsBody> bodies;
  final double dampening;
  final double frequency;

  box2d.Joint _createB2Joint(PhysicsWorld physicsNode) {
    box2d.ConstantVolumeJointDef b2Def = new box2d.ConstantVolumeJointDef();
    for (PhysicsBody body in bodies) {
      b2Def.addBody(body._body);
    }
    b2Def.dampingRatio = dampening;
    b2Def.frequencyHz = frequency;
    return physicsNode.b2World.createJoint(b2Def);
  }
}

Vector2 _convertPosToVec(Point pt, PhysicsWorld physicsNode) {
  return new Vector2(
    pt.x / physicsNode.b2WorldToNodeConversionFactor,
    pt.y / physicsNode.b2WorldToNodeConversionFactor
  );
}
