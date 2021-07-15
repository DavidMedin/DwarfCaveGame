vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	float id = Texel(tex,texture_coords).x;
	if(id == 0){
		return vec4(0,0,0,1);
	}else{
		return vec4(1,1,1,1);
	}
}
