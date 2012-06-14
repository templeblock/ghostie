#version 330

//smooth in vec4 theColor;
layout(location = 0) out vec4 color;
//out vec4 color;

void main()
{
	float fog_end	=	120;
	float fog_start	=	72;
	float fog_dist	=	fog_end - fog_start;
	float fog_amt;
	float fog_coord;
	
	fog_coord	=	abs(gl_FragCoord.z / gl_FragCoord.w) - fog_start;
	fog_coord	=	clamp(fog_coord, 0.0, fog_dist);

	fog_amt		=	(fog_dist - fog_coord) / fog_dist;
	fog_amt		=	clamp(fog_amt, 0.0, 1.0);

	color	=	mix(
		vec4(1.0f, 1.0f, 1.0f, 1.0f),
		//vec4(0.33f, 0.28f, 0.25f, 1.0f),
		vec4(0, 0, 0, 1.0f),
		// 0 == all fog, 1 == all color
		fog_amt
	);
}
