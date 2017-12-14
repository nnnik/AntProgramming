#Include displayOut.ahk
#Include ObjRegisterActive.ahk
#NoEnv
#Persistent
SetBatchLines, -1
ObjRegisterActive( AntServer, "{f52e0360-3454-4576-8486-8131f0b92f6c}" ) 
Run, AntHill1.ahk, , , pid
OnExit, Exit
return
Exit:
Process, Close, %pid%
ExitApp


class AntServer {
	
	addController( controller, Name ) {
		GameControl.addController( controller, Name )
	}
	
}

class GameControl {
	
	w := 600
	h := 600
	elements       := []
	elementsClass  := {}
	movingElements := []
	timeMultiplier := 1
	calcRounds     := 1
	controller     := []
	started        := false
	state          := ""
	
	__New()
	{
		global SpeedSlider, ControllerDDL
		static init := new GameControl()
		if init
			return init
		className := This.base.__Class
		%className% := This	
		
		GUi, add, Picture,  % "w" . this.w . " h" . this.h . " hwndGUI"
		GUI, add, Slider, % "w" . this.w . " vSpeedSlider gSpeedChange", 33
		GUI, add, DropDownList, % "w" . this.w " vControllerDDL gControllerChange"
		This.hwnd    := GUI
		This.display := new display( GUI, [ 1, 1 ] )
		GUI, show
		This.draw()
		return
		SpeedChange:
		GuiControlGet, SpeedSlider, , SpeedSlider
		GameControl.timeMultiplier := SpeedSlider < 33 ? 1 / ( 43-SpeedSlider ) * 10 : ( SpeedSlider - 22 ) / 10
		GameControl.calcRounds := Round( GameControl.timeMultiplier ) ? Round( GameControl.timeMultiplier ) : 1
		return
		ControllerChange:
		GuiControlGet, ControllerDDL, , ControllerDDL
		if GameControl.started
			GameControl.shutdown( func( "startNewSimulation" ).bind( ControllerDDL ) )
		else
			startNewSimulation( ControllerDDL, GameControl )
		return
	}
	
	addController( controller, Name ) {
		global ControllerDDL
		if !This.controller.hasKey( Name )
			GuiControl, , ControllerDDL, % Name
		This.controller[ Name ] := controller
	}
	
	shutdown( callBack := "" ) {
		if !This.running
		{
			This.execShutDown()
			return
		}
		This.toShutDown := 1
		This.shutDownCallBack := callBack
	}
	
	execShutDown() {
		This.toShutDown := 0
		This.started := false
		This.stopGameLoop()
		for each, element in This.elements.clone() {
			element.despawn()
		}
		This.backGround     := ""
		This.elements       := ""
		This.elementsClass  := ""
		This.movingElements := ""
		This.Spawner.shutDown()
		This.draw()
		This.shutDownCallBack()
		This.shutDownCallBack := ""
	}
	
	startUp() {
		This.elements       := []
		This.elementsClass  := {}
		This.movingElements := {}
		This.backGround     := new BackGround( [ 1, 1 ] )
		This.Spawner.startUp()
		This.started := true
	}
	
	startGameLoop()
	{
		This.tickTime := getTime()
		This.frameTime := getTime()
		This.running := true
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
		This.running := false
		SetTimer, gameLoop, off
	}
	
	tick() {
		if This.tickRunning
			return
		This.tickrunning := 1
		This.state := "Tick started"
		this.setTickTime()
		This.state := "Tick set Time"
		Loop % This.calcRounds {
			this.addFrameTime()
			This.state := "Tick add frame Time"
			this.calculateWorld()
			This.state := "Tick calculate world"
		}
		this.draw()
		Tick.state := "draw"
		if ( this.toShutdown )
			This.execShutdown()
		This.tickRunning := 0
	}
	
	calculateWorld() {
		this.doEntityTasks()
		this.calculatePhysics()
		this.Spawner.spawnStuff()
	}
	
	setTickTime() {
		currentTime := getTime()
		This.deltaTick := currentTime - This.tickTime
		This.tickTime := currentTime
	}
	
	addFrameTime() {
		This.dT := This.deltaTick * This.timeMultiplier / This.calcRounds
		if !This.dT
			This.dT := 0
		This.frameTime += This.dT
	}
	
	doEntityTasks() {
		for each,  element in This.elements
			element.executeLogic()
	}
	
