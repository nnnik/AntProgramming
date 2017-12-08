#Include displayOut.ahk
#NoEnv
SetBatchLines, -1

;--------- Testing ---------
AntServer.addAntHill( testController )
AntServer.startUp()

class testController {
	
	class antControl {
		onIdle() {
			this.walk()
		}
		onWallCollide() {
			this.stop()
			Random, deg, 15, 45
			this.turnLBy( deg )
		}
		onHungry() {
			this.stopEverything()
			this.turnToHill()
		}
		onArriveHome() {
			this.stopEverything()
			this.turnRBy( 180 )
		}
		onSeeAnt( anyAnt ) {
			if ( this.getEnergy() > 33.33 && this.getEnergy() < 90 && !isObject( this.getProperty( "follows" ) ) && !anyAnt.getProperty( "follows" ).equals( this ) )
			{
				this.turnTo( anyAnt )
				this.setProperty( "follows", anyAnt )
			}
		}
		onSeeAntHill( anyAntHill )
		{
			
			if ( this.getEnergy() > 33.33 && this.getEnergy() < 90 && ( !isObject( this.getProperty( "follows" ) ) || !this.getProperty( "follows" ).ptr ) )
			{
				this.stopTurn()
				this.turnRBy( 45 )
			}
		}
		onTick(){
			if ( this.getEnergy() > 33.33 && isObject( this.getProperty( "follows" ) ) )
			{
				this.turnTo( this.getProperty( "follows" ) )
			}
		}
		onBored() {
			;Random, val, 1, 6
			;if ( val = 5 )
			;{
				;this.stop()
				;this.turnToHill()
			;}
			;else
				;this.stop()
		}
	}
}
;-----This Controller normally should get added by a seperate script through COM


class AntServer {
	
	addAntHill( controller ) {
		nAntHill := new AntHill( [ 1, 1 ] )
		nAntHill.setController( controller )
	}
	
	startup() {
		GameControl.startGameLoop()
	}
	
}

class GameControl {
	
	w := 600
	h := 600
	elements := []
	elementsClass := {}
	movingElements := []
	
	__New()
	{
		static init := new GameControl()
		if init
			return init
		className := This.base.__Class
		%className% := This	
		
		GUI, NEW
		GUI +hwndGUI
		
		This.hwnd    := GUI
		This.display := new display( GUI, [ 1, 1 ] )
		GUI, show, % "w" . this.w . " h" this.h
		fn := this.initializeGame.bind( this )
		SetTimer, %fn%, -1
		
	}
	
	initializeGame() {
		new BackGround( [ 1, 1 ] )
	}
	
	startGameLoop()
	{
		SetTimer, gameLoop, 15
		return
		gameLoop:
		GameControl.tick()
		return
		GuiClose:
		ExitApp
	}
	
	stopGameLoop()
	{
		SetTimer, gameLoop, off
	}
	
	tick() {
		this.setFrameTime()
		this.doEntityTasks()
		this.calculatePhysics()
		this.callEventHandlers()
		this.draw()
	}
	
	draw() {
		This.display.draw()
	}
	
	setFrameTime() {
		currentTime := getTime()
		this.dT := currentTime - this.frameTime
		if !this.dT
			this.dT := 0
		this.frameTime := currentTime
	}
	
	doEntityTasks() {
		for each,  element in this.elements
			element.executeLogic()
	}
	
	calculatePhysics() {
		for each, movingElement in this.movingElements {
			if ( movingElement.collisionSize ) {
				if ( movingElement.vel.1 = 0 && movingElement.vel.2 = 0 )
					continue
				movingElement.setPos( movingElement.pos.add( movingElement.vel.mul( this.dT ) ) )
				pos := movingElement.pos
				vec := new Vector2d( 1, 1 )
				dist := vec.sub( pos ).abs()
				range := vec.sub( [ movingElement.collisionSize, movingElement.collisionSize ] ).div( 2 )
				if !dist.lequal( range ) {
					if ( dist.1 > range.1 )
						pos.1 += ( pos.1 < vec.1 ) ? dist.1 - range.1 : range.1 - dist.1
					if ( dist.2 > range.2 )
						pos.2 += ( pos.2 < vec.2 ) ? dist.2 - range.2 : range.2 - dist.2
					movingElement.setPos( pos )
					movingElement.triggerCallBack( "WallCollide" )
				}
			}
		}
	}
	
}

