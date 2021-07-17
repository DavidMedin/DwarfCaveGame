vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	float id = Texel(tex,texture_coords).x;
	if(id*255==1){
		//air
		return vec4(1,1,1,1);
	}else if(id*255==2){
		//gold
		return vec4(1,1,0,1);
	}else if(id*255==3){
		//stone
		return vec4(0,0,0,1);
	}else{
		//something is wrong
		return vec4(1,0,1,1);
	}
}
