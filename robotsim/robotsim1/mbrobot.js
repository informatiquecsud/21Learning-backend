function w(t,i,o,n){sim.robots[0].i2c.write(16,[0,t,o]),sim.robots[0].i2c.write(16,[2,i,n])}function setSpeed(t){_v=t<20?t+5:t}function forward(){w(1,1,_v,_v)}function backward(){w(2,2,_v,_v)}function stop(){w(0,0,0,0)}function right(){let t=2,i=1;_v>0&&(t=1,i=2),w(t,i,Math.round(.9*_v),Math.round(.9*_v))}function left(){let t=1,i=2;_v>0&&(t=2,i=1),w(t,i,Math.round(.9*_v),Math.round(.9*_v))}function rightArc(t){let i,o;v=Math.abs(_v),t<_axe?i=0:(o=(t-_axe)/(t+_axe)*(1-v*v/2e4),i=Math.round(o*v)),_v>0?w(1,1,v,i):w(2,2,i,v)}function leftArc(t){let i,o;v=Math.abs(_v),t<_axe?i=0:(o=(t-_axe)/(t+_axe)*(1-v*v/2e4),i=Math.round(o*v)),_v>0?w(1,1,i,v):w(2,2,v,i)}function getDistance(){return sim.robots[0].getDistance()}function setLED(t){sim.robots[0].pin8.write_digital(t),sim.robots[0].pin12.write_digital(t)}function setMbrobot(){_v=50,irLeft=sim.robots[0].pin13,irRight=sim.robots[0].pin14,ledLeft=sim.robots[0].pin8,ledRight=sim.robots[0].pin12}_axe=.097;