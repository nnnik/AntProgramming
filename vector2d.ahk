class vector2d
{
	
	__New( values* )
	{
		This.1 := values.1
		This.2 := values.2
	}
	
	add( vector )
	{
		return new vector2d( this.1 + vector.1, this.2 + vector.2 )
	}
	
	sub( vector )
	{
		return new vector2d( this.1 - vector.1, this.2 - vector.2 )
	}
	
	mul( vector )
	{
		if isObject( vector )
			return new vector2d( this.1 * vector.1, this.2 * vector.2 )
		else
			return new vector2d( this.1 * vector, this.2 * vector )
	}
	
	div( vector )
	{
		if isObject( vector )
			return new vector2d( this.1 / vector.1, this.2 / vector.2 )
		else
			return new vector2d( this.1 / vector, this.2 / vector )
	}
	
	magnitude()
	{
		return ((this.1**2)+(this.2**2)) ** 0.5
	}
	
	abs()
	{
		return new vector2d( abs( this.1 ), abs( this.2 ) )
	}
	
	lequal( vector )
	{
		return ( this.1 <= vector.1 ) && ( this.2 <= vector.2 )
	}
	
	dotP( vector ) {
		return this.1 * vector.1 + this.2 * vector.2
	}
	
	rotate( degrees ) {
		return new Vector2d( this.1 * cos( degrees ) + this.2 * sin( degrees ), this.2 * cos( degrees ) - this.1 * sin( degrees ) )
	}
	
	getRot() {
		if ( This.1 < 0 )
			return 8*atan( 1 ) -acos( This.2 / This.magnitude() )
		else
			return acos( This.2 / This.magnitude() )
	}
	
}