class GraphicalElement {
	
	static isElem := 1
	
	__New( pos, rot := 0 ) {
		This.pic := GameControl.display.addPicture( This.picFile, [ 1, 1, This.picLevel ], This.picSize )
		This.setPos( pos )
		This.setRot( rot )
		This.pic.setVisible()
		GameControl.elements[ &This ] := This
		GameControl.elementsClass[ this.__Class, &this ] := this
		This.onSpawn()
	}
	
	__Delete() {
		This.despawn()
	}
	
	despawn() {
		if This.despawned
			return
		This.despawned := true
		This.onDespawn()
		GameControl.elements.delete( &this )
		if ( GameControl.movingElements.hasKey( &This ) )
			GameControl.movingElements.delete( &This )
		GameControl.elementsClass[ this.__Class ].delete( &this )
		This.pic.setVisible( false )
		This.pic := ""
		This.base := ""
	}
	
	setPos( pos ) {
		this.pos := pos
		this.pos.base := vector2d
		picPos := this.pos.clone()
		picPos.Push( this.picLevel )
		this.pic.setPosition( picPos )
	}
	
	setRot( rot ) {
		static pi4 := atan( 1 )
		this.rot := trueMod( rot, pi4 * 8 )
		this.pic.setRotation( [ -rot * 45 / pi4, 0, 0 ] )
	}
	
	setVelocity( vel ) {
		this.vel := vel
		this.vel.base := Vector2d
		if !GameControl.movingElements.hasKey( &this )
			GameControl.movingElements[ &this ] := this
	}
	
	getInfo() {
		return new GraphicalElement.ElementInfo( This )
	}
	
	class ElementInfo {
		
		static isRef := 1
		
		__New( Obj ) {
			This.ptr := &Obj
		}
		
		equals( objOrRef ) {
			if ( objOrRef.hasKey( "ptr" ) )
				return objOrRef.ptr == this.ptr
			return &objOrRef == This.ptr
		}
		
		getType() {
			return resolveRef( This ).__Class
		}
		
	}
	
}