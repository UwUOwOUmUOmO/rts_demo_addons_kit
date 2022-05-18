extends CombatSensor

class_name AirSensor

const PROJECTILE_CROSS_SECTION = 1.7

signal __vehicle_detected(vehicle)
signal __lock_on_detected(direction)
signal __inbound_projectile(projectile)
