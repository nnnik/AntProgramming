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
			Random, deg, 15, 90
			this.turnLBy( deg )
		}
		onHungry() {
			this.stopEverything()
			this.turnToHill()
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
	}
	
	despawn() {
		GameControl.elements.delete( &this )
		GameControl.movingElements.delete( &this )
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
	static picFile := "res\ant.png", picLevel := 3, picSize := [ 0.0125, 0.03 ], collisionSize := 0.03
	
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
			else if ( isObject( This.targetDegrees ) )
			{
				tDist := This.targetDegrees.pos.sub( This.pos )
				dDist := tDist.div( tDist.magnitude() )
				if ( dDist.1 < 0 )
					nRot := 8*atan( 1 ) -acos( dDist.2 )
				else
					nRot := acos( dDist.2 )
				if ( abs( This.rot - nRot ) < maxRot )
				{
					This.setRot( nRot )
					This.getControl().stopTurn()
				}
				else
					This.setRot( This.rot + ( ( This.state & 4 ) ? -maxRot : maxRot ) )
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
		if ( GameControl.frameTime - This.timeLastStateChange > 5 )
			This.triggerCallBack( "Bored" )
		;Tooltip % This.energy
		if ( This.pos.sub( This.antHill.pos ).abs().div( ( new Vector2d( This.antHill.picSize* ) ).div( 2 ) ).magnitude() < 1 )
			This.energy := 100
		if ( This.energy < 33.333 && e > 33.333 )
			This.triggerCallBack( "Hungry" )
		if ( This.energy < 0 )
			This.despawn()
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
		This.antHill.controller.antControl["on" . name ].call( This.getControl() )
	}
	
	getControl() {
		return new This.AntMoveControl( This )
	}
	
	class AntMoveControl {
		
		__New( nAnt ) {
			This.ant := &nAnt
		}
		
		walk() {
			Object( This.ant ).addState( 1 )
		}
		
		stop() {
			Object( This.ant ).removeState( 1 )
		}
		
		turnL() {
			nAnt := Object( This.ant )
			nAnt.addState( 2 )
			nAnt.removeState( 4 )
			nAnt.targetDegrees := ""
		}
		
		turnLBy( degrees ) {
			degrees := deg2rad( degrees )
			nAnt := Object( This.ant )
			nAnt.addState( 2 )
			nAnt.removeState( 4 )
			nAnt.targetDegrees := trueMod( nAnt.rot + degrees, atan( 1 ) * 8 )
		}
		
		turnR() {
			nAnt := Object( This.ant )
			nAnt.addState( 6 )
			nAnt.targetDegrees := ""
		}
		
		turnRBy( degrees ) {
			degrees := deg2rad( degrees )
			nAnt := Object( This.ant )
			nAnt.addState( 2 )
			nAnt.removeState( 4 )
			nAnt.targetDegrees := trueMod( nAnt.rot - degrees , atan( 1 ) * 8 )
		}
		
		turnToHill() {
			nAnt  := Object( This.ant )
			dHill := nAnt.antHill.pos.sub( nAnt.pos ).rotate( -this.rot )
			if ( dHill.2 < 0 )
				This.turnR()
			else
				This.turnL()
			nAnt.targetDegrees := nAnt.antHill
		}
		
		stopTurn() {
			nAnt := Object( This.ant ).removeState( 6 )
			nAnt.targetDegrees := ""
		}
		
		stopEverything() {
			Object( This.ant ).removeState( 0xFF )
		}
		
		setProperty( name, value ) {
			nAnt := Object( This.ant )
			for each, propertyName in nAnt.propertyKeys
				if ( popertyName = name )
					return nAnt.propertyValues[ each ] := value
			propertyValues.Push( value )
			propertyKeys.Push( name )
			return value
		}
		
		getProperty( name ) {
			nAnt := Object( This.ant )
			for each, propertyName in nAnt.propertyKeys
				if ( popertyName = name )
					return nAnt.propertyValues[ each ]
		}
		
	}
	
}

class AntHill extends GraphicalElement {
	static picFile := "res\anthill.png", picLevel := 2, picSize := [ 0.1, 0.1 ]
	
	timeSinceLastSpawn := getTime() - 10
	
	setController( controller ) {
		This.controller := controller
	}
	
	executeLogic() {
		if ( GameControl.frameTime - this.timeSinceLastSpawn > 10 )
		{
			Random, deg, 0, 359
			deg := deg / 45 * atan(1)
			sinVal := sin( deg ) * ( ( this.picSize.2 + Ant.picSize.2 ) / 2 ), cosVal := cos( deg ) * ( ( this.picSize.1  + Ant.picSize.2 ) / 2 )
			newAnt := new Ant( [ this.pos.1 + sinVal, this.pos.2 + cosVal ], deg )
			newAnt.antHill := This
			this.timeSinceLastSpawn := GameControl.frameTime
		}
	}
	
}

class Sugar extends GraphicalElement {
	static picFile := "res\sugarfull.png", picLevel := 2, picSize := [ 0.05, 0.05 ]
}

class Apple extends GraphicalElement {
	static picFile := "res\apple.png", picLevel := 2, picSize := [ 0.05, 0.05 ]
}

class BackGround extends GraphicalElement {
	static picFile := "res\background.png", picLevel := 1, picSize := [ 1.1, 1.1 ]
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
	
}