from worlds import *

class SimpleTrail(SimulatedWorld):

    def __init__(self, simulation=None):
        self.points = 0


        self.sim = simulation or sim
        self.sim.picture("trail", 390, -120, 0, 0.5, 0.5)
        self.sim.zoneCircle(200, 200, 30, )

        self.reset()

    @zone
    def onCirceZone()

world = SimpleTrail()
