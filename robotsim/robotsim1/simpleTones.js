var AudioContext=window.AudioContext||window.webkitAudioContext,context=new AudioContext,o=null,g=null,soundObj={bump:["triangle",100,.8,333,.2,100,.4,80,.7],buzzer:["sawtooth",40,.8,100,.3,110,.5],zip:["sawtooth",75,.8,85,.2,95,.4,110,.6,120,.7,100,.8],powerdown:["sine",300,1.2,150,.5,1,.9],powerup:["sine",30,1,150,.4,350,.9],bounce:["square",75,.5,150,.4],siren:["sawtooth",900,2.5,400,.5,900,1,400,1.4,900,2,400,2.5],loop:["sine",340,2.5,550,.8,440,1.4],falling:["sine",750,5.2,700,1,600,2,500,3,400,4,300,4.5,200,5]},tone={C0:16.35,"C#0":17.32,D0:18.35,"D#0":19.45,E0:20.6,F0:21.83,"F#0":23.12,Gb0:23.12,G0:24.5,"G#0":25.96,A0:27.5,"A#0":29.14,B0:30.87,C1:32.7,"C#1":34.65,D1:36.71,"D#1":38.89,E1:41.2,F1:43.65,"F#1":46.25,G1:49,"G#1":51.91,A1:55,"A#1":58.27,B1:61.74,C2:65.41,"C#2":69.3,D2:73.42,"D#2":77.78,E2:82.41,F2:87.31,"F#2":92.5,G2:98,"G#2":103.83,A2:110,"A#2":116.54,B2:123.47,C3:130.81,"C#3":138.59,D3:146.83,"D#3":155.56,E3:164.81,F3:174.61,"F#3":185,G3:196,"G#3":207.65,A3:220,"A#3":233.08,B3:246.94,C4:261.63,"C#4":277.18,D4:293.66,"D#4":311.13,E4:329.63,F4:349.23,"F#4":369.99,G4:392,"G#4":415.3,A4:440,"A#4":466.16,B4:493.88,C5:523.25,"C#5":554.37,D5:587.33,"D#5":622.25,E5:659.26,F5:698.46,"F#5":739.99,G5:783.99,"G#5":830.61,A5:880,"A#5":932.33,B5:987.77,C6:1046.5,"C#6":1108.73,D6:1174.66,"D#6":1244.51,E6:1318.51,F6:1396.91,"F#6":1479.98,G6:1567.98,"G#6":1661.22,A6:1760,"A#6":1864.66,B6:1975.53,C7:2093,"C#7":2217.46,D7:2349.32,"D#7":2489.02,E7:2637.02,F7:2793.83,"F#7":2959.96,G7:3135.96,"G#7":3322.44,A7:3520,"A#7":3729.31,B7:3951.07,C8:4186.01,"C#8":4435,D8:4699,"D#8":4978,E8:5274,F8:5588,"F#8":5920,G8:6272,"G#8":6645,A8:7040,"A#8":7459,B8:7902},chord={C:[261.6,329.6,392],Cm:[261.6,311.1,392],"C#":[277.2,349.2,415.3],D:[293.7,370,440],Dm:[293.7,349.2,440],"D#":[311.1,392,466.2],E:[329.6,415.3,493.9],Em:[329.6,392,493.9],F:[349.2,440,523.251],Fm:[349.2,415.3,523.251],"F#":[370,554.365,466.2],G:[392,493.9,587.33],Gm:[392,466.2,587.33],"G#":[466.2,523.251,622.254],A:[440,554.365,659.255],Am:[440,523.251,659.255],"A#":[466.2,587.33,698.456],B:[493.9,622.254,739.989],Bm:[493.9,587.33,739.989]},isFlatTone=e=>/\wb\d/.test(e);function downFlatTone(e){var t={Ab:"G#",Bb:"A#",Cb:"B",D:"C#",E:"D#",F:"E",G:"F#"};return toneKey=e.replace(/\d/,""),toneOctave=e.replace(/\D/g,""),t[toneKey]+("Cb"===toneKey?Number(toneOctave)-1:toneOctave)}const VOLUME_CURVE=[1,.61,.37,.22,.14,.08,.05,0];function playSound(e,t,o){if(soundObj[arguments[0]]&&1===arguments.length){var n=arguments[0];playSound(...soundObj[n])}else{var c=context.createOscillator(),r=context.createGain();c.type=e,c.frequency.setValueAtTime(t,context.currentTime);for(var a=3;a<arguments.length;a+=2)c.frequency.exponentialRampToValueAtTime(arguments[a],context.currentTime+arguments[a+1]);r.gain.setValueAtTime(.3,context.currentTime),r.gain.setValueCurveAtTime(VOLUME_CURVE,context.currentTime,2),c.connect(r),r.connect(context.destination),c.start(),c.stop(context.currentTime+o)}}playTone=(e,t,n)=>{void 0===t&&(t="sine"),void 0===n&&(n=1.3),void 0===e&&(e=440),o=context.createOscillator(),g=context.createGain(),o.connect(g),o.type=t,"string"===typeof e?chord[e]?(o.frequency.value=chord[e][0],completeChord(chord[e][1],t,n),completeChord(chord[e][2],t,n)):isFlatTone(e)?o.frequency.value=tone[downFlatTone(e)]:tone[e]&&(o.frequency.value=tone[e]):"object"===typeof e?(o.frequency.value=e[0],completeChord(e[1],t,n),completeChord(e[2],t,n)):o.frequency.value=e,g.connect(context.destination),o.start(0),g.gain.setValueCurveAtTime(VOLUME_CURVE,context.currentTime,n)},completeChord=(e,t,o)=>{osc=context.createOscillator(),gn=context.createGain(),osc.connect(gn),osc.type=t,osc.frequency.value=e,gn.connect(context.destination),osc.start(0),gn.gain.setValueCurveAtTime(VOLUME_CURVE,context.currentTime,o)};