	calculatePhysics() {
		for each, movingElement in This.movingElements {
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
	
	class Spawner {
		
		static sugar, spawnSpeed, spawnValues, maxHeaps := 4
		
		startUp() {
			This.sugar := []
			This.spawnSpeed := 4
			This.spawnValues := []
			Loop % This.maxHeaps
				This.spawnValues.push( 0 )
		}
		
		shutDown() {
			This.sugar := ""
			This.spawnValues := ""
		}
		
		spawnStuff() {
			Random, dice, 1, 10
			Random, sugarDice, 1, 4
			if ( This.spawnValues[ sugarDice ] += dice * GameControl.dT * This.spawnSpeed * This.maxHeaps ) > 100 {
				This.spawnValues[ sugarDice ] := 0
				This.sugar[ sugarDice ].despawn()
				This.sugar[ sugarDice ] := This.spawnSugar()
				This.spawnSpeed := 0.2
			}
		}
		
		spawnSugar() {
			Loop {
				random, x, 1, 2000
				random, y, 1, 2000
				x := x / 2000 + 0.5
				y := y / 2000 + 0.5
				posSugar := new Vector2d( x, y )
				min := 100000
				For each, nAntHill in GameControl.elementsClass.AntHill
					if ( ( dist := posSugar.sub( nAntHill.pos ).magnitude() ) < min )
						min := dist
			} Until min > 0.333
			return new SugarHeap( posSugar )
		}
		
	}
	
	draw() {
		This.display.draw()
	}
	
}

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
		if ( GameControl.movingElements.hasKey( &This ) ) {
			GameControl.movingElements.delete( &This )
		}
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
		
		getVisible() {
			vis := []
			for elementPtr, void in This.sees
				if ( elementPtr != &This && elem := resolvePtr( elementPtr ).getInfo() ).isRef
					vis.Push( elem )
			return vis
		}
		
		getTouched() {
			touch := []
			for elementPtr, void in This.touches
				if ( elementPtr != &This && elem := resolvePtr( elementPtr ).getInfo() ).isRef
					touch.Push( elem )
			return touch
		}
		
		getHolding() {
			nAnt := resolveRef( This )
			if nAnt.holding
				return nAnt.holding.getInfo()
		}
		
		isHome() {
			nAnt := resolveRef( This )
			return nAnt.touches.hasKey( nAnt.antHill )
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

class AntHill extends GraphicalElement {
	static picFile := "res\anthill.png", picLevel := 2, picSize := new Vector2d( 0.1, 0.1 )
	
	static spawnRate := 1
	static maxAnts   := 20
	currentAnts := 1
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

class SugarHeap extends GraphicalElement {
	static picFile := "res\sugarfull.png", picLevel := 2, picSize := new Vector2d( 0.05, 0.05 )
	static canPickup := 1
	
	onSpawn() {
		Random, durability, 3, 5
		This.pieces := durability
	}
	
	pickedUpBy( elem ) {
		piece := new SugarPiece( This.pos.clone() )
		if !( --This.pieces )
			This.despawn()
		return piece.pickedUpBy( elem )
	}
	
}

class SugarPiece extends GraphicalElement {
	static picFile := "res\sugarfull.png", picLevel := 4, picSize := new Vector2d( 0.015, 0.015 ), collisionSize := 0.015
	static canPickup := 1
	static isFood := 1
	heldBy := []
	
	pickedUpBy( elem ) {
		This.heldBy[ &elem ] := 1
		return This
	}
	
	droppedBy( elem ) {
		This.heldBy.delete( &elem )
		return This
	}
	
	getInfo() {
		return new This.SugarPieceInfo( This )
	}
	
	class SugarPieceInfo extends GraphicalElement.ElementInfo {
		getHeldBy() {
			nSugar := resolveRef( This )
			heldBy := []
			for elemPtr, void in nSugar.heldBy
				if ( ref := resolvePtr( elemPtr ).getInfo() ).isRef {
					heldBy.push( ref )
				}
			if heldBy.Length()
				return heldBy
		}
	}
	
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
	if ( refElement.isRef && obj := resolvePtr( refElement.ptr ) )
		return obj
	refElement.delete( "ptr" )
	refElement.base := ""
}
resolvePtr( refPtr ) {
	if ( GameControl.elements.hasKey( refPtr ) )
		return Object( refPtr )
}
startNewSimulation( controllerName, nGameControl )
{
	nGameControl.startUp()
	nAntHill := new AntHill( [ 1, 1 ] )
	nAntHill.setController( nGameControl.controller[ controllerName ] )
	nGameControl.startGameLoop()
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
