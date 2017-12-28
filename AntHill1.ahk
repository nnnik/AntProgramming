#Persistent
#NoEnv
#NoTrayIcon
SetBatchLines, -1
AntServer := ComObjActive( "{f52e0360-3454-4576-8486-8131f0b92f6c}" )
AntServer.addController( testController, "Left Rotate Ants" )
AntServer.addController( testController2, "Random Rotate Ants" )


class testController2 {
	
	ping() {
		return 1
	}
	
	class antControl {
		onIdle() {
			this.walk()
		}
		onWallCollide() {
			if !this.getHolding() {
				this.stop()
				Random, deg, 45, 90
				Random, dir, 0, 1
				if ( dir )
					this.turnLBy( deg )
				else
					This.turnRBy( deg )
			}
		}
		onHungry() {
			this.stopEverything()
			this.turnToHill()
		}
		onArriveHome( home ) {
			This.drop()
			This.stop()
			This.turnRBy( 180 )
		}
		onSeeSugarHeap( anySugarHeap ) {
			if ( This.getEnergy() > 33.333 && !This.getHolding() ) {
				This.stop()
				This.turnTo( anySugarHeap )
			}
		}
		onArriveSugarHeap( anySugarHeap ) {
			if ( This.getEnergy() > 33.333 && !This.getHolding() ) {
				This.stop()
				This.turnToHill()
				This.pickUp( anySugarHeap )
			}
		}
		onSeeSugarPiece( anySugarPiece ) {
			if ( This.getEnergy() > 33.333 && !anySugarPiece.getHeldBy() && !This.getHolding() ){
				This.stop()
				This.turnTo( anySugarPiece )
			}
		}
		onArriveSugarPiece( anySugarPiece ) {
			if ( This.getEnergy() > 33.333 && !This.getHolding() && !anySugarPiece.getHeldBy() ){
				This.pickUp( anySugarPiece )
				if !This.isHome() {
					This.stop()
					This.turnToHill()
				}
				else
					This.drop()
			}
			
		}
		onSeeAlliedAnt( anyAnt ) {
			if !( This.getHolding() || This.getEnergy() < 33.333 || anyAnt.getHolding() || This.canSee( "SugarHeap" ) || This.canSee( "SugarPiece" )  || This.canSee( "Home" ) ) {
				This.turnLBy( 135 )
			}
		}
	}
	
}

class testController {
	
	ping() {
		return 1
	}
	
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
		onArriveHome( home ) {
			This.drop()
			This.stop()
			This.turnRBy( 180 )
		}
		onSeeSugarHeap( anySugarHeap ) {
			if ( This.getEnergy() > 33.333 && !This.getHolding() ) {
				This.stop()
				This.turnTo( anySugarHeap )
			}
		}
		onArriveSugarHeap( anySugarHeap ) {
			if ( This.getEnergy() > 33.333 && !This.getHolding() ) {
				This.stop()
				This.turnToHill()
				This.pickUp( anySugarHeap )
			}
		}
		onSeeSugarPiece( anySugarPiece ) {
			if ( This.getEnergy() > 33.333 && !anySugarPiece.getHeldBy() && !This.getHolding() ){
				This.stop()
				This.turnTo( anySugarPiece )
			}
		}
		onArriveSugarPiece( anySugarPiece ) {
			if ( This.getEnergy() > 33.333 && !This.getHolding() && !anySugarPiece.getHeldBy() ){
				This.pickUp( anySugarPiece )
				This.stop()
				This.turnToHill()
			}
			
		}
	}
}