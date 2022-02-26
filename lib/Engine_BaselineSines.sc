
Engine_BaselineSines : CroneEngine {
	var <g, <b, <lim_s;
	alloc {
        var s = Server.default;
        g = Group.new(Server.default);
        b = Bus.audio(s, 2);
        
        lim_s = {
            Out.ar(0, Limiter.ar(In.ar(b.index, 2)))
        }.play(target:g, addAction:\addAfter);

		this.addCommand("newsine", "fff", { arg msg;
            var amp = msg[1];
            var hz = msg[2];
            var pan = msg[3];
            {
                var mul = AmpComp.ir(hz) * amp;
                Out.ar(b.index, Pan2.ar(SinOsc.ar(hz)*mul, pan))
            }.play(target:g, addAction:\addToTail);
		});

		this.addCommand("clear", "", { arg msg;
			g.deepFree;
		});
	}
	free {
		g.free;
        lim_s.free;
        b.free;
	}
}
