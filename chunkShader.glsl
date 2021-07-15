//#extention GL_ARB_arrays_of_arrays : enable
uniform float chunks[5*5*100*100];

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	float id = chunks[floor(screen_coords.x/100)][floor(screen_coords.y/100)][screen_coords.x%100][screen_coords.y%100];
	if(id == 0){
		return vec4(0,0,0,1);
	}else{
		return vec4(1,0,0,1);
	}
}
