import Phaser from 'phaser';

import Scene from './Scene';

export default class Game extends Phaser.Game {
	constructor() {
		super({
			parent: 'root',
			width: window.innerWidth,
			height: window.innerHeight,
			scene: [Scene],
		});

		window.addEventListener("resize", () => {
			this.resize(window.innerWidth, window.innerHeight);
		});
	}
}
