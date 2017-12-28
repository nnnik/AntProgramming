class AntHill extends GraphicalElement {
	static picFile := "res\anthill.png", picLevel := 2, picSize := new Vector2d( 0.1, 0.1 )
	
	static spawnRate := 1
	static maxAnts   := 25
	currentAnts := 5
	timeSinceLastSpawn := getTime() - 10
	ants := 0
	
	setController( controller ) {
		This.controller := controller
	}
	
	notifyDeadController() {
		Try This.controller.ping()
		catch e {
			GameControl.shutDown()
		}
	}
	
	notifyDrop( obj ) {
		if ( obj.isFood ) {
			obj.despawn()
			if ( This.currentAnts < This.maxAnts )
				This.currentAnts++
		}
	}
	
	executeLogic() {
		if ( GameControl.frameTime - this.timeSinceLastSpawn > This.spawnRate && This.ants < This.currentAnts )
		{
			Random, deg, 0, 359
			deg := deg / 45 * atan(1)
			sinVal := sin( deg ) * ( ( this.picSize.2 + Ant.picSize.2 ) / 2 ), cosVal := cos( deg ) * ( ( this.picSize.1  + Ant.picSize.2 ) / 2 )
			newAnt := new Ant( [ this.pos.1 + sinVal, this.pos.2 + cosVal ], deg )
			newAnt.antHill := This
			newAnt.sees[ &This ] := 1
			newAnt.touches[ &This ] := 1
			This.ants++
			this.timeSinceLastSpawn := GameControl.frameTime
		}
	}
	
}