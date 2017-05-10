const path = require('path');
const nodeModulesPath = path.resolve(__dirname, 'node_modules');
const mainPath = path.resolve(__dirname, 'app/assets/angular2');

module.exports = {
	entry: { 
	        angular2: "./app/assets/angular2/incremental.ts",
		angular2_polyfills: "./app/assets/angular2/polyfills.ts"
	},
	output: {
		path: path.resolve(__dirname, "app/assets/javascripts"),
		filename: "[name].js"
	},
	module: {
		rules: [
		{ test: /.(png|woff(2)?|eot|ttf|svg)(\?[a-z0-9=\.]+)?$/, loader: 'url-loader?limit=100000' },
		{ test: /\.css$/, loaders: ['style-loader', 'css-loader', 'resolve-url'], exclude: [mainPath] },
		{ test: /\.css$/, loaders: ['raw-loader'], include: [mainPath] },
		{ test: /\.scss$/, loaders: ['style', 'css', 'resolve-url', 'sass?sourceMap'], exclude: [mainPath] },
		{ test: /\.scss$/, loaders: ['css-to-string', 'css', 'resolve-url', 'sass?sourceMap'], include: [mainPath] },
		{ test: /\.ts$/,
			loaders: ['awesome-typescript-loader?configFileName=./app/assets/angular2/tsconfig.json', 'angular2-template-loader'],
			exclude: [/\.(spec|e2e)\.ts$/, /\.spec\.ts$/, /node_modules\/(?!(ng2-.+))/, /\.e2e-spec\.ts$/] },
		{ test: /\.html$/, loader: 'raw-loader' }
		]
	},
	resolve: {
		modules: [nodeModulesPath],
		extensions: ['.ts', '.js' ],
		alias: {}
	}
};
