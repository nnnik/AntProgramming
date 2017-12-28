class GameControl {
	
	w := 600
	h := 600
	elements       := []
	elementsClass  := {}
	movingElements := []
	fieldSize      := new Vector2d( 1, 1 )
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
		This.setFieldSize( [2, 2] )
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
		This.backGround     := new BackGround( This.fieldSize.div( 2 ).add( [ 0.5, 0.5 ] ) )
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
		for each,  element in This.elements.clone()
			element.executeLogic()
	}
	
	calculatePhysics() {
		for each, movingElement in This.movingElements.clone() {
			if ( movingElement.collisionSize ) {
				FileOpen( "debug.txt", "w").write( disp( This, 1 ) )
				if ( movingElement.vel.1 = 0 && movingElement.vel.2 = 0 )
					continue
				movingElement.setPos( movingElement.pos.add( movingElement.vel.mul( this.dT ) ) )
				pos    := movingElement.pos
				size   := This.fieldSize
				center := size.div( 2 ).add( [ 0.5, 0.5 ] )
				dist := center.sub( pos ).abs()
				range := size.sub( [ movingElement.collisionSize, movingElement.collisionSize ] ).div( 2 )
				if !dist.lequal( range ) {
					if ( dist.1 > range.1 )
						pos.1 += ( pos.1 < center.1 ) ? dist.1 - range.1 : range.1 - dist.1
					if ( dist.2 > range.2 )
						pos.2 += ( pos.2 < center.2 ) ? dist.2 - range.2 : range.2 - dist.2
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
				posSugar := new vector2d( x, y ).div( new Vector2d( 2000, 2000 ).div( GameControl.fieldSize ) ).add( [0.5, 0.5] )
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
	
	setFieldSize( size ) {
		if ( size.length() <= 2 ) {
			size := new Vector2d( size.1, size.2 )
			This.display.setFieldSize( size )
			This.fieldSize := size
		}
	}
	
}