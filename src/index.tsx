import Game from './Game';
import * as serviceWorker from './serviceWorker';

import './index.css';

window.addEventListener("load", () => {
	const _ = new Game();
});

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: http://bit.ly/CRA-PWA
serviceWorker.register();
