class Ant extends GraphicalElement {
	static picFile := "res\ant.png", picLevel := 3, picSize := new Vector2d( 0.0125, 0.03 ), collisionSize := 0.03
	
	static viewDist := 0.1
	static maxVel := 0.1
	static maxVelHolding := 0.025
	static maxRot := 4
	static maxRotHolding := 1
	static energyRot     := 1
	static energyWalk    := 1
	static energyIdle    := 1
	static energyHolding := 1
	state := 0 ;a bitmask
	timeLastStateChange := getTime()
	propertyValues := []
	propertyKeys   := []
	energy := 100
	sees   := []
	touches:= []
	messages := []
	visited:= true
	hungry := false
	
	onSpawn() {
		This.sees[ &this ] := 1
		This.touches[ &this ] := 1
	}
	
	onDespawn() {
		This.antHill.ants--
		This.holding.droppedBy( This )
		This.holding := ""
		This.antHill := ""
	}
	
	executeLogic() {
		;check for turn
		This.handleMessages()
		if ( This.state & 2 ) {
			maxRot := ( This.holding ? This.maxRotHolding : This.maxRot ) * GameControl.dT
			if ( ( This.targetDegrees > -1 && abs( This.rot - ( nRot := This.targetDegrees ) ) < maxRot ) || ( isObject( This.targetDegrees ) && abs( This.rot - ( nRot := This.targetDegrees.pos.sub( This.pos ).getRot() ) ) < maxRot ) ) {
				This.setRot( nRot )
				This.getControl().stopTurn()
			}
			else {
				This.setRot( This.rot + ( ( This.state & 4 ) ? -maxRot : maxRot ) )
				This.energy -= This.energyRot * GameControl.dT
			}
		}
		if ( This.state & 1 ) {
			This.energy -= This.energyWalk * GameControl.dT
			vel := This.holding ? This.maxVelHolding : This.maxVel
			This.setVelocity( [ sin( This.rot ) * vel, cos( This.rot ) * vel ] )
		} else {
			This.setVelocity( [ 0, 0 ] )
			if ( !This.state )
				This.triggerCallBack( "Idle" )
		}
		This.energy -= This.energyIdle * GameControl.dT
		saw := this.sees.clone()
		touched := this.touches.clone()
		newSee := []
		newTouch := []
		for each, className in [ "Ant", "AntHill", "SugarHeap", "SugarPiece" ] {
			for each, element in GameControl.elementsClass[ className ]
			{
				inview := false
				if ( ( dist := element.pos.sub( this.pos ) ).magnitude()  < ( This.viewDist + element.picSize.magnitude() ) / 2 ) {
					if ( !saw.hasKey( &element ) ) {
						this.sees[ &element ] := 1
						newSee.push( element )
					} else 
						saw.delete( &element )
					if ( dist.div( element.picSize.div( 2 ) ).magnitude() <= 1 ) {
						if (  !touched.hasKey( &element ) ) {
							this.touches[ &element ] := 1
							newTouch.push( element )
						}
						else
							touched.delete( &element )
					}
				}
			}
		}
		for elementPtr, void in saw
			This.sees.delete( elementPtr )
		for elementPtr, void in touched
			This.touches.delete( elementPtr )
		for each, element in newSee{
			This.triggerCallBack( "See" . This.getName( element ), element.getInfo() )
		}
		for each, element in newTouch {
			This.triggerCallBack( "Arrive" . This.getName( element ), element.getInfo() )
		}
		if ( This.holding ) {
			This.holding.setPos( This.pos.add( [ This.picSize.2 / 2 * sin( This.rot ), This.picSize.2 / 2 * cos( This.rot ) ] ) )
			This.holding.setVelocity( This.vel )
			This.holding.setRot( This.rot )
			This.energy -= This.energyHolding * GameControl.dT
		}
		if ( GameControl.frameTime - This.timeLastStateChange > 5 )
			This.triggerCallBack( "Bored" )
		if ( This.touches.hasKey( &( This.antHill ) ) )
		{
			if ( !This.visited ) {
				This.hungry := false
				This.visited := true
			}
			This.energy := 100
		}
		else
			This.visited := false
		if ( This.energy < 33.333 && !This.hungry )
		{
			This.triggerCallBack( "Hungry" )
			This.hungry := true
		}
		if ( This.energy < 0 )
			This.despawn()
		This.triggerCallBack( "Tick" )
	}
	
	getName( element ) {
		if ( element == this.antHill )
			return "Home"
		if ( element.__Class == "Ant" ) {
			if ( element.antHill == This.antHill )
				return "AlliedAnt"
			else
				return "ForeignAnt"
		}
		return element.__Class
	}
	
	addState( bitMask ) {
		This.state := This.state | bitMask
		This.timeLastStateChange := GameControl.frameTime
	}
	
	removeState( bitMask ) {
		This.state := This.state & ( bitMask ^ 0xFF )
		This.timeLastStateChange := GameControl.frameTime
	}
	
	triggerCallBack( name, p* ) {
		if This.hasKey( "antHill" )
			try This.antHill.controller.antControl["on" . name ].call( This.getControl(), p* )
		catch e
			This.antHill.notifyDeadController()
	}
	
