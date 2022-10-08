extends MaunalSnapShot

class_name AutoSnapShot

const SERIALIZABLE_SIGNALS := {
	"changed": "auto_snap",
}

var frequency := 10 setget set_freq
var count := 10
var freq_mutex := Mutex.new()

func _init():
	resize(1)

func set_host(h: Serializable):
	if is_instance_valid(host):
		Utilities.SignalTools.disconnect_from(host, self, SERIALIZABLE_SIGNALS, false)
	host = h
	Utilities.SignalTools.connect_from(host, self, SERIALIZABLE_SIGNALS, false)

func auto_snap():
	freq_mutex.lock()
	count -= 1
	if count <= 0:
		snap()
		count = limit
	freq_mutex.unlock()

func set_freq(f: int):
	freq_mutex.lock()
	count = (frequency - count) + f
	frequency = f
	freq_mutex.unlock()