class GraphicalElement {
	
	__New( pos, rot := 0 ) {
		this.pic := GameControl.display.addPicture( this.picFile, [ 1, 1, this.picLevel ], this.picSize )
		this.setPos( pos )
		this.setRot( rot )
		this.pic.setVisible()
		GameControl.elements[ &this ] := this
		GameControl.elementsClass[ this.__Class, &this ] := this
		this.onSpawn()
	}
	
	despawn() {
		this.onDespawn()
		GameControl.elements.delete( &this )
		GameControl.movingElements.delete( &this )
		GameControl.elementsClass[ this.__Class ].delete( &this )
		This.pic.setVisible( false )
		This.pic := ""
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
		GameControl.movingElements[ &this ] := this
	}
	
}


class Ant extends GraphicalElement {
	static picFile := "res\ant.png", picLevel := 3, picSize := new Vector2d( 0.0125, 0.03 ), collisionSize := 0.03
	
	static viewDist := 0.1
	static maxVel := 0.1
	static maxRot := 1
	static energyRot  := 1
	static energyWalk := 1
	static energyIdle := 1
	state := 0 ;a bitmask
	timeLastStateChange := getTime()
	propertyValues := []
	propertyKeys   := []
	energy := 100
	sees   := []
	
	onSpawn() {
		This.sees[ &this ] := 1
	}
	
	onDespawn() {
		this.antHill.ants--
	}
	
	executeLogic() {
		;check for turn
		e := This.energy
		if ( This.state & 2 ) {
			maxRot := This.maxRot * GameControl.dT
			This.energy -= This.energyRot * GameControl.dT
			if ( This.targetDegrees > -1 && abs( This.rot - This.targetDegrees ) < maxRot ) {
				This.setRot( This.targetDegrees )
				This.getControl().stopTurn()
			}
			else if ( isObject( This.targetDegrees ) && abs( This.rot - ( nRot := This.targetDegrees.pos.sub( This.pos ).getRot() ) ) < maxRot )
			{
				This.setRot( nRot )
				This.getControl().stopTurn()
			}
			else
				This.setRot( This.rot + ( ( This.state & 4 ) ? -maxRot : maxRot ) )
		}
		if ( This.state & 1 ) {
			This.energy -= This.energyWalk * GameControl.dT
			This.setVelocity( [ sin( This.rot ) * This.maxVel, cos( This.rot ) * This.maxVel ] )
		} else {
			This.setVelocity( [ 0, 0 ] )
			if ( !This.state )
				This.triggerCallBack( "Idle" )
		}
		This.energy -= This.energyIdle * GameControl.dT
		saw := this.sees.clone()
		newSee := []
		for each, className in [ "Ant", "AntHill" ] {
			for each, element in GameControl.elementsClass[ className ]
			{
				if ( ( inView := element.pos.sub( this.pos ).magnitude() < ( This.viewDist + element.picSize.magnitude() ) / 2 ) && !saw.hasKey( &element ) ) {
					this.sees[ &element ] := 1
					newSee.push( element )
				}
				else if inView
					saw.delete( &element )
			}
		}
		for each, void in saw
			This.sees.delete( each )
		for each, element in newSee {
			This.triggerCallBack( "See" . element.__Class, element.getInfo() )
		}
		if ( GameControl.frameTime - This.timeLastStateChange > 5 )
			This.triggerCallBack( "Bored" )
		if ( This.pos.sub( This.antHill.pos ).abs().div( ( This.antHill.picSize ).div( 2 ) ).magnitude() < 1 )
		{
			if ( e < 100 )
				This.triggerCallBack( "ArriveHome" )
			This.energy := 100
		}
		if ( This.energy < 33.333 && e > 33.333 )
			This.triggerCallBack( "Hungry" )
		if ( This.energy < 0 )
			This.despawn()
		This.triggerCallBack( "Tick" )
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
		This.antHill.controller.antControl["on" . name ].call( This.getControl(), p* )
	}
	
	getControl() {
		return new This.AntMoveControl( This )
	}
	
	getInfo() {
		return new This.AntInfo( This )
	}
	
	class AntInfo {
		