	getControl() {
		return new This.AntMoveControl( This )
	}
	
	getInfo() {
		return new This.AntInfo( This )
	}
	
	drop() {
		held := This.holding
		held.setVelocity( [0, 0] )
		held.droppedBy( This )
		This.holding := ""
		if This.touches.hasKey( &(This.antHill) )
			This.antHill.notifyDrop( held )
	}
	
	addMessage( Name, p* ) {
		This.messages.push( [Name, p] )
	}
	
	handleMessages() {
		for each, message in This.messages
			This[ message.1 ].Call( This, ( message.2 )* )
		This.messages := []
	}
	
	class AntInfo extends GraphicalElement.ElementInfo {
		
		getEnergy() {
			return resolveRef( This ).energy
		}
		
		getTurning() {
			nAnt := resolveRef( This )
			if ( nAnt.state & 2 )
				return nAnt.state & 4 ? "R" : "L"
		}
		
		getWalk() {
			return resolveRef( This ) & 1
		}
		
		getProperty( name ) {
			nAnt := resolveRef( This )
			for each, propertyName in nAnt.propertyKeys
				if ( propertyName = name )
					return nAnt.propertyValues[ each ]
		}
		
		canSee( elementNameOrReference ) {
			nAnt := resolveRef( This )
			if ( elementNameOrReference.isRef )
				elementNameOrReference := resolveRef( elementNameOrReference )
			if ( elementNameOrReference.isElem )
				return nAnt.sees[ &elementNameOrReference ]
			if ( !IsObject( elementNameOrReference ) && elementNameOrReference ~= "^[a-zA-Z]+$" )
				for elemPtr in nAnt.sees {
					if ( ( name := nAnt.getName( resolvePtr( elemPtr ) ) ) = elementNameOrReference )
						return 1
				}
			return 0
		}
		
		getHolding() {
			nAnt := resolveRef( This )
			if nAnt.holding
				return nAnt.holding.getInfo()
		}
		
		isHome() {
			nAnt := resolveRef( This )
			return nAnt.touches.hasKey( &( nAnt.antHill ) )
		}
		
	}
	
	class AntMoveControl extends Ant.AntInfo {
		
		
		walk() {
			resolveRef( This ).addState( 1 )
		}
		
		stop() {
			resolveRef( This ).removeState( 1 )
		}
		
		turnL() {
			nAnt := resolveRef( This )
			nAnt.addState( 2 )
			nAnt.removeState( 4 )
			nAnt.targetDegrees := ""
		}
		
		turnLBy( degrees ) {
			degrees := deg2rad( degrees )
			nAnt := resolveRef( This )
			This.turnL()
			nAnt.targetDegrees := trueMod( nAnt.rot + degrees, atan( 1 ) * 8 )
		}
		
		turnR() {
			nAnt := resolveRef( This )
			nAnt.addState( 6 )
			nAnt.targetDegrees := ""
		}
		
		turnRBy( degrees ) {
			degrees := deg2rad( degrees )
			nAnt := resolveRef( This )
			This.turnR()
			nAnt.targetDegrees := trueMod( nAnt.rot - degrees , atan( 1 ) * 8 )
		}
		
		turnTo( reference ) {
			if reference.isRef
				reference := resolveRef( reference )
			if ( !reference.isElem )
				return "invalid input"
			nAnt  := resolveRef( This )
			if !( nAnt.sees.hasKey( &reference ) || nAnt.antHill == reference )
				return "Ant can't see input and input is not home"
			nRot := reference.pos.sub( nAnt.pos ).getRot()
			if ( trueMod( nAnt.rot - nRot, 8*atan( 1 ) ) > 4 * atan( 1 ) )
				This.turnL()
			else
				This.turnR()
			nAnt.targetDegrees := reference
		}
		
		turnToHill() {
			This.turnTo( resolveRef( This ).antHill )
		}
		
		stopTurn() {
			nAnt := resolveRef( This )
			nAnt.removeState( 6 )
			nAnt.targetDegrees := ""
		}
		
		stopEverything() {
			resolveRef( This ).removeState( 0xFF )
			This.drop()
		}
		
		pickup( reference ) {
			if reference.isRef
				reference := resolveRef( reference )
			if ( !reference.isElem )
				return "invlid Input"
			if ( !reference.canPickup )
				return "can't pickup input"
			nAnt := resolveRef( This )
			if !( nAnt.touches.hasKey( &reference ) )
				return "Ant can't pickup anything it doesn't touch"
			nAnt := resolveRef( This )
			nAnt.holding := reference.pickedUpBy( nAnt )
			nAnt.toches[ &( nAnt.holding ) ] := 1
			nAnt.sees[ &( nAnt.holding ) ] := 1
		}
		
		drop() {
			nAnt := resolveRef( This )
			if !held := nAnt.holding
				return "Ant can't drop nothing"
			nAnt.addMessage( "drop" )
		}
		
		setProperty( name, value ) {
			nAnt := resolveRef( This )
			for each, propertyName in nAnt.propertyKeys
				if ( propertyName = name )
					return nAnt.propertyValues[ each ] := value
			nAnt.propertyValues.Push( value )
			nAnt.propertyKeys.Push( name )
			return value
		}
		
	}
	
}