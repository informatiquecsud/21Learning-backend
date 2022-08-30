from pyodide import create_proxy
from js import document

iframe = document.querySelector('iframe.robotsim-container')
sim = iframe.contentWindow.sim
robot = sim.robots[0]

def zone(callback):
    return create_proxy(callback)

class SimulatedWorld:

    def __init__(self):
        pass

    def reset(self):
        robot.setPosition(0, 0)
        robot.setAngle(0)



