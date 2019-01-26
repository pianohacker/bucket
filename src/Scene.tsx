import 'phaser';
import Phaser from 'phaser';

export default class Scene extends Phaser.Scene {
	x: number = 0;
	testObject?: Phaser.GameObjects.Graphics;

	constructor() {
		super({
			key: "Scene",
		});
	}

	create() {
		this.testObject = this.add.graphics();
		this.testObject.y = 800;
		this.testObject.fillStyle(0xff0000, 1);
		this.testObject.fillCircle(0, 0, 3);
	}

	update() {
		// this.testObject!.x = this.x++;
	}
}
