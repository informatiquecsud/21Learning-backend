from mbrobot2 import *

cmds = [
    [forward],
    [backward],
    [stop],
    [right],
    [left],
    [rightArc, 0.2],
    [leftArc, 0.2],
    [stop],
    [rotateMotor, M_LEFT, 60],
    [rotateMotor, M_LEFT, -60],
    [stop],
    [rotateMotor, M_RIGHT, 60],
    [rotateMotor, M_RIGHT, -60],
    [stop],
]

cmds = cmds[-3:]

for cmd in cmds:
    print("running", cmd)
    f, *args = cmd
    f(*args)
    delay(1000)
    stop()
    delay(500)


