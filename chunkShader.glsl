uniform Image gold;
uniform vec2 offset;
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	float id = Texel(tex,texture_coords).x;
	if(id*255==1){
		//air
		return vec4(1,1,1,1);
	}else if(id*255==2){
		//gold
		return Texel(gold,vec2(mod(screen_coords.x+offset.x,40)/40,mod(screen_coords.y+offset.y,40)/40));
	}else if(id*255==3){
		//stone
		return vec4(0,0,0,1);
	}else{
		//something is wrong
		return vec4(1,0,1,1);
	}
}
