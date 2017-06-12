const path = require('path');
const nodeModulesPath = path.resolve(__dirname, 'node_modules');
const mainPath = path.resolve(__dirname, 'app/assets/vues');
const assetPath = path.resolve(__dirname, 'app/assets/javascripts');

module.exports = {
	entry: {
		typescripts: (mainPath + "/src/vues.ts")
	},
	output: {
		filename: "vues.js",
		path: assetPath
	},

	// Enable sourcemaps for debugging webpack's output.
	devtool: "source-map",

	resolve: {
		// Add '.ts' and '.tsx' as resolvable extensions.
		modules: [nodeModulesPath],
		extensions: [".ts", ".js", ".json", ".html"],
		    alias: {
			          'vue$': 'vue/dist/vue.common.js'
					      }
	},

	module: {
		rules: [
		  { test: /\.ts$/, 
		    exclude: /node_modules/,
		    loaders: "awesome-typescript-loader?configFileName=./app/assets/vues/tsconfig.json&transpileOnly=false"
		  },
                  {test: /\.html$/, loader: 'raw-loader'},
      		  { enforce: "pre", test: /\.js$/, loader: "source-map-loader" } ]
	}
};