		__New( nAnt ) {
			This.ptr := &nAnt
		}
		
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
		
		equals( objOrRef ) {
			if ( objOrRef.hasKey( "ptr" ) )
				return objOrRef.ptr = this.ptr
		}
		
	}
	
	class AntMoveControl {
		
		__New( nAnt ) {
			This.ptr := &nAnt
		}
		
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
			if !isObject( reference )
				Throw Exception( "Cannot turn to that" )
			if reference.hasKey( "ptr" ) {
				reference := resolveRef( reference )
			}
			nAnt  := resolveRef( This )
			nRot := reference.pos.sub( nAnt.pos ).getRot()
			if ( nRot - This.rot < 0 )
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
		
		getTurn() {
			nAnt := resolveRef( This )
			if ( nAnt.state & 2 )
				return nAnt.state & 4 ? "R" : "L"
		}
		
		stopEverything() {
			resolveRef( This ).removeState( 0xFF )
		}
		
		setProperty( name, value ) {
			nAnt := resolveRef( This )
			for each, propertyName in nAnt.propertyKeys
				if ( propertyName = name )
				{
					return nAnt.propertyValues[ each ] := value
				}
			nAnt.propertyValues.Push( value )
			nAnt.propertyKeys.Push( name )
			return value
		}
		
		getProperty( name ) {
			nAnt := resolveRef( This )
			
			for each, propertyName in nAnt.propertyKeys
				if ( propertyName = name )
				{
					;Msgbox getProperty success
					return nAnt.propertyValues[ each ]
				}
			
		}
		
		getEnergy() {
			return resolveRef( This ).energy
		}
		
		getWalk() {
			return resolveRef( This ) & 1
		}
		
		equals( objOrRef ) {
			if ( objOrRef.hasKey( "ptr" ) )
				return objOrRef.ptr = this.ptr
		}
		
	}
	
}

class AntHill extends GraphicalElement {
	static picFile := "res\anthill.png", picLevel := 2, picSize := new Vector2d( 0.1, 0.1 )
	
	
	static spawnRate := 1
	static maxAnts   := 30
	timeSinceLastSpawn := getTime() - 10
	ants := 0
	
	setController( controller ) {
		This.controller := controller
	}
	
	executeLogic() {
		if ( GameControl.frameTime - this.timeSinceLastSpawn > This.spawnRate && This.ants < This.maxAnts )
		{
			Random, deg, 0, 359
			deg := deg / 45 * atan(1)
			sinVal := sin( deg ) * ( ( this.picSize.2 + Ant.picSize.2 ) / 2 ), cosVal := cos( deg ) * ( ( this.picSize.1  + Ant.picSize.2 ) / 2 )
			newAnt := new Ant( [ this.pos.1 + sinVal, this.pos.2 + cosVal ], deg )
			newAnt.antHill := This
			newAnt.sees[ &This ] := 1
			This.ants++
			this.timeSinceLastSpawn := GameControl.frameTime
		}
	}
	
}

class Sugar extends GraphicalElement {
	static picFile := "res\sugarfull.png", picLevel := 2, picSize := new Vector2d( 0.05, 0.05 )
}

class Apple extends GraphicalElement {
	static picFile := "res\apple.png", picLevel := 2, picSize := new Vector2d( 0.05, 0.05 )
}

class BackGround extends GraphicalElement {
	static picFile := "res\background.png", picLevel := 1, picSize := new Vector2d( 1.1, 1.1 )
}

getTime() {
	static frequency, init := DllCall( "QueryPerformanceFrequency", "UInt64*", frequency )
	DllCall( "QueryPerformanceCounter", "UInt64*", time )
	return time / frequency
}

deg2rad( deg ) {
	static deg2rad := atan( 1 ) / 45
	return deg * deg2rad
}

rad2deg( rad ) {
	static rad2deg := 45 / atan( 1 )
	return rad * rad2deg
}

trueMod( a, b ) {
	a := a < 0 ? a + ( b * ceil( -a/b ) ) : a
	a := a/b
	a := a - floor( a )
	return a * b
}

resolveRef( refElement ) {
	if GameControl.elements.hasKey( refElement.ptr ) {
		return Object( refElement.ptr )
	}
	refElement.delete( "ptr" )
	refElement.base := ""
}

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